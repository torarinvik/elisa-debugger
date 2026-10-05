# DAP trace files, version 1

The DAP adapter exposes versioned custom requests for saving the current exact
managed trace and reopening a compatible trace into the current session. Both
requests use the existing adapter process and the loaded EDIR program. Hosts
must not start a second adapter to access the same session.

The [JSON Schema](../schemas/dap-trace-files-v1.schema.json) describes request
and response envelopes. The initialize response advertises:

```json
{
  "supportsElisaTraceFiles": true,
  "elisaTraceFilesVersion": 1
}
```

Hosts must check both fields before sending these requests. Trace paths are
local filesystem paths resolved by the adapter process. They are JSON strings;
the adapter decodes JSON escapes, preserves spaces, and rejects empty, invalid,
or over-capacity paths.

## Save a trace

Send `elisa/saveTrace` with the destination path:

```json
{"seq":41,"type":"request","command":"elisa/saveTrace","arguments":{"path":"build/session.trace"}}
```

The session must be stopped and have no active host-effect request. The adapter
exports through the managed trace service, which validates exactness before
writing a complete trace artifact and atomically replacing the destination.
A successful response has `body: {"accepted":true}`. A failed request leaves
the existing destination unchanged if writing did not complete atomically.

## Open a trace

Send `elisa/openTrace` with the path, target event, and stop generation from a
recent `elisa/getTimeline` snapshot:

```json
{"seq":42,"type":"request","command":"elisa/openTrace","arguments":{"path":"build/session.trace","eventIndex":0,"expectedStopGeneration":7}}
```

The target and generation must be nonnegative JSON integers. Duplicate,
missing, malformed, or overflowing fields are rejected. The generation must
still match the stopped session. Opening is rejected while the adapter has a
pending host-effect provider request or while the session is running.

The artifact must match both the build identity and the complete fingerprint
of the EDIR image currently loaded in this DAP session. The adapter does not
compile source or choose another executable based on the trace. It validates
the whole file, replays and checks the saved bounded history in temporary
state, positions at `eventIndex`, then replaces the live session only after
all checks succeed. A rejected open leaves the running session unchanged.

A successful response has `body: {"accepted":true}` and is followed by a DAP
`stopped` event with reason `step`. The stop generation advances. Hosts should
query `elisa/getTimeline` and refresh `stackTrace`, `scopes`, and `variables`
because inspection handles belong to the previous generation. The reopened
history remains available for forward and reverse navigation within the
reported bounds after the artifact reader is released.

Trace files are integrity-checked, not authenticated. Hosts should treat a
trace as untrusted input and present adapter failures clearly. The adapter
reports incompatible images, corrupt files, unsupported limits, stale
generations, and invalid session state as failed DAP responses. This extension
does not transfer artifact bytes over DAP; host plugins choose how to create,
copy, and retain the path.

## Editor integration

VS Code extensions can use `DebugSession.customRequest("elisa/saveTrace", …)`
and `DebugSession.customRequest("elisa/openTrace", …)`. JetBrains bridges and
other DAP hosts can send the same custom requests over the existing adapter
connection. A host should save the artifact URI/path with its own session
metadata, ask the user to select a compatible launch when reopening, and use
the timeline response as the authoritative range for navigation.
