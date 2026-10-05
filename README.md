# Elisa debugger

This repository contains the Elisa implementation of the debugger core and its
editor-neutral integration boundary. The implementation is deliberately split
into qualified modules:

- `DebuggerIdentity` owns stable build, source, position, allocation, and
  binding identities.
- `DebuggerCapabilities` owns engine/history feature negotiation.
- `DebuggerSession` owns lifecycle and stop-generation rules.
- `DebuggerEvents` owns typed event envelopes.
- `DebuggerEDIR` owns the first managed instruction verifier and machine slice.
- `DebuggerReplay` owns cursors, checkpoints, and immutable branch lineage.
- `DebuggerTrace` owns versioned trace metadata and chunk validation.
- `DebuggerValues` owns typed inspection states and stale value handles.
- `DebuggerMetadata` owns content-addressed source spans and function metadata.
- `DebuggerSourceStore` owns bounded source-file, function, and client-path
  metadata registration with explicit validation and lookup APIs.
- `DebuggerBreakpoints` owns build-aware breakpoint status and hit policy.
- `DebuggerConcurrency` owns logical task and wait-edge identities.
- `DebuggerHistory` owns bounded historical query descriptors.
- `DebuggerTimeline` owns bounded retained-history coordinates and bookmarks.
- `DebuggerReplayEngine` executes verified EDIR images, records pre-step state,
  and performs bounded reverse-step/seek on logical machine state.
- `DebuggerManagedEngine` binds that replay engine to a session and exposes
  launch, pause, continue, step, reverse-step, seek, and durable checkpoint
  operations through one provider-neutral controller.
- `DebuggerManagedService` is the public managed provider facade for editor and
  test-runner bridges; it dispatches typed requests into that controller and
  exposes bounded frame/local snapshots.
- `DebuggerEngine`, `DebuggerNative`, and `DebuggerAgent` define the provider
  contract and the explicit native-agent capability boundary.
- `DebuggerEffects`, `DebuggerScheduler`, `DebuggerTraceStream`, and
  `DebuggerProvenance` provide bounded effect virtualization, deterministic
  scheduling, trace recovery, and allocation-aware mutation history.
- `DebuggerQueryEvaluator` executes bounded historical predicates with
  cancellation and explicit no-match/resource-limit results.
- `DebuggerTraceBinary` and `DebuggerTraceStorage` provide canonical
  little-endian encoding, checksums, chunk validation, and torn-write prefix
  recovery without serializing host memory layouts.
- `DebuggerTraceRecorder`, `DebuggerTraceBundle`, `DebuggerTraceReader`, and
  `DebuggerCheckpointCodec` provide bounded manifest/event recording,
  append-only bundle verification, event decoding, and restart-safe managed
  checkpoints.
- `DebuggerHistoricalValues` preserves absent, unavailable, optimized-away,
  uninitialized, invalid, and redacted values across historical positions.
- `DebuggerQueryEngine` provides cancellable last-write and first-change
  queries over bounded provenance indexes.
- `DebuggerReplayCompare` aligns verified branches by shared semantic event
  prefixes and reports the first divergence.
- `DebuggerConcurrencyExploration` provides bounded alternate schedule and
  observed race analysis with explicit exploration limits.
- `DebuggerTraceHealth` and `DebuggerTraceRetention` preserve verified trace
  prefixes and protect pinned checkpoint/branch dependency closures during
  collection.
- `DebuggerNativeAttach`, `DebuggerBuildInvocation`, and
  `DebuggerProtocolConfig` define explicit native attach, structured compiler,
  and editor launch contracts without shell command construction.
- `DebuggerProtocol`, `DebuggerSessionService`, `DebuggerSecurity`, and
  `DebuggerBuild` are public integration contracts for DAP, JetBrains, CLI,
  remote, and headless clients; private limits are named constants in each
  module.
- `DebuggerDiscovery`, `DebuggerProtocolEvents`, and `DebuggerMemory` expose
  machine-readable capability discovery, ordered event delivery, and bounded
  managed-memory inspection for editor-neutral clients.
- `DebuggerProtocolIntegration` provides the typed discovery document,
  ownership token, stale-generation, paging-limit, and trace capability
  checks shared by editor and headless clients.
- `DebuggerCLIEntrypoint` provides a line-oriented interactive/machine command
  mode without duplicating session policy.
- `DebuggerProtocolFraming` owns bounded length-prefixed transport framing.
- `DebuggerProtocolServer` owns the first headless Elisa session endpoint.
- `DebuggerDAP` projects session capabilities into editor debugger features.

All debugger-owned executable logic is written in Elisa. The compiler and
runtime are external build prerequisites; no debugger policy is implemented in
the host Makefile or an editor plugin.

## Build and verify

The default compiler path expects the sibling self-hosted Elisa compiler and its
runtime object:

```sh
make check server
make smoke
# Compile the additional provider, trace, query, and protocol modules.
make module-check
# The source metadata and protocol event modules also have focused checks.
make source-store-check protocol-events-check
```

The Makefile requires a fresh sibling compiler product by default. Keep
`ELISA_ALLOW_STALE_STAGE1=0` for the strict compiler-freshness gate; setting it
to `1` is an explicit escape hatch for investigating older build artifacts.
The build output is ignored under `build/`.

`build/elisa-debugger` runs the deterministic core self-test. The self-test
returns a nonzero code for identity, capability, session, event, EDIR, replay,
or adapter regressions.

`build/elisa-debugger-server` is a headless Elisa process endpoint. It accepts
the framed request shape in [spec/session-protocol.md](spec/session-protocol.md)
and first negotiates protocol major/minor versions through `initialize`; an
incompatible major receives an explicit error, and session methods require a
successful negotiation. It can launch a verified EDIR
artifact through `arguments.program`, control the managed execution, and return
stack, scope, and paged local snapshots. Its standard output is protocol-only,
which makes it safe for an editor, test runner, or another process to launch
and supervise. The request parser and EDIR file loader are bounded, and an
invalid artifact is rejected before execution. The initialize wire schema is
published at
[schemas/session-protocol-v1.initialize.schema.json](schemas/session-protocol-v1.initialize.schema.json).

`build/elisa-debugger-dap-server` is the standard DAP transport entrypoint. It
accepts `Content-Length` framed messages and dispatches initialize, launch,
configuration, continue, next, reverse-step, pause, threads, stack, scopes,
variables, evaluate, source and function breakpoints, `readMemory`, and
lifecycle commands. It correlates every response with the request sequence and applies the shared
session state machine. Its current `initialize` response advertises
`configurationDone`, function, conditional and hit-conditional breakpoints,
logpoints, hover evaluation, `stepBack`, `terminate`, and bounded `readMemory`
for the managed provider. Conditional and numeric hit-condition support
applies to both source and function breakpoints. Data breakpoints, restart,
`setVariable`, and disassembly remain unsupported. Plugins should use the
actual capability response rather than the broader typed Elisa module surface.
The adapter also advertises optional host-effects extension version 1 for
clock, random, console input, and console output. Clients that implement it
must inspect execution responses and reply through the same DAP session; see the
[host-effects contract](spec/dap-host-effects-v1.md).

`build/elisa-debugger-jetsam` is a read-only macOS memory-pressure report
inspector. Build it with `make ELISA_ALLOW_STALE_STAGE1=0 native-jetsam-tool`,
then inspect one snapshot with `build/elisa-debugger-jetsam <report.ips> [pid]`
or compare two ordered snapshots with
`build/elisa-debugger-jetsam --compare <baseline.ips> <latest.ips> [pid]`.
The optional PID defaults to the report's `largestProcess`. Inputs are capped
at 16 MiB and matched by PID plus process binary UUID before comparison. This
tool reports Jetsam counters; it does not attach to a live process or identify
native allocation call sites. Run its regression fixture with
`make ELISA_ALLOW_STALE_STAGE1=0 native-jetsam-check`.

`build/elisa-debugger-procinfo <pid>` takes one read-only live macOS process
resource snapshot. Build it with
`make ELISA_ALLOW_STALE_STAGE1=0 native-macos-resources-tool`. It reports
virtual/resident bytes, process and thread CPU time, thread counts, page faults,
and the process start identity. It does not suspend the target, read its memory,
trace allocations, or integrate with an interactive debugger session. Verify
the sampler with `make ELISA_ALLOW_STALE_STAGE1=0 native-macos-resources-check`.

`build/elisa-debugger-memread <pid> <0x-address> <length>` performs one bounded,
read-only macOS task-memory read (1–4096 bytes). Build it with
`make ELISA_ALLOW_STALE_STAGE1=0 native-macos-memory-tool`; run its focused
self-read and bounds regression with
`make ELISA_ALLOW_STALE_STAGE1=0 native-macos-memory-check`. It never suspends
or writes to the target, and it is not yet connected to DAP or a persistent
attach session. macOS may refuse `task_for_pid`; reading another hardened app
can require debugger signing entitlements and target authorization, and
protected system processes remain unavailable. Treat the hex output as
sensitive process data. This primitive is a foundation for attach inspection,
not an allocation profiler or proof of the cause of a memory spike.

`build/elisa-debugger-cli` accepts one command per line (`launch`, `attach`,
`pause`, `continue`, `step`, `reverseStep`, `seek`, `timeline`, `inspect`, `tasks`,
`checkpoint`, `compare`, `traceVerify`, `saveTrace`, `openTrace`, and `close`). Session
commands share the dispatcher used by the headless service. `timeline` prints
the current event and branch, retained/exact bounds, seek/reverse eligibility,
and stop generation. Use `seek <event> [expected-stop-generation]` to move to
an exact event; the optional generation rejects stale scripted seeks. Use
`saveTrace <path>` to transactionally write an exact managed trace to a file;
for example, `saveTrace build/session.trace`. In a new CLI process, use
`openTrace <event> <path>` to validate a saved trace against the CLI's default
managed image, replay its bounded history, and position at the requested event
before inspecting or seeking through its timeline; for example,
`openTrace 1 build/session.trace`. The path is the remaining text after the
event, so spaces are preserved. The DAP adapter advertises version 1 of
`supportsElisaTraceFiles`, with `elisa/saveTrace` and generation-aware
`elisa/openTrace` requests on the existing adapter connection. Reopening
requires the trace to match the currently loaded EDIR build and image; refresh
timeline and inspection after its stopped event. See the
[versioned DAP trace-file contract](spec/dap-trace-files-v1.md). The compact
JSON process still cannot carry a destination path or return trace artifact
bytes, so trace-file transfer is available through the interactive CLI, DAP,
and typed Elisa service API.

The headless process currently owns one managed session per process. Its
inspection results are tied to the returned stop generation; local pages use
bounded `pageSize` and `pageStart` operands. It returns the managed session's
single `main` thread, accepts `setBreakpoints` for normalized logical paths
in the launched EDIR artifact, supports bounded managed-memory reads with
`arguments.address` and `arguments.length`, and returns checkpoint/branch
metadata for validated managed history. It also exposes read-only
`trace.verify` metadata for the bounded current recording. The `evaluate`
request accepts the shared bounded expression grammar, a zero-based frame
index, and an optional expected stop generation; signed results are decimal
strings. Trace artifact transfer and provider selection are not wired on this
endpoint;
discovery reports the smaller process capability set. See [the integration
guide](docs/integration.md) for the exact process boundaries and limitations.

## Integration boundary

VS Code integrations should launch the DAP adapter for the standard debugger
experience. JetBrains plugins can use that adapter where their chosen host
route supports DAP; otherwise they can map supported operations to the
headless JSON process. The transports use the same managed engine policy, but
each process owns an independent session. No VS Code or JetBrains plugin is
included or qualified here. Host glue must not import private modules, parse
CLI text, or duplicate replay policy. See the [integration guide](docs/integration.md),
[compiler integration record](docs/compiler-integration.md),
[plugin-author guide](spec/plugin-integration.md), and the protocol
specification for current limits and wire details.

The source also contains typed `DebuggerTimeline`, `DebuggerMemory`, and
`DebuggerProtocolEvents` contracts for Elisa callers. These modules are not a
stable cross-language ABI, and the compact process does not serialize their
advanced surfaces or share a running session with a second connection.
External plugins should enable panels only when their selected transport
implements the corresponding operations.
