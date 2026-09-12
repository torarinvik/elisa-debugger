# Plugin integration guide

The debugger is a process service. A plugin owns presentation and workspace
configuration; the Elisa executable owns target execution, source identity,
replay, checkpoints, branches, and capability decisions.

## VS Code

Register a debugger type whose adapter executable is
`build/elisa-debugger-dap-server` (or the installed equivalent). Launch it with
standard input/output transport. For the current managed provider, pass a
verified `.edir` artifact path in `arguments.program`. The adapter opens and
verifies that artifact before launching the managed session. It does not yet
compile Elisa source or apply `args`, `cwd`, `env`, or `stopOnEntry`; do not
present those options as active until their execution path is implemented.
Do not invoke a shell to assemble a command line.

The adapter must be started once per debug session. The plugin should keep the
returned session identity and use the normal DAP request/event lifecycle. The
managed adapter routes launch, pause, continue, next, step back, and stack
positions through the same EDIR session engine used by the Elisa facade. A
timeline or branch panel may open a second connection to the session service,
but it must use the same session and stop generation rather than launch a
second target.

## JetBrains

Use the same DAP process when the host's DAP integration is available. If the
target JetBrains platform requires a native debugger bridge, keep that bridge
thin: map run configuration, breakpoint, frame, scope, variable, evaluate,
pause, resume, and termination actions to the session protocol. The bridge
must not parse human CLI output or reimplement replay policy.

The host integration should check `discover`/`initialize` version negotiation,
surface `UNSUPPORTED` as a capability limitation, and preserve source/build
content identities when mapping paths between the project and debug host.
Use the discovery capability and limit fields to enable timeline, checkpoint,
memory, and trace panels only when the active provider advertises them. Event
notifications are ordered by sequence and acknowledged explicitly, which lets
the bridge reconnect without replaying stale UI state.

## Other clients

Use `spec/session-protocol.md` for headless tools, test runners, CI, and custom
frontends. The request/response protocol is JSON and framed independently from
the target's stdout/stderr. IDs and event ordinals are strings; clients must
not coerce them to floating-point numbers.

All clients must handle cancellation, progress, stale stop generations,
truncated history, missing source artifacts, and capability changes. A client
that only supports ordinary debugging can ignore timeline extensions while
using the same launch/stack/variables operations.

The reference Elisa client can issue advanced operations without opening the
interactive CLI. Plugin panels should retain the session ownership token and
expected stop generation they received from `initialize`; a second panel must
reuse that session rather than launch another debuggee. When a trace is
partial, the plugin should show the last verified event and disable reverse
actions beyond it. When a value is unavailable, the plugin should render the
reported state verbatim instead of displaying a numeric zero.

The optional `timeline`, `memory`, and `events` surfaces are public protocol
contracts backed by `DebuggerTimeline`, `DebuggerMemory`, and
`DebuggerProtocolEvents`. They return typed unavailable, stale, corrupt, and
resource-limit states so clients can degrade gracefully without inspecting
private module data.

## Remote artifact transfer

Remote clients transfer traces and build artifacts through the authenticated
session channel. Start a transfer with the byte length and the canonical Elisa
checksum returned by `DebuggerRemoteArtifacts::transfer_checksum`. Send chunks
in zero-based sequence order; each chunk is bounded by the advertised transfer
limit, and a missing, duplicated, or oversized chunk fails the transfer. Finish
only after all declared bytes have arrived. The artifact becomes readable only
when the final checksum matches. Transfer failures are surfaced in both the
artifact state and the channel's public error field, and remote quota usage
includes every accepted chunk. Clients should discard incomplete transfers on
disconnect and restart them after reconnecting.
