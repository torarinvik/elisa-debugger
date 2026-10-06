#!/bin/sh
set -eu

server=${1:?expected DAP server path}
fixture=${2:?expected compiler-produced virtual-file mutation fixture}
trace=build/dap-file-mutations.eltr
host_input=build/dap-file-mutations-host.bin
trap 'rm -f "$host_input"' EXIT HUP INT TERM
printf A > "$host_input"

frame() {
    payload=$1
    length=$(printf %s "$payload" | wc -c | tr -d ' ')
    printf 'Content-Length: %s\r\n\r\n%s' "$length" "$payload"
}

record_requests() {
    frame '{"seq":1,"type":"request","command":"initialize"}'
    frame "{\"seq\":2,\"type\":\"request\",\"command\":\"launch\",\"arguments\":{\"program\":\"$fixture\",\"elisaVirtualFiles\":[{\"handle\":1,\"path\":\"$host_input\",\"contentsHex\":\"41\",\"writable\":true}]}}"
    frame '{"seq":3,"type":"request","command":"configurationDone"}'
    frame '{"seq":4,"type":"request","command":"continue"}'
    frame "{\"seq\":5,\"type\":\"request\",\"command\":\"elisa/saveTrace\",\"arguments\":{\"path\":\"$trace\"}}"
}

replay_requests() {
    frame '{"seq":1,"type":"request","command":"initialize"}'
    frame "{\"seq\":2,\"type\":\"request\",\"command\":\"launch\",\"arguments\":{\"program\":\"$fixture\"}}"
    frame '{"seq":3,"type":"request","command":"configurationDone"}'
    frame '{"seq":4,"type":"request","command":"pause"}'
    frame "{\"seq\":5,\"type\":\"request\",\"command\":\"elisa/openTrace\",\"arguments\":{\"path\":\"$trace\",\"eventIndex\":0,\"expectedStopGeneration\":1}}"
    frame '{"seq":6,"type":"request","command":"next"}'
    frame '{"seq":7,"type":"request","command":"stepBack"}'
    frame '{"seq":8,"type":"request","command":"continue"}'
    frame "{\"seq\":9,\"type\":\"request\",\"command\":\"elisa/saveTrace\",\"arguments\":{\"path\":\"$trace\"}}"
}

assert_frames() {
    printf '%s' "$1" | python3 -c '
import json, sys
data = sys.stdin.buffer.read()
while data:
    header, data = data.split(b"\r\n\r\n", 1)
    length = int(header.removeprefix(b"Content-Length: "))
    payload, data = data[:length], data[length:]
    assert len(payload) == length
    json.loads(payload)
'
}

record_output=$(record_requests | "$server")
printf '%s\n' "$record_output" | grep -F '"supportsElisaVirtualFileWrites":true,"elisaVirtualFileWritesVersion":1' >/dev/null
printf '%s\n' "$record_output" | grep -F '"request_seq":5,"command":"elisa/saveTrace","success":true,"body":{"accepted":true}' >/dev/null
printf '%s\n' "$record_output" | grep -F '"event":"exited","body":{"exitCode":-1}' >/dev/null
assert_frames "$record_output"
test "$(cat "$host_input")" = A
original_trace=$(cksum "$trace")
printf Z > "$host_input"
for host_state in changed missing; do
    if test "$host_state" = missing; then rm "$host_input"; fi
    replay_output=$(replay_requests | "$server")
    for response in \
        '"request_seq":5,"command":"elisa/openTrace","success":true' \
        '"request_seq":6,"command":"next","success":true' \
        '"request_seq":7,"command":"stepBack","success":true' \
        '"request_seq":8,"command":"continue","success":true' \
        '"request_seq":9,"command":"elisa/saveTrace","success":true' \
        '"event":"exited","body":{"exitCode":-1}'; do
        printf '%s\n' "$replay_output" | grep -F "$response" >/dev/null
    done
    if printf '%s\n' "$replay_output" | grep -E '"requestId":|"event":"output"' >/dev/null; then
        printf '%s\n' "$replay_output" >&2
        exit 1
    fi
    assert_frames "$replay_output"
    test "$(cksum "$trace")" = "$original_trace"
    if test "$host_state" = changed; then test "$(cat "$host_input")" = Z; fi
done
test ! -e "$host_input"
