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

The current bounded bootstrap server accepts the same method vocabulary in a
compact request such as `{ "method": "launch", "id": 7,
"expectedStopGeneration": 1 }`; it correlates the numeric request ID as a
decimal string in the response. Full envelopes and parameter decoding are
added behind this stable framing without changing session-generation rules.

## Lifecycle

The client sends `initialize` with `protocolMajor`, `protocolMinor`, `client`,
and requested extensions. The server returns its versions, `server`, supported
engines, target/platform support, and feature capabilities. An incompatible
major version is an explicit error. Minor versions are additive only.

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

Large results are paginated with an opaque `next` token. Requests that may run
longer than a client timeout emit `progress` events and honor `cancel` by
request ID. Mutation requests declare whether retrying the same ID is safe.

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
