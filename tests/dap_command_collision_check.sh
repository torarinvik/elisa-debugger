#!/bin/sh
set -eu

DAP_SERVER=$1
PROGRAM_PATH=$2
EXPECTED_SUCCESSFUL_CONFIGURATION_DONE_RESPONSES=2

input=$(for payload in \
    '{"seq":1,"type":"request","command":"configurationDone"}' \
    '{"seq":2,"type":"request","command":"initialize"}' \
    "{\"seq\":3,\"type\":\"request\",\"command\":\"launch\",\"arguments\":{\"program\":\"$PROGRAM_PATH\"}}" \
    '{"seq":4,"type":"request","command":"configurationDone"}' \
    '{"seq":5,"type":"request","command":"pause"}' \
    '{"seq":6,"type":"request","command":"configurationDone"}' \
    '{"seq":7,"type":"request","command":"dPntinue"}' \
    '{"seq":8,"type":"request","command":"stackTrace","arguments":{"threadId":1}}' \
    '{"seq":9,"type":"request","command":"stackTrace","arguments":{"threadId":2}}' \
    '{"seq":10,"type":"request","command":"scopes","arguments":{"frameId":1}}' \
    '{"seq":11,"type":"request","command":"scopes","arguments":{"frameId":2}}' \
    '{"seq":12,"type":"request","command":"scopes"}'; do
    frame_length=$(printf %s "$payload" | wc -c | tr -d ' ')
    printf 'Content-Length: %s\r\n\r\n%s' "$frame_length" "$payload"
done)

output=$(printf %s "$input" | "$DAP_SERVER")
printf '%s\n' "$output" | grep -F '"command":"configurationDone","success":false,"message":"configurationDone requires a launched session"' >/dev/null
successful_configuration_done_responses=$(printf '%s\n' "$output" | grep -F '"command":"configurationDone","success":true' | wc -l | tr -d ' ')
test "$successful_configuration_done_responses" -eq "$EXPECTED_SUCCESSFUL_CONFIGURATION_DONE_RESPONSES"
printf '%s\n' "$output" | grep -F '"command":"dPntinue","success":false,"message":"unsupported command"' >/dev/null
printf '%s\n' "$output" | grep -F '"command":"stackTrace","success":true' >/dev/null
printf '%s\n' "$output" | grep -F '"command":"stackTrace","success":false' >/dev/null
printf '%s\n' "$output" | grep -F '"command":"scopes","success":true' >/dev/null
printf '%s\n' "$output" | grep -F '"command":"scopes","success":false' >/dev/null
initialize_response_line=$(printf '%s\n' "$output" | grep -n -F '"command":"initialize","success":true' | cut -d: -f1)
initialized_event_line=$(printf '%s\n' "$output" | grep -n -F '"type":"event","event":"initialized"' | cut -d: -f1)
launch_response_line=$(printf '%s\n' "$output" | grep -n -F '"command":"launch","success":true' | cut -d: -f1)
test "$initialize_response_line" -lt "$initialized_event_line"
test "$initialized_event_line" -lt "$launch_response_line"
if printf '%s\n' "$output" | grep -F '"type":"event","event":"continued"' >/dev/null; then
    exit 1
fi
