# Plugin integration guide

The debugger is a process service. A plugin owns presentation and workspace
configuration; the Elisa executable owns target execution, source identity,
replay, checkpoints, branches, and capability decisions.

## VS Code

Register a debugger type whose adapter executable is
`build/elisa-debugger-dap-server` (or the installed equivalent). Launch it with
standard input/output transport. Forward the user's `program`, `args`,
`cwd`, `env`, `stopOnEntry`, compiler/build identity, and source mappings in a
DAP `launch` request. Do not invoke a shell to assemble a command line.

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

## Other clients

Use `spec/session-protocol.md` for headless tools, test runners, CI, and custom
frontends. The request/response protocol is JSON and framed independently from
the target's stdout/stderr. IDs and event ordinals are strings; clients must
not coerce them to floating-point numbers.

All clients must handle cancellation, progress, stale stop generations,
truncated history, missing source artifacts, and capability changes. A client
that only supports ordinary debugging can ignore timeline extensions while
using the same launch/stack/variables operations.
