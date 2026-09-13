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

The Makefile allows a stale sibling compiler product by default because that
checkout can contain unrelated work. Set `ELISA_ALLOW_STALE_STAGE1=0` for the
strict compiler-freshness gate.
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
variables, evaluate, breakpoint, `readMemory`, and lifecycle commands. It
correlates every response with the request sequence and applies the shared
session state machine. Its current `initialize` response advertises
`configurationDone`, `stepBack`, `terminate`, and bounded `readMemory` support
for the managed provider. It reports function, conditional, hit-conditional,
and data breakpoints; hover evaluation; restart; set-variable; and disassembly
as unsupported. Plugins should use the actual capability response rather
than the broader typed Elisa module surface.

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

`build/elisa-debugger-cli` accepts one command per line (`launch`, `attach`,
`pause`, `continue`, `step`, `reverseStep`, `seek`, `inspect`, `tasks`,
`checkpoint`, `compare`, `traceVerify`, `saveTrace`, and `close`) and reports
machine-readable generation/status lines through the same dispatcher used by
the session server. Commands that require a request payload remain available
through the framed session service, while the line mode keeps one stable,
argument-free operation vocabulary.

The headless process currently owns one managed session per process. Its
inspection results are tied to the returned stop generation; local pages use
bounded `pageSize` and `pageStart` operands. It returns the managed session's
single `main` thread. Expression evaluation, source breakpoint payloads, trace
artifact transfer, memory reads, and provider selection are not wired on this
endpoint; discovery reports the smaller process capability set. See [the
integration guide](docs/integration.md) for the exact process boundaries and
limitations.

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
