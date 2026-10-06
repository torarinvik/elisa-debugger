#!/bin/sh
set -eu

cli=${1:?expected CLI path}
server=${2:?expected DAP path}
fixture=${3:?expected EDIR image}
creator=${4:?expected divergence fixture creator}
bad=build/replay-divergence.eltr
good=build/dap-trace-effects.eltr
output=build/replay-divergence-dap.output
component=machine-state
event=58
if test "${5:-events}" = resources; then
    bad=build/resource-divergence.eltr
    good=build/dap-file-mutations.eltr
    output=build/resource-divergence-dap.output
    component=resource-operation
    event=0
    "$creator" resources
else
    "$creator"
fi

cli_output=$(printf 'launch %s\npause\nopenTrace 0 %s\nstack\ntimeline\nopenTrace 0 %s\ncontinue\nstack\n' "$fixture" "$bad" "$good" | "$cli")
printf '%s\n' "$cli_output" | grep -F "divergence version=1 component=$component event=$event lastVerified=$event recording=1 branch=0" > /dev/null
printf '%s\n' "$cli_output" | grep -F 'frame id=1 event=0 instruction=0' > /dev/null
printf '%s\n' "$cli_output" | grep -F 'result=-1 returnDepth=0' > /dev/null
test "$(printf '%s\n' "$cli_output" | grep -c '^error code=')" -eq 1

frame() {
    payload=$1
    length=$(printf %s "$payload" | wc -c | tr -d ' ')
    printf 'Content-Length: %s\r\n\r\n%s' "$length" "$payload"
}
{
    frame '{"seq":1,"type":"request","command":"initialize"}'
    frame "{\"seq\":2,\"type\":\"request\",\"command\":\"launch\",\"arguments\":{\"program\":\"$fixture\"}}"
    frame '{"seq":3,"type":"request","command":"configurationDone"}'
    frame '{"seq":4,"type":"request","command":"pause"}'
    frame "{\"seq\":5,\"type\":\"request\",\"command\":\"elisa/openTrace\",\"arguments\":{\"path\":\"$bad\",\"eventIndex\":0,\"expectedStopGeneration\":1}}"
    frame '{"seq":6,"type":"request","command":"elisa/getTimeline"}'
    frame "{\"seq\":7,\"type\":\"request\",\"command\":\"elisa/openTrace\",\"arguments\":{\"path\":\"$good\",\"eventIndex\":0,\"expectedStopGeneration\":1}}"
    frame '{"seq":8,"type":"request","command":"continue"}'
} | "$server" > "$output"

# Transport verification only: all lengths and JSON messages must remain
# valid even for diagnostics containing full-width identities and hashes.
python3 - "$output" "$component" "$event" <<'PY'
import json
import pathlib
import sys

data = pathlib.Path(sys.argv[1]).read_bytes()
messages = []
while data:
    header, data = data.split(b'\r\n\r\n', 1)
    assert header.startswith(b'Content-Length: '), header
    length = int(header.split(b': ', 1)[1])
    assert 0 < length <= len(data)
    messages.append(json.loads(data[:length]))
    data = data[length:]
responses = {m['request_seq']: m for m in messages if m['type'] == 'response'}
assert responses[5]['success'] is False
diagnostic = responses[5]['body']['elisaReplayDivergence']
assert diagnostic['version'] == 1
assert diagnostic['component'] == sys.argv[2]
assert diagnostic['eventIndex'] == diagnostic['lastVerifiedEvent'] == sys.argv[3]
assert diagnostic['recordingId'] == '1' and diagnostic['branchId'] == '0'
if sys.argv[2] == 'machine-state':
    assert diagnostic['expectedEventAvailable'] and diagnostic['observedEventAvailable']
else:
    assert diagnostic['expectedValue'] == '91' and diagnostic['observedValue'] == '90'
assert diagnostic['expectedValueAvailable'] and diagnostic['observedValueAvailable']
assert diagnostic['expectedValue'] != diagnostic['observedValue']
assert diagnostic['verifiedCheckpointAvailable'] is False
assert responses[6]['body']['currentEvent'] == 0
assert responses[6]['body']['stopGeneration'] == 1
assert responses[7]['success'] and responses[8]['success']
assert responses[7]['body'] == {'accepted': True}
assert any(m.get('event') == 'exited' and m['body']['exitCode'] == -1 for m in messages)
assert not any(m.get('event') == 'output' or 'requestId' in m.get('body', {}) for m in messages)
PY
