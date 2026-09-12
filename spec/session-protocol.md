# Elisa debugger session protocol v1

This is the editor-neutral integration boundary for the debugger. The server is
implemented in Elisa and is usable by VS Code, JetBrains integrations, test
runners, CI systems, and custom clients without importing debugger internals.

## Transport

The default adapter runs as a child process using framed UTF-8 JSON messages on
standard input and standard output. Each frame is one decimal byte length, a
single space, and exactly that many UTF-8 bytes followed by `\n`. Standard
output contains protocol frames only. Diagnostics and target output use
standard error or explicit protocol events.

The same messages may be carried over a local socket or an authenticated remote
transport. The transport does not change message semantics.

## Envelope

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

After the session is stopped, `stack` returns the current managed frame,
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

`discover` reports the features this endpoint can provide. Threads, expression
evaluation, memory reads, source-breakpoint operands, and trace artifact
transfer are not wired to this process transport yet. Their method names remain
reserved for compatible future protocol versions and return an explicit
unsupported or unavailable result. The typed in-process service exposes a
broader surface than this process endpoint; clients should not infer wire
support from an in-process module or from the method vocabulary alone.

## Lifecycle

The client sends `initialize` with `protocolMajor`, `protocolMinor`, `client`,
and requested extensions. The server returns its versions, `server`, supported
engines, target/platform support, and feature capabilities. An incompatible
major version is an explicit error. Minor versions are additive only.

The Elisa implementation also exposes a typed discovery document containing
product version, trace schema, installation health, resource limits, and the
complete capability set. Mutating clients retain the ownership token returned
by session creation; requests without that token are rejected before target
state is touched.

The client then sends `createSession` or `openTrace`, followed by `launch`,
`attach`, or `replay`. State-changing requests carry `session`, `requestId`,
and optionally `expectedStopGeneration`. A stale generation returns
`STALE_GENERATION`; the server never applies a request against a different
stop.

Every stop event includes `stopGeneration`, `position`, `reason`, `engine`,
`history`, and the complete current capability set. A seek/restore event is
not observable as a ready stop until state validation succeeds.

## Initial method families

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

The typed service paginates large results with opaque `next` tokens. The
current compact headless local-inspection response instead uses the decimal
offset described above. Typed operations that may run longer than a client
timeout emit `progress` events and honor `cancel` by request ID. Mutation
requests declare whether retrying the same ID is safe.

## Timeline, history, and branch extensions

The managed session service uses the reserved `checkpoint`, `branch`,
`compare`, `trace.verify`, and `trace.export` methods for advanced clients.
Requests carry structured fields only:

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

The DAP adapter maps this contract to ordinary editor debugging. Timeline,
history, provenance, and branch features use namespaced extensions while
retaining the same session IDs, stop generations, values, and errors.
