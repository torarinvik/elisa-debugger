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
validator rejects stale generations, missing or mismatched session-owner tokens
for mutations and cancellation, oversized targets, and unsupported trace
operations before the provider is touched. The transport passes the expected
owner token it issued for the session; a non-zero token supplied by a client is
not sufficient by itself.
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

The adapter follows the `linesStartAt1` and `columnsStartAt1` options from the
`initialize` request. Both default to `true`; the adapter converts Elisa's
one-based source lines and zero-based UTF-16 columns to the requested bases.
Unknown source locations use `0` for both coordinates. Keep the response
`request_seq` and the adapter sequence separate. A client may send multiple
frames in one write and may fragment a frame across reads.

For the current managed provider, set `arguments.program` to a verified `.edir`
artifact path. The adapter loads and verifies the file before starting the
session, then reports instruction source lines from that artifact. Missing or
invalid artifacts fail the launch. Use the `variablesReference` returned by
`scopes` to request the current locals. The reference is tied to the stop
generation and becomes stale after execution advances. Variable requests may
include bounded `start` and `count` fields; initialized integer locals are
returned as values, while uninitialized locals are marked `<unavailable>`.
Until source-name metadata is emitted, locals use stable ordinal names such as
`local0`.

EDIR schema 2 carries a bounded source-file table with source IDs, normalized
logical paths, content digests, and line counts. `setBreakpoints` accepts the
standard `source.path` form and resolves it only against that table; it never
derives a file ID from the client path. A positive `sourceReference` remains
supported for clients that already use the earlier adapter extension. If both
fields are supplied they must resolve to the same source file. Path matching
uses exact normalized path bytes, with client backslashes treated as `/`;
unknown or ambiguous paths fail the request. Since editors normally send an
absolute path while EDIR stores portable relative logical paths, a DAP `launch`
request can include the adapter option `sourcePathRoot` set to the local
workspace root. The adapter strips only that exact root prefix at a path
separator boundary, then resolves the remaining relative path exactly. For
example, `/work/project/src/main.elisa` maps to `src/main.elisa` when
`sourcePathRoot` is `/work/project`; Windows drive roots and backslash paths are
also supported, including UNC roots. Windows root matching ignores ASCII case
differences and normalizes backslashes; the relative logical path still matches
exactly. The option must be an absolute POSIX path, a drive path, or a UNC
share path, and it never performs basename or suffix matching. `stackTrace` returns a DAP
`source` object using the same mapped path, so clients can open the frame and
reuse its path in later breakpoint requests. Clients that already send the
EDIR logical path can omit the option. The metadata currently contains no
embedded source text, so a content digest alone does not prove that a client's
workspace file has matching contents.

The normal adjacent compiler checkout may not include the EDIR lowering
extension. With an Elisa compiler checkout that supports `-emit edir`, run
`make ELISA_EDIR_COMPILER=/path/to/elisac_stage1.sh compiler-edir-check` to
compile the typed-local fixture, load and execute its artifact in the debugger
VM, exercise DAP local inspection, and compare the native result. This gate
currently covers one typed `i64` local with literal arithmetic; unsupported
source shapes are rejected by the compiler. Ordinary source compilation and
native-program launch through DAP remain unavailable on this managed provider.

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
