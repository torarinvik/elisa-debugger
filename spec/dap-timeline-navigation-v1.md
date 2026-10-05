# DAP timeline navigation, version 1

The DAP adapter exposes a versioned extension for editor timeline panels and
other hosts that need to inspect retained history or seek to a specific event.
It uses the same DAP process and managed session as ordinary stepping; hosts
must not start a second adapter process for timeline navigation.

## Negotiation

The DAP `initialize` response advertises:

```json
{
  "supportsElisaTimelineNavigation": true,
  "elisaTimelineNavigationVersion": 1
}
```

Clients must check both fields before sending the custom requests below. The
extension does not replace DAP `stepBack` or `reverseContinue`; those remain
available according to the standard capability response.

## Read the timeline

Send `elisa/getTimeline` with no `arguments`:

```json
{"seq":31,"type":"request","command":"elisa/getTimeline"}
```

A successful response body has this shape:

```json
{
  "version": 1,
  "stopGeneration": 2,
  "currentEvent": 1,
  "hasRetainedRange": true,
  "retainedFirst": 0,
  "retainedLast": 12,
  "hasExactRange": true,
  "exactFirst": 0,
  "exactLast": 12,
  "canSeek": true,
  "canReverse": true
}
```

`stopGeneration` identifies the snapshot used for optimistic concurrency.
Event indexes and generations are nonnegative JSON integers. `currentEvent`
is the current managed history position. `retainedFirst` and `retainedLast`
bound the history the adapter still retains; `hasRetainedRange` indicates
whether that range is available. When `hasExactRange` is true, `exactFirst`
and `exactLast` identify the range whose execution state and replay side state
are exact. When a range is unavailable, its numeric bounds are zero and its
availability flag (`hasRetainedRange` or `hasExactRange`) is false. `canSeek`
and `canReverse` report current eligibility; a client should use these fields
to disable controls instead of guessing from the range endpoints.

The request requires an inspectable stopped session with a history provider.
The response is a snapshot. Query again after a stop event or a successful
navigation request to refresh the current event and eligibility.

## Seek to an event

Send `elisa/seek` with the target index in `arguments.eventIndex` and the
generation from the timeline snapshot in `arguments.expectedStopGeneration`:

```json
{"seq":32,"type":"request","command":"elisa/seek","arguments":{"eventIndex":4,"expectedStopGeneration":2}}
```

`eventIndex` and `expectedStopGeneration` must be unsigned JSON integers, and
the event must identify an exact retained position. Duplicate `arguments`,
`eventIndex`, or `expectedStopGeneration` fields, a missing operand, a stale
generation, or a value outside the managed seek range are rejected. The
generation check prevents a delayed timeline control from moving a session
after newer execution state has replaced the snapshot the control came from. A
stale generation returns the DAP failure message `timeline snapshot is stale;
query the timeline again`. A failed seek leaves the current position
unchanged. A successful seek returns a normal DAP success response and a
`stopped` event with reason `step`; hosts should refresh `stackTrace`,
`scopes`, and `variables`, because their handles are bound to the stop
generation.

Version 1 currently routes to the managed EDIR service, whose seek API caps
event indexes at 64. This is an implementation limit, not a promise that the
retained trace always reaches event 64. The reported bounds and eligibility
remain authoritative for the active session. A future expansion of that
engine limit must update the wire contract if JSON integer precision becomes
relevant to supported hosts.

## Editor integration

VS Code extensions can use `DebugSession.customRequest("elisa/getTimeline")`
and the `elisa/seek` custom request after checking initialize. A seek must
include both `eventIndex` and `expectedStopGeneration`, with the latter set to
the returned `timeline.stopGeneration`. A timeline slider should clamp its
range to the reported exact bounds, disable navigation when `canSeek` is false,
and refresh inspection after the resulting stopped event.

JetBrains bridges and other DAP hosts should send the same custom commands
through their DAP client's custom-request facility. If a host route filters
unknown DAP commands, it needs a bridge that preserves these requests on the
existing adapter connection. This repository supplies the adapter contract;
it does not ship a VS Code extension, JetBrains plugin, or timeline UI.
