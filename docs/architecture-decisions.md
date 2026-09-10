# Architecture decisions

This document records decisions that are already reflected in the Elisa
implementation. It is deliberately separate from the local implementation
plan so clients and contributors can review the supported contracts without
depending on ignored planning material.

## Ownership and module boundaries

Debugger-owned executable behavior is implemented in Elisa modules under
`src/`. The compiler, runtime object, linker, libc, and editor hosts are
infrastructure dependencies. `core`, metadata, trace, and protocol models do
not import editor or operating-system UI code. CLI, DAP, and headless service
entrypoints dispatch through shared session and error models.

Public types and operations are inside a module's `public` section. Capacity,
sentinel, protocol, and error-detail constants remain private. Persistent data
is encoded field by field through `DebuggerTraceBinary`; host struct layout and
raw pointers are never written to a trace.

## Execution providers

The managed EDIR provider is the first exact-history provider. It owns logical
machine state and bounded reverse navigation. Native and postmortem modules
advertise their narrower capability sets and reject unsupported lifecycle or
replay claims. A provider must return a typed capability or state error before
an adapter exposes an operation.

## State and concurrency

Every mutating session request is checked against a stop generation. A stale
generation is rejected without applying the operation. Checkpoint validation
derives runtime status from task states, rejects cyclic parent trees and
duplicate waiters, and preserves historical scheduler decisions without
mistaking their captured state for the current task state.

## Exactness and external effects

Exactness is explicit. The trace and effect modules distinguish exact,
observational, incomplete, diverged, and corrupt states. Replayed effects must
match the recorded kind and request identity; external writes carry a recorded
suppression policy and are never implicitly sent to the real world.

## Protocols

The headless protocol uses a decimal byte count, one space, exactly that many
UTF-8 payload bytes, and a newline. DAP uses standard `Content-Length` framing
where the declared length covers only the JSON body. Numeric IDs at the compact
headless boundary are rendered as decimal strings in responses. Discovery is
allowed to omit an ID; stateful requests may not use the reserved zero ID.

## Current resource limits

The initial implementation uses fixed bounded arrays so malformed input cannot
allocate unbounded memory. Limits are advertised by discovery where exposed,
and every reader validates lengths before indexing. Increasing a limit requires
updating the named module constant, its format/protocol specification, and the
focused corruption tests together.

## Public advanced surfaces

The managed provider exposes inspection, breakpoint, checkpoint, branch,
comparison, trace verification, and trace export operation names through the
same service used by the headless server and DAP adapter. Operations that
require request payloads are validated through typed service contracts; the
service never falls back to parsing interactive CLI output.

Historical values use an explicit `Absent` state in addition to unavailable,
optimized-away, uninitialized, invalid, and redacted states. Query results
carry cancellation and resource-limit outcomes, and never turn an incomplete
scan into a complete answer.

Concurrency exploration is bounded by task, event, preemption, branch, and
work limits. Race reports describe observed concurrent accesses under the
captured vector-clock model; they do not claim race freedom for schedules
outside the explored bound.

Trace health is monotonic. A later corrupt or unsupported event records the
last verified prefix and downgrades capabilities at that boundary. Retention
marks only unpinned, unreferenced chunks for collection so checkpoint and
branch dependency closures remain recoverable after interrupted cleanup.

## Native artifact formats

Native artifact discovery keeps format readers independent: `DebuggerNativeElf`
handles bounded ELF64 little-endian headers for Linux targets, while
`DebuggerNativeMachO` handles bounded Mach-O 64-bit headers and load-command
records for macOS targets. Each reader validates architecture identity and all
declared table ranges before exposing metadata. ELF program and section headers,
and Mach-O load-command records, are exposed only after their individual bounds are
validated; ELF segment file ranges also have checked file-size and memory-size
relationships. Symbol and segment decoding can therefore be added per format
without sharing unsafe offset assumptions. Callers
use `DebuggerNativeArtifact` as the single public selector: it checks a bounded
magic prefix and dispatches to the appropriate reader, while unknown formats
remain explicitly unsupported.
Mach-O UUID load commands are exposed only when their full 16-byte identity is
present, allowing build-artifact matching without trusting a path or filename.
