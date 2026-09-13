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
result payloads are not wired to this compact transport, including source
breakpoints, memory reads, checkpoints, branches, trace verification, trace
export, and historical queries. Threads, frames, scopes, and locals are
available through the managed inspection surface. Expression evaluation and
trace artifact transfer are not wired to this process. Clients must honor the
process's discovery result; method names in the typed in-process API or the
protocol vocabulary alone do not imply wire support.

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
standalone process implements protocol-major/minor negotiation but does not
currently implement the `createSession` token exchange or enforce ownership
tokens on its compact requests.

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
`continue`, `step`, `reverseStep`, `seek`, `threads`, `stack`, `scopes`,
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

## Target timeline, history, and branch extensions

These method shapes describe the intended advanced client contract. The
standalone process does not currently serialize their result payloads or expose
them as supported wire methods. Where in-process Elisa modules implement these
operations, they remain subject to the capability set reported by the active
provider. Requests carry structured fields only:

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
