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

The Elisa agent/controller boundary carries a bounded safe-point handshake.
Each stop request receives a monotonic generation, and the controller exposes
`Stopped` only after the agent acknowledges that same generation. Event
ordinals are checked against the bounded buffer cursor; unknown event kinds,
gaps, capacity exhaustion, and invalid acknowledgement state downgrade the
live controller to `AgentFailed` with a transport error. An overflowed buffer
cannot resume, so an exact capture cannot silently continue after losing an
event. Target crashes retain captured agent state and remain inspectable as a
crash, while agent transport failure remains a separate state. This is a
controller and testable agent contract; it does not claim a platform process
transport or make native history/replay capabilities available.

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

The generic scalar `EffectOracle` qualifies clock values and individual
unsigned 64-bit random samples for exact replay. Random samples use the typed
`effect_oracle_record_random` and `effect_oracle_replay_random_result` APIs;
their complete 64-bit value is preserved by the checkpoint codec. Callers
provide stable request/result hashes, which must identify the relevant call
shape and stream position. Console input/output, file contents, network
payloads, process state, and foreign-call results still exceed the scalar
record shape. Recording those kinds marks the oracle incomplete, and replay
refuses incomplete data even if a serialized exactness flag is forged. The
typed console adapters and virtual file store still need a shared durable
effect-event path before those effects can contribute to exact replay.

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

The typed `service_restore_fresh_checkpoint` API restores a decoded managed
checkpoint by first comparing its full build identity and canonical fingerprint
of the complete EDIR image with the destination, then replaying its event prefix
into a temporary exact managed service. It checks the resulting event position,
state hash, and machine snapshot before applying the checkpoint's side state.
It requires negotiated checkpoint support and a `Created` destination with no
recorded events or branch records; caller-seeded debug configuration is
retained. Checkpoint integrity and identity checks detect accidental
mismatches, but the hashes do not authenticate an untrusted checkpoint. This
API is an in-process surface; the compact headless wire protocol does not
transfer checkpoint payloads.

Historical values use an explicit `Absent` state in addition to unavailable,
optimized-away, uninitialized, invalid, and redacted states. Query results
carry cancellation and resource-limit outcomes, and never turn an incomplete
scan into a complete answer.
Durable managed checkpoints carry both recording and branch identities; either
identity being absent invalidates the checkpoint before restoration.
Build manifests likewise require every present artifact to carry a known kind,
nonzero size, and nonzero content identity before launch or recording is allowed.

Concurrency exploration is bounded by task, event, preemption, branch, and
work limits. Race reports describe observed concurrent accesses under the
captured vector-clock model; they do not claim race freedom for schedules
outside the explored bound.

Trace health is monotonic. A later corrupt or unsupported event records the
last verified prefix and downgrades capabilities at that boundary. Retention
marks only unpinned, unreferenced chunks for collection so checkpoint and
branch dependency closures remain recoverable after interrupted cleanup.

Durable trace file reads and writes reject any path containing a parent
directory component before opening, staging, or renaming a file. This keeps
the bounded trace API from turning a caller-controlled relative path into an
escape from its selected trace directory while preserving ordinary absolute
and nested paths for host integrations.

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
ELF symbol entries are decoded only from complete, entry-size-aligned symbol
sections. Name-string resolution follows the section's linked string table and
returns explicit invalid or truncated state instead of scanning beyond the
declared table.
Mach-O `nlist_64` entries are likewise read only through a validated
`LC_SYMTAB` command, with checked symbol and string-table ranges.
Mach-O symbol names follow the declared string-table range and use the same
bounded, explicit invalid/truncated result contract as ELF names.
An ELF or Mach-O symbol with name offset zero is represented as a valid empty
name, preserving the object-file convention for unnamed entries.
Nonempty native names can be converted to deterministic bounded FNV identities
through `DebuggerNativeSymbols::symbol_name_id`; zero or oversized names return
the reserved invalid identity.
`DebuggerNativeSymbolLoader` is the provider-neutral materialization boundary:
it accepts only validated parsed records, derives stable record identities from
name/address/size, and leaves malformed or zero-sized symbols out of the table.
Its ELF section loader validates the complete bounded section before publishing
any entries, so a malformed symbol or name cannot leave a partially populated
table behind.
Capacity exhaustion and identity collisions use the same rollback rule.
