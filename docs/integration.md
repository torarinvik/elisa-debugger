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
table and exact function-name breakpoints against EDIR function descriptors,
one `main` thread, stack and locals inspection, bounded local paging,
`readMemory`, continue, pause, `next`, `stepIn`, `stepOut`, `stepBack`,
`reverseContinue`, disconnect, and terminate. Source paths must match the
artifact's logical paths. Set the adapter launch argument `sourcePathRoot` to
the workspace root when the editor sends absolute paths; the adapter removes
that exact root prefix before matching. It does not use basename or suffix
matching. Source breakpoints support bounded arithmetic expression conditions,
positive numeric hit conditions, and `logMessage` logpoints with `{expression}`
interpolation. Conditions and hit conditions are applied before a logpoint
message is emitted.

An `setFunctionBreakpoints` request replaces the complete function breakpoint set.
Names match exactly and apply to every same-named function descriptor, including
overloads. A name absent from the loaded artifact is returned unverified.
Function breakpoints accept the same bounded expression conditions and positive
numeric hit conditions as source breakpoints; function log messages are not supported.
The initialize response advertises `supportsFunctionBreakpoints`.

Each logpoint emits a DAP `output` event without stopping. A message is limited
to 256 decoded bytes, and a breakpoint replacement accepts
at most 8192 combined decoded condition and log-message bytes. Each continue
request buffers at most 8192 bytes of log output. If a template expression
cannot be evaluated or the output bound is reached, continue stops with an
error instead of silently discarding the log. Expression evaluation is bounded
and side-effect free.
Data breakpoints, variable assignment, restart, and disassembly remain
unavailable. The initialize response advertises the relevant DAP capabilities;
clients should honor that response.

The initialize response also advertises the optional
`supportsElisaHostEffects` version 1 extension. It yields clock, random, and
console-output requests through the response body of `continue`, `next`,
`stepIn`, or `stepOut`. A host must inspect those responses and send the
correlated `elisa/provideHostEffect` reply through the same session. The
[versioned wire contract](../spec/dap-host-effects-v1.md) describes the
message format and host integration path. If initialize also advertises
`supportsElisaHostEffectCancellation` version 1, a host can cancel a timed-out
provider request on that same session and retry execution from the unchanged
effect instruction. This repository provides the DAP backend; it does not
include a VS Code or JetBrains plugin or a concrete host-effect provider.

The initialize response also advertises
`supportsElisaTimelineNavigation` version 1. Hosts can call
`elisa/getTimeline` for retained/exact bounds and eligibility, then
`elisa/seek` on the same adapter connection to jump to an event. Include the
snapshot's `stopGeneration` with each seek so stale slider requests are
rejected. A successful seek emits a stopped event; refresh stack and variable
handles afterward. The
[timeline navigation contract](../spec/dap-timeline-navigation-v1.md) includes
request shapes, the current managed event limit, and guidance for VS Code,
JetBrains, and other DAP clients. Its companion
[JSON Schema](../schemas/dap-timeline-navigation-v1.schema.json) can validate
the custom request and response payloads in plugin tests.

The adapter also advertises `supportsElisaTraceFiles` version 1. Stopped
sessions can save exact managed traces with `elisa/saveTrace` and reopen a
compatible trace at a specific event with `elisa/openTrace`. Opening requires
the current timeline generation and the same build and EDIR image; after a
successful open, refresh timeline bounds and every stop-scoped inspection
handle. See the [trace file contract](../spec/dap-trace-files-v1.md) and its
[JSON Schema](../schemas/dap-trace-files-v1.schema.json) for request,
compatibility, and failure behavior.

For managed EDIR programs that read virtual files, check
`supportsElisaVirtualFiles` and `elisaVirtualFilesVersion` in `initialize`,
then provide immutable byte snapshots in the launch request. Each snapshot
maps an explicit guest handle to a logical path and hex-encoded bytes; version
1 supports read-only contents. The
[virtual-file contract](../spec/dap-virtual-files-v1.md) defines bounds,
handle ordering, and replay behavior.

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
`arguments.program`, `setBreakpoints`, `evaluate`, `pause`, `continue`, `step`,
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

For read-only expression evaluation, send `evaluate` with a bounded
`arguments.expression` and an optional zero-based `arguments.frameIndex`.
The evaluator reads the selected stopped frame and current globals without
changing execution state. Successful signed 64-bit results are decimal
strings. Send `expectedStopGeneration` when the client has a current stop
snapshot so an evaluation cannot silently use a newer state. Validate the
request and result with the
[`evaluate` schema](../schemas/session-protocol-v1.evaluate.schema.json).

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
This endpoint does not implement attach or trace artifact transfer.
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
| VS Code | DAP initialize/launch, breakpoints, inspection, execution requests, lifecycle, and optional timeline and trace-file custom requests | Register a debugger type in the consuming plugin, point it at the DAP executable, and use `program` plus optional `sourcePathRoot` in launch configuration. Timeline and trace-file actions use `DebugSession.customRequest` on the existing session. |
| JetBrains | The same DAP operations where the selected IDE/plugin route can launch a DAP adapter, including timeline and trace-file custom requests when its bridge supports them | No JetBrains plugin or platform-version qualification is included. A host-specific bridge translates UI/session requests and renders responses; the host manages local trace paths and selects a build-compatible launch before reopening. |
| Other editors and tools | DAP for standard debugger UI and optional timeline/trace-file custom requests; compact JSON for custom managed lifecycle/inspection clients | Launch the child process directly, keep protocol output separate from logs, preserve exact protocol IDs, and report unavailable operations from endpoint behavior rather than parsing messages. |

For a DAP host, the mapping is direct: source-line breakpoints use
`setBreakpoints`; call-stack and local panes use `threads`, `stackTrace`,
`scopes`, and `variables`; controls use the supported execution requests; the
host displays capability fields and protocol errors. A timeline panel checks
`supportsElisaTimelineNavigation`, queries `elisa/getTimeline`, and seeks with
`elisa/seek` on the same DAP connection; it refreshes inspection after the
stopped event. When `supportsElisaTraceFiles` is present, the host can call
`elisa/saveTrace` while stopped and reopen a compatible artifact with
`elisa/openTrace`, supplying the timeline snapshot's stop generation. The
loaded EDIR image must match the artifact, and the host refreshes timeline and
inspection after the resulting stopped event. DAP carries a local path rather
than trace bytes, so the plugin owns artifact selection and retention. For a compact JSON host,
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
- Treat the DAP and compact headless service as independent sessions. A DAP
  timeline panel must use the timeline custom requests on its existing adapter
  connection instead of starting another process.
- Do not parse CLI output or import private engine/storage modules into a
  plugin. The command-line interface is not the editor API.
- Do not claim native attach, native replay, remote sessions, trace branching,
  or history panels in a host integration until the selected process transport
  both advertises and implements the required operation end to end.

See the [plugin-author guide](../spec/plugin-integration.md) for launch
configuration examples and the current attach limitation.
