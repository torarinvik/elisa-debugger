# Editor and tool integration

The debugger has two integration boundaries. Use the DAP executable when an
editor already has a DAP client. Use the versioned headless service when a
plugin or test runner wants debugger-specific history, trace, or branch
operations.

For in-process Elisa integrations, `DebuggerManagedService` is the shared
managed provider facade. Construct it with a verified `ProgramImage`, dispatch
typed requests through `service_dispatch`, and read bounded frames or locals
with `service_frame` and `service_locals`. This path executes the same replay
engine directly, including reverse-step and validated `targetEvent` seek.
The DAP executable and CLI use this facade for managed launch, pause, resume,
step, reverse-step, and seek operations. The standalone headless server keeps
the provider-neutral lifecycle dispatcher for now; in-process clients that
need managed execution can call `DebuggerSessionService::managed_new` and
`service_handle_managed` with the same envelope model.

Call `DebuggerDiscovery::discovery_for` before selecting optional UI actions.
The returned protocol version, provider kind, history mode, capabilities, and
resource limits are stable machine-readable data. Timeline positions and
bookmarks use `DebuggerTimeline`; managed heap and stack reads use
`DebuggerMemory`; ordered asynchronous notifications use
`DebuggerProtocolEvents`. These public modules keep editor adapters independent
of private replay and storage representations.

`DebuggerProtocolIntegration` is the typed contract for clients that need the
full discovery and session handshake. Its discovery document includes product
version, trace schema, installation health, per-session capabilities, and
bounded page/query/payload limits. Requests carry a client identity, session
ownership token, expected stop generation, page size, and target event. The
validator rejects stale generations, missing ownership for mutations, oversized
targets, and unsupported trace operations before the provider is touched.
Retry classification is explicit: discovery and read-only inspection operations
are safe to repeat, launch/attach/branch/terminate are forbidden to repeat after
an uncertain result, and other mutations are same-request-only so a client can
deduplicate by request ID without creating a second operation.

## VS Code

Register `build/elisa-debugger-dap-server` as a debug adapter that is launched
as a child process. Send ordinary DAP `initialize`, `launch`,
`configurationDone`, `setBreakpoints`, `threads`, `stackTrace`, `scopes`,
`variables`, `evaluate`, `continue`, `next`, `stepIn`, `stepOut`, `pause`, and
`disconnect` requests. The adapter uses `Content-Length: <bytes>\r\n\r\n` and
returns one JSON message per frame. Read the advertised capability fields on
`initialize`; do not infer support from the executable name.

The adapter reports source coordinates using DAP's one-based line and
zero-based column convention. Keep the response `request_seq` and the adapter
sequence separate. A client may send multiple frames in one write and may
fragment a frame across reads.

For the current managed provider, set `arguments.program` to a verified `.edir`
artifact path. The adapter loads and verifies the file before starting the
session, then reports instruction source lines from that artifact. Missing or
invalid artifacts fail the launch. The Elisa compiler does not emit EDIR yet,
so this path is for artifacts produced by a fixture or a compatible external
producer; ordinary source compilation and native-program launch are not
available through this provider today.

## JetBrains

Implement the JetBrains debugger-process bridge against the same DAP endpoint,
or use the headless service when the plugin needs reverse execution and trace
verification. The service is a child process with protocol-only stdout. Each
request is a decimal byte count, one space, the UTF-8 JSON payload, and a final
newline. Numeric request IDs and event ordinals are represented as decimal
strings at the external boundary so JavaScript, Kotlin, and Java clients do
not lose precision.

The service method names are versioned and editor-neutral: `discover`,
`initialize`, `createSession`, `launch`, `attach`, `openTrace`, `replay`,
`pause`, `continue`, `step`, `reverseStep`, `seek`, `threads`, `stack`,
`scopes`, `variables`, `evaluate`, `setBreakpoints`, `setDataBreakpoints`,
`checkpoint`, `branch`, `compare`, `trace.verify`, `trace.export`, `detach`,
`terminate`, and `close`. Include `expectedStopGeneration` on requests that
operate on a stopped session. A stale value produces `STALE_GENERATION` and
does not mutate the session.

Use the discovery response to hide unsupported commands and to size client
buffers from the advertised limits. Subscribe to protocol events by sequence
number and acknowledge them monotonically; do not infer stop state from log
text.

## Other clients

Keep transport, rendering, and retry policy in the client. The Elisa modules
own session transitions, capabilities, cancellation, trace exactness, and
typed failure codes. Clients should preserve unknown fields, page large
results with `next`, and treat `UNAVAILABLE`, `CORRUPT`, `DIVERGED`, and
`RESOURCE_LIMIT` as distinct states. No client should parse human-readable
messages to decide whether an operation is supported.

For a custom runner, launch the headless server, wait for `discover`, create a
session, and use the returned stop generation as the optimistic concurrency
token. For a remote runner, carry the same messages through an authenticated
tunnel and use the Elisa remote-artifact transfer checks before opening a
trace.

Remote sessions make disconnect behavior explicit through
`RemoteDisconnectPolicy`: a client can request detach, pause, or continue when
the transport disappears. The selected policy remains attached to the remote
channel across heartbeat draining and reconnect attempts; quota failures still
block reconnect until a new channel is created.
