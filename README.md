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
- `DebuggerBreakpoints` owns build-aware breakpoint status and hit policy.
- `DebuggerConcurrency` owns logical task and wait-edge identities.
- `DebuggerHistory` owns bounded historical query descriptors.
- `DebuggerReplayEngine` executes verified EDIR images, records pre-step state,
  and performs bounded reverse-step/seek on logical machine state.
- `DebuggerManagedEngine` binds that replay engine to a session and exposes
  launch, pause, continue, step, reverse-step, seek, and durable checkpoint
  operations through one provider-neutral controller.
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
- `DebuggerProtocol`, `DebuggerSessionService`, `DebuggerSecurity`, and
  `DebuggerBuild` are public integration contracts for DAP, JetBrains, CLI,
  remote, and headless clients; private limits are named constants in each
  module.
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
and emits the first protocol discovery response. Its standard output is
protocol-only, which makes it safe for an editor, test runner, or another
process to launch and supervise. The request parser is bounded and rejects an
invalid frame without attempting to execute target code.

`build/elisa-debugger-dap-server` is the standard DAP transport entrypoint. It
accepts `Content-Length` framed messages and dispatches initialize, launch,
configuration, continue, next, reverse-step, pause, threads, stack, scopes,
variables, evaluate, breakpoint, and lifecycle commands. It correlates every
response with the request sequence and applies the shared session state
machine. Managed capability negotiation advertises reverse execution,
watchpoints, and hover evaluation; unavailable values remain explicit in the
response body rather than being fabricated.

`build/elisa-debugger-cli` accepts one command per line (`launch`, `pause`,
`continue`, `step`, `reverseStep`, and `close`) and reports machine-readable
generation/status lines through the same dispatcher used by the session server.

The server remains intentionally bounded: launch, pause, continue, terminate,
detach, generation checks, and sequence correlation are live session
operations. Target argument decoding, full source-file payloads, and provider
selection are explicit protocol extensions; clients must use capability
negotiation and standard DAP failure responses instead of assuming an
unconfigured target exists.

## Integration boundary

VS Code and JetBrains integrations should launch the headless process and use
the documented protocol. They do not import private modules, parse CLI text,
or duplicate replay policy. The DAP adapter and advanced session service share
the same `DebuggerSession` state and stop-generation semantics. See the
protocol specification for framing, IDs, coordinates, version negotiation,
pagination, cancellation, and error behavior.
