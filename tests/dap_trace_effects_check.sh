#!/bin/sh
set -eu

server=${1:?expected DAP server path}
fixture=${2:?expected compiler-produced effect fixture}
trace=build/dap-trace-effects.eltr

frame() {
    payload=$1
    length=$(printf %s "$payload" | wc -c | tr -d ' ')
    printf 'Content-Length: %s\r\n\r\n%s' "$length" "$payload"
}

record_requests() {
    frame '{"seq":1,"type":"request","command":"initialize"}'
    frame "{\"seq\":2,\"type\":\"request\",\"command\":\"launch\",\"arguments\":{\"program\":\"$fixture\",\"elisaVirtualFiles\":[{\"handle\":1,\"path\":\"data/input.bin\",\"contentsHex\":\"41\"}]}}"
    frame '{"seq":3,"type":"request","command":"configurationDone"}'
    frame '{"seq":4,"type":"request","command":"continue"}'
    frame '{"seq":5,"type":"request","command":"elisa/provideHostEffect","arguments":{"requestId":4,"valueHigh":0,"valueLow":3}}'
    frame '{"seq":6,"type":"request","command":"continue"}'
    frame '{"seq":7,"type":"request","command":"elisa/provideHostEffect","arguments":{"requestId":6,"valueHigh":4294967295,"valueLow":4294967295}}'
    frame '{"seq":8,"type":"request","command":"continue"}'
    frame '{"seq":9,"type":"request","command":"elisa/provideHostEffect","arguments":{"requestId":8}}'
    frame '{"seq":10,"type":"request","command":"continue"}'
    frame '{"seq":11,"type":"request","command":"elisa/provideHostEffect","arguments":{"requestId":10,"valueHigh":0,"valueLow":66}}'
    frame '{"seq":12,"type":"request","command":"continue"}'
    frame '{"seq":13,"type":"request","command":"elisa/provideHostEffect","arguments":{"requestId":12,"valueHigh":4294967295,"valueLow":4294967295}}'
    frame '{"seq":14,"type":"request","command":"continue"}'
    frame "{\"seq\":15,\"type\":\"request\",\"command\":\"elisa/saveTrace\",\"arguments\":{\"path\":\"$trace\"}}"
}

replay_requests() {
    frame '{"seq":1,"type":"request","command":"initialize"}'
    # The second adapter starts without any mounted input or provider reply.
    frame "{\"seq\":2,\"type\":\"request\",\"command\":\"launch\",\"arguments\":{\"program\":\"$fixture\"}}"
    frame '{"seq":3,"type":"request","command":"configurationDone"}'
    frame '{"seq":4,"type":"request","command":"pause"}'
    frame "{\"seq\":5,\"type\":\"request\",\"command\":\"elisa/openTrace\",\"arguments\":{\"path\":\"$trace\",\"eventIndex\":0,\"expectedStopGeneration\":1}}"
    frame '{"seq":6,"type":"request","command":"next"}'
    frame '{"seq":7,"type":"request","command":"continue"}'
    frame "{\"seq\":8,\"type\":\"request\",\"command\":\"elisa/saveTrace\",\"arguments\":{\"path\":\"$trace\"}}"
}

record_output=$(record_requests | "$server")
printf '%s\n' "$record_output" | grep -F '"request_seq":15,"command":"elisa/saveTrace","success":true,"body":{"accepted":true}' > /dev/null
printf '%s\n' "$record_output" | grep -F '"event":"exited","body":{"exitCode":-1}' > /dev/null
original_trace=$(cksum "$trace")
replay_output=$(replay_requests | "$server")
for response in \
    '"request_seq":5,"command":"elisa/openTrace","success":true,"body":{"accepted":true}' \
    '"request_seq":6,"command":"next","success":true' \
    '"request_seq":7,"command":"continue","success":true' \
    '"request_seq":8,"command":"elisa/saveTrace","success":true,"body":{"accepted":true}' \
    '"event":"exited","body":{"exitCode":-1}'; do
    printf '%s\n' "$replay_output" | grep -F "$response" > /dev/null
done
if printf '%s\n' "$replay_output" | grep -E '"requestId":|"event":"output"' > /dev/null; then
    printf '%s\n' "$replay_output" >&2
    exit 1
fi
test "$(cksum "$trace")" = "$original_trace"
