# Plugin integration guide

The debugger exposes process transports; a plugin owns presentation and
workspace configuration. The Elisa core owns debugger policy, but each process
transport exposes only the operations it can carry end to end. This repository
does not include a VS Code or JetBrains plugin or certify a host-platform
integration. For the transport comparison and current host mapping, see the
[editor integration guide](../docs/integration.md).

## VS Code

Register a debugger type whose adapter executable is
`build/elisa-debugger-dap-server` (or the installed equivalent) and connect
its standard input/output streams using DAP `Content-Length` framing. A launch
configuration for a plugin type named `elisa` can look like this:

```json
{
  "type": "elisa",
  "request": "launch",
  "name": "Debug EDIR artifact",
  "program": "${workspaceFolder}/build/program.edir",
  "sourcePathRoot": "${workspaceFolder}"
}
```

The plugin supplies its own debugger `type`; `request` must be `launch`.
`program` must identify a complete, supported EDIR artifact. The adapter
checks the artifact bytes before starting the managed session; it does not
compile `.elisa` source and does not require the filename to end in `.edir`.
`sourcePathRoot` is optional and maps absolute editor paths to EDIR's relative
logical source paths. Without it, the client must use the exact logical path
stored in the artifact. The [launch-configuration schema](../schemas/dap-launch-configuration.schema.json)
documents these fields. It also lists `args`, `cwd`, `env`, and `stopOnEntry`
as ignored because the current adapter does not apply them.

The adapter does not implement DAP `attach`. The
[attach-configuration schema](../schemas/dap-attach-configuration.schema.json)
intentionally rejects every attach configuration so a plugin can disable that
mode instead of offering a nonfunctional choice. The separate Elisa native
attach model is not connected to this DAP endpoint.

Start one adapter process for each debug session. Send DAP `initialize`, then
`launch`; process `initialized` and later stop/termination events according
to their DAP sequence numbers. Read capabilities from the `initialize`
response and offer only the operations it advertises. Use `configurationDone`
and the ordinary DAP breakpoint, thread, frame, scope, and variable requests
supported by that response. Do not invoke a shell to assemble a command line
or treat DAP's `program` as an Elisa source file.

The DAP process does not return a cross-connection session identity. A second
process cannot attach to or share the running DAP session. Timeline and branch
controls that need more than the DAP operations must use an integration that
already owns the same in-process managed service. The standalone headless
session process exposes the compact `createSession` ownership handshake; it
does not turn the DAP process into a shareable session.

## JetBrains

Use the same DAP executable and launch fields when the selected JetBrains
host/plugin route supports DAP. Map the run configuration to
`request=launch`, `program`, and, when required, `sourcePathRoot`; do not expose
attach for this adapter. If a host-specific bridge is required, it can call
only the operations exposed by a process transport. The public Elisa modules
are source-level APIs for Elisa callers, not a stable cross-language ABI; a
Kotlin or Java plugin cannot directly call them as a supported integration
route. Do not parse human CLI output or reimplement debugger policy. This guide
does not claim a JetBrains version has been tested.

The DAP adapter uses standard DAP `initialize` capabilities. The headless
process has a separate `discover`/`initialize` version handshake; its current
`initialize` request requires numeric `protocolMajor` and `protocolMinor`.
Clients may then send `createSession` and must preserve its returned
`sessionId` and `ownerToken` according to the
[`createSession` schema](../schemas/session-protocol-v1.create-session.schema.json).
Progress notifications and event acknowledgements remain outside the compact
process transport.

## Other clients

Use `spec/session-protocol.md` for headless tools, test runners, CI, and custom
frontends. The compact process protocol uses length-prefixed UTF-8 JSON on
stdin/stdout, independently from target output. It accepts request IDs as
unsigned JSON integers or decimal strings and returns them as strings; event
ordinals are strings. The broader typed target contract uses string IDs.
Clients must not coerce returned IDs or ordinals to floating-point numbers.
Before protocol negotiation, send `discover` and use its feature flags to
decide which controls to expose. Validate its wire shape against the
[discovery schema](../schemas/session-protocol-v1.discover.schema.json); the
protocol specification includes a replayable request/response transcript for
clients in any language.

Clients using the typed Elisa service must handle its cancellation, stale
generation, capability, and bounded-history results. The current compact
headless process does not emit progress/events or route cancellation. It does
expose the read-only `timeline` snapshot, while other advanced result payloads
remain typed-only. A client that only supports ordinary DAP debugging should
use the advertised DAP capabilities and avoid assuming that a method name in
the broader session protocol is wired to that process.

An Elisa component built in-process can call typed service APIs without
opening the interactive CLI. Those APIs do not extend the compact JSON process
transport, and the current DAP process does not expose the advanced timeline
snapshot. Where a transport actually supplies a session ownership token and stop
generation, clients must preserve them and reject stale handles. When a trace
is partial, show the last verified event and disable reverse actions beyond
it. When a value is unavailable, render its availability state instead of
displaying a numeric zero.

The `timeline`, `memory`, and `events` surfaces have public Elisa contracts
backed by `DebuggerTimeline`, `DebuggerMemory`, and `DebuggerProtocolEvents`.
The compact process serializes `timeline`, bounded managed `memory` reads, and
the metadata result of `trace.verify`; `events` remains a typed surface until
a transport advertises and implements its result payload.

## Remote artifact transfer

The Elisa source defines an authenticated-channel policy and bounded remote
artifact-transfer state machine. It does not ship a network listener, tunnel,
or cryptographic handshake. A host that supplies those pieces can start a
transfer with the byte length and canonical checksum, send bounded chunks in
zero-based sequence order, and finish only after all bytes arrive and the
checksum matches. The backend rechecks transfer authorization at each step;
the host remains responsible for reconnect and incomplete-transfer handling.

Before forwarding a remote operation, the agent must call
`DebuggerRemote::remote_authorize` for its `RemoteOperation`. Authorization
requires a connected, authenticated, non-quota-exceeded channel and applies a
separate policy bit for inspection, execution control, debugger mutation,
external process execution, or artifact transfer. Debugger mutation is
controlled by `Policy.mutate` and defaults off; it is distinct from writing
files. External process execution uses `spawn_process`, and artifact transfer
uses `export_trace`. Artifact begin, chunk, and finish operations recheck the
artifact-transfer permission so changing or revoking policy during a transfer
cannot bypass the gate. A host must still provision the authenticated tunnel
or local IPC peer; this API does not supply cryptography.
