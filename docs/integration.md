# Editor and tool integration

Use one of the two process boundaries according to the host's debugger
support:

| Boundary | Use it for | Current scope |
| --- | --- | --- |
| DAP adapter, `build/elisa-debugger-dap-server` | Editors that can launch a Debug Adapter Protocol process | Managed EDIR launch, source-line debugging, stack and local inspection, memory reads, and the advertised forward/reverse stepping operations |
| Headless service, `build/elisa-debugger-server` | Test runners, custom frontends, and hosts that need direct managed-session requests | Versioned compact JSON framing, managed EDIR lifecycle and time navigation, and bounded frame/local inspection |

Each process owns its own managed session. The DAP and headless transports do
not attach to or share one another's session. Neither process currently ships a
network listener. The public Elisa modules define source-level APIs for Elisa
callers; they are not a stable cross-language ABI. Plugins written in another
language should use DAP or the documented JSON process boundary.

The [support matrix](support-matrix.md) and the running endpoint's discovery or
capability response define what is available. Method names in a typed Elisa
module or in the protocol vocabulary do not establish that a process transport
implements that method's operands and result. In particular, this repository
does not ship a VS Code or JetBrains plugin, and has not qualified either host
integration end to end.

## DAP process

Launch `build/elisa-debugger-dap-server` as a child process and connect its
standard input and output using DAP `Content-Length` framing. Standard output
is reserved for protocol messages. The adapter implements managed EDIR
launch; `program` is a verified EDIR artifact, not Elisa source. It does not
compile source or apply `args`, `cwd`, `env`, or `stopOnEntry` from a launch
configuration. DAP attach is unavailable.

The current adapter supports source-line breakpoints against the EDIR source
table, one `main` thread, stack and locals inspection, bounded local paging,
`readMemory`, continue, pause, `next`, `stepIn`, `stepOut`, `stepBack`,
`reverseContinue`, disconnect, and terminate. Source paths must match the
artifact's logical paths. Set the adapter launch argument `sourcePathRoot` to
the workspace root when the editor sends absolute paths; the adapter removes
that exact root prefix before matching. It does not use basename or suffix
matching. Source breakpoints support bounded arithmetic expression conditions,
positive numeric hit conditions, and `logMessage` logpoints with `{expression}`
interpolation. A logpoint emits a DAP `output` event without stopping; a
condition and hit condition are applied before the message is emitted. A
message is limited to 256 decoded bytes, and a breakpoint replacement accepts
at most 8192 combined decoded condition and log-message bytes. Each continue
request buffers at most 8192 bytes of log output. If a template expression
cannot be evaluated or the output bound is reached, continue stops with an
error instead of silently discarding the log. Expression evaluation is bounded
and side-effect free.
Function and data breakpoints, variable assignment, restart, and disassembly
remain unavailable. The initialize response advertises the relevant DAP
capabilities; clients should honor that response.

The DAP adapter honors `linesStartAt1` and `columnsStartAt1`. `stackTrace`
supports the standard `startFrame` and `levels` paging arguments and reports
`totalFrames`; initialization advertises
`supportsDelayedStackTraceLoading`. Treat returned `frameId` and
`variablesReference` values as opaque handles. Both are valid only for the stop
generation that produced them, so request a fresh stack trace and scopes after
execution advances. The adapter supports both `source.path` and a known
positive `sourceReference` for source breakpoints; when both are supplied they
must identify the same EDIR source entry.

DAP source breakpoints may include an optional `column`. The adapter converts
one-based DAP columns to zero-based coordinates when `columnsStartAt1` is true,
matches that position against executable EDIR source spans, and returns the
normalized line and column with each breakpoint response. A breakpoint without
a column keeps the existing line-only resolution and response shape. Column
matching is correct when EDIR source spans already use the session
protocol's zero-based UTF-16 columns. Current compiler-emitted EDIR artifacts
use one-based UTF-8-byte columns, so they are incompatible even for ASCII until
the producer normalizes them. The DAP adapter does not infer or transcode those
producer-specific units; `columnsStartAt1` only selects the zero-based versus
one-based DAP coordinate basis. Non-ASCII UTF-16 matching is not verified for
current compiler artifacts.

## Headless JSON process

Run `build/elisa-debugger-server` with one process per client session. The
transport is a decimal UTF-8 byte length, one space, the JSON request, then a
newline. Send `discover`, validate its response with the
[discovery schema](../schemas/session-protocol-v1.discover.schema.json), then
negotiate protocol major/minor with `initialize` before session methods. The
protocol guide includes a complete discovery transcript. The compact process currently supports
protocol `1.0`; see the [initialize schema](../schemas/session-protocol-v1.initialize.schema.json)
and [wire specification](../spec/session-protocol.md) for exact framing,
fields, and errors.

The supported compact request flow is `launch` with
`arguments.program`, `setBreakpoints`, `pause`, `continue`, `step`,
`reverseStep`, `seek`, the read-only `timeline` history extension, bounded managed `memory` reads, and checkpoint/branch metadata.
The read-only `trace.verify` method also returns bounded verification metadata
for the current managed trace; opaque trace bytes still require a separate
transport.
After launch, `threads` returns one logical `main` thread, including while the
session is running. Pause before requesting `stack`, `scopes`, or `variables`.
`program` must name a complete verified EDIR artifact. `variablesReference` is
generation-bound; request a fresh scopes response after execution advances.
Variable pages use top-level `pageSize` and decimal-string
`pageStart`/`next` offsets. The current page-size limit is 256 entries.

For source breakpoints, send `setBreakpoints` with
`arguments.source.path` equal to the artifact's normalized logical source path
and a `breakpoints` array of positive line numbers. The endpoint replaces that
source's complete breakpoint set and returns each breakpoint ID, line, and
`verified` status. A path absent from the artifact metadata is rejected;
absolute editor paths must be mapped to the EDIR logical path by the host.
Requests are bounded to 32 lines per source. The
[set-breakpoints schema](../schemas/session-protocol-v1.set-breakpoints.schema.json)
defines the compact wire shape.

The `timeline` response reports the current event and branch, retained and
exact bounds, bounded bookmarks, and the latest checkpoint event and state
digest. It is valid only while the managed session is stopped or replaying;
clients should pass its `stopGeneration` when issuing a seek or reverse
request. Event and identity fields are decimal JSON strings. Providers without
history return `UNSUPPORTED` or `UNAVAILABLE`. Validate the wire shape with the
[timeline schema](../schemas/session-protocol-v1.timeline.schema.json).

Checkpoint and branch requests return validated metadata (`event`/`stateHash`
or a branch ID) and preserve the same stop-generation rules. `trace.verify`
returns `state`, verified chunk/event counts, and a replayability flag; a
successful response is a snapshot and carries the current stop generation.
This endpoint does not implement attach, expression evaluation, or trace
artifact transfer.
`createSession` can establish process-scoped session ownership before launch;
after that handshake, preserve the returned `sessionId` on every request and
the returned `ownerToken` on every state changing request. Comparison and
trace operations that need structured operands or results are not available
through this compact endpoint merely because corresponding typed Elisa APIs
exist. `discover` reports the compact endpoint's
capabilities, with process-inaccessible features disabled. Reverse execution
uses the same managed service history that produces the timeline snapshot.

The compact process does not emit progress or ordered session events, route
cancellation, or let another process attach to its session. Requests and
responses are documented in
[the session protocol](../spec/session-protocol.md). That document labels the
broader typed target contract separately from the methods currently wired to
the compact process.

## Host adapter mapping

| Host | Map host actions to | Current adapter guidance |
| --- | --- | --- |
| VS Code | DAP initialize/launch, source breakpoints, threads/frames/scopes/variables, execution requests, and lifecycle | Register a debugger type in the consuming plugin, point it at the DAP executable, and use `program` plus optional `sourcePathRoot` in launch configuration. This repository supplies the backend, not the extension manifest or TypeScript host glue. |
| JetBrains | The same DAP operations where the selected IDE/plugin route can launch a DAP adapter; otherwise the compact JSON requests the host can support | No JetBrains plugin or platform-version qualification is included. A host-specific bridge must only translate UI/session requests and render responses; it cannot obtain attach, evaluate, or advanced trace operations from the current compact endpoint. |
| Other editors and tools | DAP for standard debugger UI; compact JSON for custom managed lifecycle/inspection clients | Launch the child process directly, keep protocol output separate from logs, preserve decimal IDs/offsets as strings where the protocol says strings, and report unavailable operations from endpoint behavior rather than parsing messages. |

For a DAP host, the mapping is direct: source-line breakpoints use
`setBreakpoints`; call-stack and local panes use `threads`, `stackTrace`,
`scopes`, and `variables`; controls use the supported execution requests; the
host displays capability fields and protocol errors. For a compact JSON host,
map lifecycle controls and source breakpoints to the documented request
names, refresh inspection handles on every stop-generation change, and keep
the headless process private to that client. There is no supported way to
combine a DAP session with a second headless connection.

## Integration rules

- Use the transport's capability and error responses to gate UI actions, while
  respecting the documented 64-byte managed `memoryRead` limit.
- Preserve unknown optional fields and distinguish `UNSUPPORTED`,
  `UNAVAILABLE`, `STALE_GENERATION`, `CORRUPT`, `DIVERGED`, and
  `RESOURCE_LIMIT`; do not infer support from human-readable messages.
- Treat the DAP and compact headless service as independent sessions. Do not
  start a second process to add a timeline panel to an existing session.
- Do not parse CLI output or import private engine/storage modules into a
  plugin. The command-line interface is not the editor API.
- Do not claim native attach, native replay, remote sessions, trace branching,
  or history panels in a host integration until the selected process transport
  both advertises and implements the required operation end to end.

See the [plugin-author guide](../spec/plugin-integration.md) for launch
configuration examples and the current attach limitation.
