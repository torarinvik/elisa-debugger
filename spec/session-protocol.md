# Elisa debugger session protocol v1 (target contract)

This document describes the editor-neutral target contract for the debugger.
The Elisa source includes typed protocol models and encoders, while the
standalone process currently implements only the compact wire subset described
in “Current headless process surface.” The other sections specify the intended
v1 contract; they are not a claim that every method, event, or transport is
already available end to end. Clients must use `discover` and the current
support documentation to determine what the running endpoint can do.

## Transport

The default adapter runs as a child process using framed UTF-8 JSON messages on
standard input and standard output. Each frame is one decimal byte length, a
single space, and exactly that many UTF-8 bytes followed by `\n`. Standard
output contains protocol frames only. Diagnostics and target output use
standard error or explicit protocol events.

The framing is designed to be transport-independent. Local-socket and
authenticated remote adapters are not currently shipped.

## Target v1 envelope

This envelope is the target typed-service schema. The standalone process uses
the compact root-object schema documented below instead.

Requests have `{ "kind": "request", "id": "...", "method": "...", "params": {} }`.
Responses have `{ "kind": "response", "id": "...", "ok": true, "result": {} }` or
`{ "kind": "response", "id": "...", "ok": false, "error": { "code": "...", "message": "..." } }`.
Events have `{ "kind": "event", "event": "...", "session": "...", "body": {} }`.

IDs and event ordinals are strings so clients cannot lose precision in a
JavaScript number. Clients must preserve unknown optional fields and must not
parse human-readable messages to determine behavior.

The executable currently accepts a compact root-object request such as
`{ "method": "launch", "id": 7,
"arguments": { "program": "build/app.edir" } }`. Request IDs may be unsigned
decimal JSON numbers or decimal strings; responses encode them as decimal
strings. The process currently owns one managed session per invocation.

## Current headless process surface

The current standalone Elisa server supports managed EDIR launch, session
control, and basic inspection over the compact framing. `launch` requires
`arguments.program`, a NUL-free UTF-8 filesystem path to a bounded EDIR file.
The server reads and verifies that artifact before replacing its initial image
or transitioning the session to running. `pause`, `continue`, `step`,
`reverseStep`, and `seek` operate through the same managed replay engine as the
in-process service. Mutating and inspection requests may include
`expectedStopGeneration`; a stale value fails without applying the request.

After launch, `threads` returns the process's single logical `main` thread.
Once the session is stopped, `stack` returns the current managed frame,
`scopes` returns the locals scope and its generation-bound
`variablesReference`, and `variables` returns typed local values. A variables
request places that reference inside `arguments`. Integer values are decimal
strings so JavaScript and other clients do not lose signed
64-bit precision. Uninitialized locals have `availability: "uninitialized"`
and `value: null`. A `variables` request must return the reference from the
current `scopes` response. Top-level `pageSize` and `pageStart` operands page
the local list; `pageSize` is bounded to 256 (zero selects the local default),
and the response's decimal-string `next` offset can be sent back as
`pageStart`. Local pages are additionally bounded by the managed inspection
capacity.

`discover.result.features` includes a boolean for every capability in the
shared `CapabilitySet`. The process clears features whose request operands or
result payloads are not wired to this compact transport, including trace
export and historical queries. Managed memory reads, source breakpoints, and
read-only trace verification are supported through bounded payloads. Managed
EDIR source breakpoints and frame-aware expression evaluation are supported
through bounded payloads. Managed source breakpoints use the bounded
`setBreakpoints` payload below. Threads, frames, scopes, and locals are
available through the managed inspection surface. Trace artifact transfer is
not wired to this process. Clients must honor the process's discovery result;
method names in the typed in-process API or the protocol vocabulary alone do
not imply wire support.

The compact `discover` request and response are described by
[`schemas/session-protocol-v1.discover.schema.json`](../schemas/session-protocol-v1.discover.schema.json).
The request may omit `id`; in that case the process returns response ID `"1"`.
An explicit positive unsigned 64-bit ID may be a JSON integer or decimal
string, and the response always represents it as a decimal string. The schema
requires every currently published feature flag while allowing additional
fields so clients can preserve additive protocol extensions.

Example payloads (each is one frame body; framing adds the decimal UTF-8 byte
length, one space, and a newline):

```json
{"method":"discover","id":7}
```

```json
{"kind":"response","id":"7","ok":true,"result":{"protocolMajor":1,"protocolMinor":0,"server":"elisa-debugger","productVersion":"0.1.0","engines":["managed"],"traceSchema":1,"features":{"sourceBreakpoints":true,"functionBreakpoints":false,"dataBreakpoints":false,"typedValues":true,"expressionEvaluation":true,"reverseExecution":true,"timeline":true,"checkpoints":true,"branches":true,"concurrencyGraph":false,"provenance":false,"remoteTransport":false,"traceVerification":true,"memoryRead":true,"historicalQueries":false,"traceExport":false,"scheduleExploration":false,"nativeAttach":false,"postmortemInspection":false},"installationHealthy":true}}
```

`expressionEvaluation: true` advertises the managed `evaluate` operation over
both the typed service and compact JSON process. Send a non-empty bounded
`arguments.expression` string and optionally select a zero-based stopped frame
with `arguments.frameIndex` (omitted selects frame zero). The endpoint decodes
JSON escapes and applies the same side-effect-free, 256-byte expression grammar
as DAP. A request may carry `expectedStopGeneration`; a stale value is rejected
before evaluation. Successful results include the current stop generation and
an `evaluation` object with `type: "i64"`, the exact signed result as a decimal
string, and the number of consumed expression bytes. Errors preserve the
normal protocol error code, including `INVALID_ARGUMENT`, `UNAVAILABLE`, and
`STALE_GENERATION`. The
[`evaluate` schema](../schemas/session-protocol-v1.evaluate.schema.json)
defines the compact request and response.

```json
{"method":"evaluate","id":20,"expectedStopGeneration":"6","arguments":{"expression":"local0 + global0","frameIndex":0}}
```

```json
{"kind":"response","id":"20","ok":true,"result":{"accepted":true,"stopGeneration":"6","evaluation":{"type":"i64","value":"46","consumed":16}}}
```

The DAP `evaluate` request continues to accept the standard `expression` and
generation-bound `frameId` operands.

After launching a verified artifact, a generic editor bridge can replace the
breakpoints for one EDIR source file by its exact normalized logical path.
Each requested line is a positive JSON integer; at most 32 lines may be sent
per source. Absolute editor paths should be mapped to the relative logical
path stored in the artifact before sending the request. The operation returns
the manager-assigned breakpoint IDs and whether each line resolves to an
executable instruction. Unknown source paths fail with `INVALID_ARGUMENT`.
The complete request and success result are validated by the
[`setBreakpoints` schema](../schemas/session-protocol-v1.set-breakpoints.schema.json).

```json
{"method":"setBreakpoints","id":8,"arguments":{"source":{"path":"main.elisa"},"breakpoints":[{"line":42},{"line":99}]}}
```

```json
{"kind":"response","id":"8","ok":true,"result":{"accepted":true,"stopGeneration":"0","breakpoints":[{"id":"1","line":42,"verified":true},{"id":"2","line":99,"verified":false}]}}
```

## Target lifecycle

The client sends `initialize` with `protocolMajor`, `protocolMinor`, `client`,
and requested extensions. The server returns its versions, `server`, supported
engines, target/platform support, and feature capabilities. An incompatible
major version is an explicit error. Minor versions are additive only.

The current headless process implements a narrower version handshake. Send
`{"method":"initialize","id":1,"protocolMajor":1,"protocolMinor":0}`
before using the endpoint. `discover` is the only session-service method that
may be called before a compatible `initialize`; all other methods return
`INITIALIZE_REQUIRED` until negotiation succeeds. Both version fields are required canonical unsigned
JSON integers in the u32 range; aliases, decimal strings, duplicates, and
nested lookalikes are rejected. The response reports the selected major and
minor, server name, product version, and installation health. A major mismatch
returns `INCOMPATIBLE_VERSION` with the requested and supported versions and
does not change session state. A newer requested minor negotiates down to the
highest minor supported by the server; the current process supports `1.0`.
`discover` remains safe before initialization and supplies the endpoint's
current capabilities. Initialization does not create a session or ownership
token, and the compact process handshake does not yet consume client identity
or extension requests. The request/response shapes are published in
[`schemas/session-protocol-v1.initialize.schema.json`](../schemas/session-protocol-v1.initialize.schema.json).

The Elisa source defines a typed discovery document containing product
version, trace schema, installation health, resource limits, and capabilities.
It also defines ownership-token validation for typed session requests. The
standalone process supports an opt-in `createSession` ownership exchange. The
successful response contains the process session ID and an owner token. Every
later request must carry the matching `sessionId`; state-changing requests
must also carry the matching `ownerToken`. An absent or mismatched token
returns `PERMISSION_DENIED` before dispatch, so a second client cannot control
a session accidentally. The token is scoped to the adapter process and is not
a replacement for an authenticated remote tunnel. Older compact clients may
continue to use the legacy one-client flow by launching without
`createSession`.

The request and result shape is published in
[`schemas/session-protocol-v1.create-session.schema.json`](../schemas/session-protocol-v1.create-session.schema.json).

The client then sends `createSession` or `openTrace`, followed by `launch`,
`attach`, or `replay`. State-changing requests carry `session`, `requestId`,
and optionally `expectedStopGeneration`. A stale generation returns
`STALE_GENERATION`; the server never applies a request against a different
stop.

Every stop event includes `stopGeneration`, `position`, `reason`, `engine`,
`history`, and the complete current capability set. A seek/restore event is
not observable as a ready stop until state validation succeeds.

## Target method families

`discover`, `createSession`, `launch`, `attach`, `openTrace`, `pause`,
`continue`, `step`, `reverseStep`, `seek`, `timeline`, `threads`, `stack`, `scopes`,
`variables`, `evaluate`, `setBreakpoints`, `setDataBreakpoints`,
`checkpoint`, `branch`, `compare`, `trace.verify`, `trace.export`, `detach`,
`terminate`, and `close` are reserved method names. Unsupported operations
return `UNSUPPORTED` with a capability explanation.

`seek` carries a bounded `targetEvent` ordinal and the current
`expectedStopGeneration`. The server validates both before changing the
selected position; a successful seek returns a new stop generation. The
request is safe to retry only with the same request ID and target ordinal.

The target typed service contract paginates large results with opaque `next`
tokens. The current compact headless local-inspection response instead uses the
decimal offset described above. The Elisa source defines progress and
cancellation models, but the standalone endpoint does not currently emit
progress events or route cancellation by request ID. Mutation retry rules in
this contract are not yet enforced by the compact endpoint.

The native snapshot JSON encoders define bounded `stack` and `values` result
objects for editor-neutral consumers. The stack result preserves thread and
invocation identities, parent links, function/task/source IDs, raw source
coordinates, local counts, and a numeric next-frame offset. The values result
preserves binding/scope/type IDs, semantic kind and availability state,
storage kind/location, declared size, lowercase hexadecimal bytes, and a
canonical scalar display when the value is a supported integer or boolean.
All 64-bit identities and storage coordinates are decimal strings. Composite,
floating-point, text, reference, and opaque values keep their raw bytes and
return `display: null` with an explicit `displayStatus`; unavailable values do
not expose bytes. Clients should retain opaque IDs and use the page's
`stopGeneration` on every follow-up request.

These result shapes are validated by the
[`native stack schema`](../schemas/session-protocol-v1.native-stack.schema.json)
and [`native values schema`](../schemas/session-protocol-v1.native-values.schema.json).
The following fixtures show the current typed encoder output:

```json
{"kind":"response","id":"42","ok":true,"result":{"accepted":true,"stopGeneration":"9","stack":{"threadId":"1301","totalFrames":2,"startFrame":0,"frames":[{"index":0,"invocationId":"1401","parentInvocationId":null,"functionId":"1501","taskId":"1601","sourceId":"1701","line":29,"column":6,"localCount":2},{"index":1,"invocationId":"1402","parentInvocationId":"1401","functionId":"1502","taskId":"1601","sourceId":"1701","line":29,"column":6,"localCount":0}],"nextFrame":null,"complete":true}}}
```

```json
{"kind":"response","id":"42","ok":true,"result":{"accepted":true,"stopGeneration":"9","frame":{"index":0,"invocationId":"1401"},"totalBindings":2,"startBinding":0,"values":[{"bindingId":"1801","scopeId":"1901","typeId":"2001","name":"binding-1801","kind":"signed","state":"available","storageKind":"stackSlot","storageLocation":"-8","byteSize":"1","bytes":"d6","display":"-42","displayStatus":"available"},{"bindingId":"1802","scopeId":"1901","typeId":"2001","name":"binding-1802","kind":"signed","state":"optimizedAway","storageKind":"unknown","storageLocation":"0","byteSize":"4","bytes":null,"display":null,"displayStatus":"unavailable"}],"complete":true,"nextBinding":null}}
```

The standalone process currently routes managed inspection only. These native
result encoders are reusable Elisa API functions and do not imply that the
process has launched a native target or advertises native stack/value support.
The server must keep those capabilities disabled until it dispatches the
native agent session and emits these result objects end to end.

## Target timeline, history, and branch extensions

These method shapes describe the intended advanced client contract. The
standalone process serializes the bounded `timeline` snapshot below; the other
advanced result payloads remain in-process typed APIs until their wire shapes
are implemented. Where in-process Elisa modules implement these operations,
they remain subject to the capability set reported by the active provider.
Requests carry structured fields only:

The `timeline` method is the first supported namespaced-free history extension
on the compact headless endpoint. It is a read-only snapshot request and is
available when the provider advertises retained history and the session is
stopped or replaying. Its result contains the current event and branch,
retained and exact history bounds, bounded bookmark metadata, and the most
recent checkpoint event and state digest when one exists. Event, branch,
bookmark, and checkpoint identities are decimal JSON strings. Clients use the
returned `stopGeneration` with `seek`, `reverseStep`, `reverseStepOver`, or
`reverseStepOut`; a stale generation is rejected before the engine moves.

For example, a successful request has this shape:

```json
{"kind":"response","id":"7","ok":true,"result":{"accepted":true,"stopGeneration":"2","timeline":{"position":{"event":"1","branch":"0"},"history":{"retained":{"available":true,"firstEvent":"0","lastEvent":"1"},"exact":{"available":true,"firstEvent":"0","lastEvent":"1"}},"bookmarks":[],"checkpoint":{"available":true,"event":"1","stateHash":"0"}}}}
```

Validate requests and responses against the
[`timeline` JSON schema](../schemas/session-protocol-v1.timeline.schema.json).

The `checkpoint` method captures a validated complete managed machine state
at the current stop and returns its event ordinal and state digest. The compact
wire result deliberately exposes metadata only; clients that need to persist
the opaque checkpoint bytes must use a typed service or a trace transfer
operation. The `branch` method creates an immutable child lineage at the current
verified position and returns its branch ID. Both methods are generation and
ownership aware and are available only when discovery advertises the
corresponding capability. Validate their shapes against the [`checkpoint`
schema](../schemas/session-protocol-v1.checkpoint.schema.json) and [`branch`
schema](../schemas/session-protocol-v1.branch.schema.json).

The `memory` method reads up to 64 bytes from the managed EDIR logical heap.
Its `arguments` object requires an `address` from 0 through 512 and a numeric
`length` from 0 through 64. Addresses may be decimal JSON strings so clients
can use one lossless representation for all protocol identities. The server
checks allocation and initialization state at the current stop before
returning bytes as lowercase hexadecimal in the bounded result object. An
unallocated or uninitialized range returns `UNAVAILABLE` without exposing
runtime pointers. Validate requests and successful responses against the
[`memory` JSON schema](../schemas/session-protocol-v1.memory.schema.json).

The compact `trace.verify` method is a read-only snapshot over the current
managed recording. It captures the bounded root event prefix, validates its
checksummed bundle, and returns `state` (`exact`, `partial`, `unavailable`,
`corrupt`, or `empty`), decimal-string `verifiedChunks` and `verifiedEvent`
counts, and a `replayable` flag. It never upgrades an incomplete capture to
exact and does not transfer trace bytes. Validate its request and successful
response against the [`trace.verify` JSON schema](../schemas/session-protocol-v1.trace-verify.schema.json).

For example, an exact response is:

```json
{"kind":"response","id":"9","ok":true,"result":{"accepted":true,"stopGeneration":"2","verification":{"state":"exact","verifiedChunks":"1","verifiedEvent":"7","replayable":true}}}
```

The typed managed service and compact endpoint expose checkpoint creation and
reverse navigation. The compact endpoint returns checkpoint metadata without
transferring opaque payloads; its timeline snapshot reports the same metadata.
Branch creation likewise returns lineage identity without transferring
unbounded event history. Unsupported
providers return the normal `UNSUPPORTED` or `UNAVAILABLE` error and never
manufacture bounds.

- `seek` uses `targetEvent` and `expectedStopGeneration`.
- `checkpoint` returns a checkpoint identity and its state digest.
- `branch` returns parent branch, fork event, replay policy, and intervention
  validation status.
- `compare` returns shared-prefix length, first divergence, and whether an
  alignment is exact or heuristic.
- `trace.verify` returns health state and the last verified event.
- `trace.export` returns an artifact identity, replayability, and dependency
  closure status.

Historical query requests use `firstEvent`, `lastEvent`, `maxResults`, and
`maxSteps`. Results include `complete`, `cancelled`, `scannedEvents`, and an
opaque continuation token. A value result always includes its availability
state; `absent`, `unavailable`, `optimizedAway`, `uninitialized`, `invalid`,
and `redacted` are distinct states.

Branch outputs remain virtual until a client explicitly requests an external
effect under a policy granting that permission. Reusing a parent input after a
branch request mismatch is a protocol error and reports the first divergence.

## Compatibility requirements

The protocol specifies source lines as one-based, columns as zero-based UTF-16
code units for editor compatibility, byte offsets as zero-based, and ranges as
start-inclusive/end-exclusive. Source and build artifacts are identified by
content IDs, not local paths. Paths are metadata used only after explicit
mapping.

The DAP adapter maps supported operations to ordinary editor debugging.
Timeline, history, provenance, and branch features are intended to use
namespaced extensions while retaining the same session IDs, stop generations,
values, and errors once their wire support is implemented.
