#!/bin/sh
set -eu

DAP_SERVER=$1
PROGRAM_PATH=$2
EXPECTED_SUCCESSFUL_CONFIGURATION_DONE_RESPONSES=2
EXPECTED_INITIALIZED_EVENTS=1
DAP_SEQUENCE_PRELAUNCH_CONFIGURATION=1
DAP_SEQUENCE_INITIALIZE=2
DAP_SEQUENCE_REJECTED_LAUNCH=3
DAP_SEQUENCE_ACCEPTED_LAUNCH=4
DAP_SEQUENCE_POSTLAUNCH_CONFIGURATION=5
DAP_SEQUENCE_PAUSE=6
DAP_SEQUENCE_POSTPAUSE_CONFIGURATION=7
DAP_SEQUENCE_UNKNOWN_COMMAND=8
DAP_SEQUENCE_VALID_STACK_TRACE=9
DAP_SEQUENCE_INVALID_STACK_TRACE=10
DAP_SEQUENCE_VALID_SCOPES=11
DAP_SEQUENCE_INVALID_SCOPES=12
DAP_SEQUENCE_MISSING_SCOPES=13
DAP_MAIN_THREAD_ID=1
DAP_INVALID_THREAD_ID=2
DAP_FRAME_ID_STRIDE=18
DAP_FRAME_ID_FIRST_OFFSET=1
DAP_FIRST_STOP_GENERATION=1
DAP_FIRST_STOP_FRAME_ID=$((DAP_FIRST_STOP_GENERATION * DAP_FRAME_ID_STRIDE + DAP_FRAME_ID_FIRST_OFFSET))
DAP_INVALID_NEXT_FRAME_ID=$((DAP_FIRST_STOP_FRAME_ID + 1))

input=$(for payload in \
    "{\"seq\":$DAP_SEQUENCE_PRELAUNCH_CONFIGURATION,\"type\":\"request\",\"command\":\"configurationDone\"}" \
    "{\"seq\":$DAP_SEQUENCE_INITIALIZE,\"type\":\"request\",\"command\":\"initialize\"}" \
    "{\"seq\":$DAP_SEQUENCE_REJECTED_LAUNCH,\"type\":\"request\",\"command\":\"launch\",\"arguments\":{\"program\":\"/dev/null\"}}" \
    "{\"seq\":$DAP_SEQUENCE_ACCEPTED_LAUNCH,\"type\":\"request\",\"command\":\"launch\",\"arguments\":{\"program\":\"$PROGRAM_PATH\"}}" \
    "{\"seq\":$DAP_SEQUENCE_POSTLAUNCH_CONFIGURATION,\"type\":\"request\",\"command\":\"configurationDone\"}" \
    "{\"seq\":$DAP_SEQUENCE_PAUSE,\"type\":\"request\",\"command\":\"pause\"}" \
    "{\"seq\":$DAP_SEQUENCE_POSTPAUSE_CONFIGURATION,\"type\":\"request\",\"command\":\"configurationDone\"}" \
    "{\"seq\":$DAP_SEQUENCE_UNKNOWN_COMMAND,\"type\":\"request\",\"command\":\"dPntinue\"}" \
    "{\"seq\":$DAP_SEQUENCE_VALID_STACK_TRACE,\"type\":\"request\",\"command\":\"stackTrace\",\"arguments\":{\"threadId\":$DAP_MAIN_THREAD_ID}}" \
    "{\"seq\":$DAP_SEQUENCE_INVALID_STACK_TRACE,\"type\":\"request\",\"command\":\"stackTrace\",\"arguments\":{\"threadId\":$DAP_INVALID_THREAD_ID}}" \
    "{\"seq\":$DAP_SEQUENCE_VALID_SCOPES,\"type\":\"request\",\"command\":\"scopes\",\"arguments\":{\"frameId\":$DAP_FIRST_STOP_FRAME_ID}}" \
    "{\"seq\":$DAP_SEQUENCE_INVALID_SCOPES,\"type\":\"request\",\"command\":\"scopes\",\"arguments\":{\"frameId\":$DAP_INVALID_NEXT_FRAME_ID}}" \
    "{\"seq\":$DAP_SEQUENCE_MISSING_SCOPES,\"type\":\"request\",\"command\":\"scopes\"}"; do
    frame_length=$(printf %s "$payload" | wc -c | tr -d ' ')
    printf 'Content-Length: %s\r\n\r\n%s' "$frame_length" "$payload"
done)

output=$(printf %s "$input" | "$DAP_SERVER")
printf '%s\n' "$output" | grep -F '"command":"configurationDone","success":false,"message":"configurationDone requires a launched session"' >/dev/null
rejected_launch_response_line=$(printf '%s\n' "$output" | grep -n -F '"command":"launch","success":false' | cut -d: -f1)
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
configuration_done_response_line=$(printf '%s\n' "$output" | grep -n -F '"command":"configurationDone","success":true' | sed -n '1p' | cut -d: -f1)
test "$initialize_response_line" -lt "$initialized_event_line"
test "$rejected_launch_response_line" -lt "$initialized_event_line"
test "$initialize_response_line" -lt "$launch_response_line"
test "$initialized_event_line" -lt "$configuration_done_response_line"
test "$configuration_done_response_line" -lt "$launch_response_line"
initialized_event_count=$(printf '%s\n' "$output" | grep -F '"type":"event","event":"initialized"' | wc -l | tr -d ' ')
test "$initialized_event_count" -eq "$EXPECTED_INITIALIZED_EVENTS"
if printf '%s\n' "$output" | grep -F '"type":"event","event":"continued"' >/dev/null; then
    exit 1
fi
