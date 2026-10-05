#!/bin/sh
set -eu

server=${1:?expected DAP server path}
fixture=${2:?expected EDIR fixture path}

readonly INITIALIZE_SEQUENCE=1
readonly LAUNCH_SEQUENCE=2
readonly CONFIGURATION_DONE_SEQUENCE=3
readonly PAUSE_SEQUENCE=4
readonly NEXT_SEQUENCE=5
readonly OLD_STACK_SEQUENCE=6
readonly FIRST_TIMELINE_SEQUENCE=7
readonly STALE_OPEN_SEQUENCE=8
readonly UNCHANGED_TIMELINE_SEQUENCE=9
readonly SAVE_TRACE_SEQUENCE=10
readonly OPEN_TRACE_SEQUENCE=11
readonly OPENED_TIMELINE_SEQUENCE=12
readonly FORWARD_SEEK_SEQUENCE=13
readonly FORWARD_TIMELINE_SEQUENCE=14
readonly REVERSE_SEEK_SEQUENCE=15
readonly CURRENT_STACK_SEQUENCE=16
readonly STALE_SCOPES_SEQUENCE=17
readonly CURRENT_SCOPES_SEQUENCE=18
readonly SECOND_TIMELINE_SEQUENCE=19
readonly STALE_SEEK_SEQUENCE=20
readonly INVALID_SEEK_SEQUENCE=21
readonly FINAL_TIMELINE_SEQUENCE=22
readonly EXPECTED_TIMELINE_VERSION=1
readonly EXPECTED_TRACE_FILES_VERSION=1
readonly TRACE_PATH='build/dap timeline navigation.trace'
readonly FIRST_EVENT=0
readonly STALE_SEEK_TARGET_EVENT=1
readonly OUT_OF_RANGE_EVENT=99
readonly STALE_STOP_GENERATION=1
readonly EXPECTED_STOP_EVENT_COUNT=5
readonly EXPECTED_UNCHANGED_TIMELINE_COUNT=2
readonly SUPPORTED_THREAD_ID=1
readonly DAP_FRAME_ID_STRIDE=18
readonly DAP_FRAME_ID_FIRST_OFFSET=1
readonly OLD_STOP_GENERATION=2
readonly OPEN_STOP_GENERATION=3
readonly FORWARD_STOP_GENERATION=4
readonly FINAL_STOP_GENERATION=5
readonly EXPECTED_STALE_FRAME_ID=$((OLD_STOP_GENERATION * DAP_FRAME_ID_STRIDE + DAP_FRAME_ID_FIRST_OFFSET))
readonly EXPECTED_CURRENT_FRAME_ID=$((FINAL_STOP_GENERATION * DAP_FRAME_ID_STRIDE + DAP_FRAME_ID_FIRST_OFFSET))

frame() {
    payload=$1
    payload_length=$(printf '%s' "$payload" | wc -c | tr -d ' ')
    printf 'Content-Length: %s\r\n\r\n%s' "$payload_length" "$payload"
}

assert_frame_lengths() {
    frame_output=$1
    printf '%s' "$frame_output" |
        sed 's/}Content-Length:/}\
Content-Length:/g' |
        tr '\015' '\012' |
        awk '
            /^Content-Length: / { expected_bytes = $2; next }
            /^\{/ {
                if (expected_bytes == "" || length($0) != expected_bytes) {
                    print "DAP frame Content-Length does not match its response body" > "/dev/stderr"
                    exit 1
                }
                frame_count++
                expected_bytes = ""
            }
            END {
                if (frame_count == 0 || expected_bytes != "") {
                    print "DAP timeline response stream contains an incomplete frame" > "/dev/stderr"
                    exit 1
                }
            }
        '
}

initialize=$(printf '{"seq":%s,"type":"request","command":"initialize"}' "$INITIALIZE_SEQUENCE")
launch=$(printf '{"seq":%s,"type":"request","command":"launch","arguments":{"program":"%s"}}' "$LAUNCH_SEQUENCE" "$fixture")
configuration_done=$(printf '{"seq":%s,"type":"request","command":"configurationDone"}' "$CONFIGURATION_DONE_SEQUENCE")
pause=$(printf '{"seq":%s,"type":"request","command":"pause"}' "$PAUSE_SEQUENCE")
next=$(printf '{"seq":%s,"type":"request","command":"next"}' "$NEXT_SEQUENCE")
old_stack=$(printf '{"seq":%s,"type":"request","command":"stackTrace","arguments":{"threadId":%s}}' "$OLD_STACK_SEQUENCE" "$SUPPORTED_THREAD_ID")
first_timeline=$(printf '{"seq":%s,"type":"request","command":"elisa/getTimeline"}' "$FIRST_TIMELINE_SEQUENCE")
stale_open=$(printf '{"seq":%s,"type":"request","command":"elisa/openTrace","arguments":{"path":"%s","eventIndex":%s,"expectedStopGeneration":%s}}' "$STALE_OPEN_SEQUENCE" "$TRACE_PATH" "$FIRST_EVENT" "$STALE_STOP_GENERATION")
unchanged_timeline=$(printf '{"seq":%s,"type":"request","command":"elisa/getTimeline"}' "$UNCHANGED_TIMELINE_SEQUENCE")
save_trace=$(printf '{"seq":%s,"type":"request","command":"elisa/saveTrace","arguments":{"path":"%s"}}' "$SAVE_TRACE_SEQUENCE" "$TRACE_PATH")
open_trace=$(printf '{"seq":%s,"type":"request","command":"elisa/openTrace","arguments":{"path":"%s","eventIndex":%s,"expectedStopGeneration":%s}}' "$OPEN_TRACE_SEQUENCE" "$TRACE_PATH" "$FIRST_EVENT" "$OLD_STOP_GENERATION")
opened_timeline=$(printf '{"seq":%s,"type":"request","command":"elisa/getTimeline"}' "$OPENED_TIMELINE_SEQUENCE")
forward_seek=$(printf '{"seq":%s,"type":"request","command":"elisa/seek","arguments":{"eventIndex":%s,"expectedStopGeneration":%s}}' "$FORWARD_SEEK_SEQUENCE" "$STALE_SEEK_TARGET_EVENT" "$OPEN_STOP_GENERATION")
forward_timeline=$(printf '{"seq":%s,"type":"request","command":"elisa/getTimeline"}' "$FORWARD_TIMELINE_SEQUENCE")
reverse_seek=$(printf '{"seq":%s,"type":"request","command":"elisa/seek","arguments":{"eventIndex":%s,"expectedStopGeneration":%s}}' "$REVERSE_SEEK_SEQUENCE" "$FIRST_EVENT" "$FORWARD_STOP_GENERATION")
current_stack=$(printf '{"seq":%s,"type":"request","command":"stackTrace","arguments":{"threadId":%s}}' "$CURRENT_STACK_SEQUENCE" "$SUPPORTED_THREAD_ID")
stale_scopes=$(printf '{"seq":%s,"type":"request","command":"scopes","arguments":{"frameId":%s}}' "$STALE_SCOPES_SEQUENCE" "$EXPECTED_STALE_FRAME_ID")
current_scopes=$(printf '{"seq":%s,"type":"request","command":"scopes","arguments":{"frameId":%s}}' "$CURRENT_SCOPES_SEQUENCE" "$EXPECTED_CURRENT_FRAME_ID")
second_timeline=$(printf '{"seq":%s,"type":"request","command":"elisa/getTimeline"}' "$SECOND_TIMELINE_SEQUENCE")
stale_seek=$(printf '{"seq":%s,"type":"request","command":"elisa/seek","arguments":{"eventIndex":%s,"expectedStopGeneration":%s}}' "$STALE_SEEK_SEQUENCE" "$STALE_SEEK_TARGET_EVENT" "$OLD_STOP_GENERATION")
invalid_seek=$(printf '{"seq":%s,"type":"request","command":"elisa/seek","arguments":{"eventIndex":%s,"expectedStopGeneration":%s}}' "$INVALID_SEEK_SEQUENCE" "$OUT_OF_RANGE_EVENT" "$FINAL_STOP_GENERATION")
final_timeline=$(printf '{"seq":%s,"type":"request","command":"elisa/getTimeline"}' "$FINAL_TIMELINE_SEQUENCE")
input="$(frame "$initialize")$(frame "$launch")$(frame "$configuration_done")$(frame "$pause")$(frame "$next")$(frame "$old_stack")$(frame "$first_timeline")$(frame "$stale_open")$(frame "$unchanged_timeline")$(frame "$save_trace")$(frame "$open_trace")$(frame "$opened_timeline")$(frame "$forward_seek")$(frame "$forward_timeline")$(frame "$reverse_seek")$(frame "$current_stack")$(frame "$stale_scopes")$(frame "$current_scopes")$(frame "$second_timeline")$(frame "$stale_seek")$(frame "$invalid_seek")$(frame "$final_timeline")"
output=$(printf '%s' "$input" | "$server")

printf '%s\n' "$output" | grep -F '"supportsElisaTimelineNavigation":true,"elisaTimelineNavigationVersion":'"$EXPECTED_TIMELINE_VERSION" >/dev/null
printf '%s\n' "$output" | grep -F '"supportsElisaTraceFiles":true,"elisaTraceFilesVersion":'"$EXPECTED_TRACE_FILES_VERSION" >/dev/null
printf '%s\n' "$output" | grep -F '"command":"elisa/getTimeline","success":true,"body":{"version":1,"stopGeneration":'"$OLD_STOP_GENERATION"',"currentEvent":1,"hasRetainedRange":true,"retainedFirst":0,"retainedLast":1,"hasExactRange":true,"exactFirst":0,"exactLast":1,"canSeek":true,"canReverse":true}' >/dev/null
printf '%s\n' "$output" | grep -F '"request_seq":'"$OLD_STACK_SEQUENCE"',"command":"stackTrace","success":true,"body":{"stackFrames":[{"id":'"$EXPECTED_STALE_FRAME_ID" >/dev/null
printf '%s\n' "$output" | grep -F '"request_seq":'"$STALE_OPEN_SEQUENCE"',"command":"elisa/openTrace","success":false,"message":"trace control is stale; query the timeline again"' >/dev/null
printf '%s\n' "$output" | grep -F '"request_seq":'"$SAVE_TRACE_SEQUENCE"',"command":"elisa/saveTrace","success":true,"body":{"accepted":true}' >/dev/null
printf '%s\n' "$output" | grep -F '"request_seq":'"$OPEN_TRACE_SEQUENCE"',"command":"elisa/openTrace","success":true,"body":{"accepted":true}' >/dev/null
printf '%s\n' "$output" | grep -F '"command":"elisa/getTimeline","success":true,"body":{"version":1,"stopGeneration":'"$OPEN_STOP_GENERATION"',"currentEvent":0,"hasRetainedRange":true,"retainedFirst":0,"retainedLast":1,"hasExactRange":true,"exactFirst":0,"exactLast":1' >/dev/null
printf '%s\n' "$output" | grep -F '"request_seq":'"$FORWARD_SEEK_SEQUENCE"',"command":"elisa/seek","success":true' >/dev/null
printf '%s\n' "$output" | grep -F '"command":"elisa/getTimeline","success":true,"body":{"version":1,"stopGeneration":'"$FORWARD_STOP_GENERATION"',"currentEvent":1,"hasRetainedRange":true,"retainedFirst":0,"retainedLast":1' >/dev/null
printf '%s\n' "$output" | grep -F '"request_seq":'"$REVERSE_SEEK_SEQUENCE"',"command":"elisa/seek","success":true' >/dev/null
printf '%s\n' "$output" | grep -F '"request_seq":'"$CURRENT_STACK_SEQUENCE"',"command":"stackTrace","success":true,"body":{"stackFrames":[{"id":'"$EXPECTED_CURRENT_FRAME_ID" >/dev/null
printf '%s\n' "$output" | grep -F '"request_seq":'"$STALE_SCOPES_SEQUENCE"',"command":"scopes","success":false' >/dev/null
printf '%s\n' "$output" | grep -F '"request_seq":'"$CURRENT_SCOPES_SEQUENCE"',"command":"scopes","success":true' >/dev/null
printf '%s\n' "$output" | grep -F '"command":"elisa/getTimeline","success":true,"body":{"version":1,"stopGeneration":'"$FINAL_STOP_GENERATION"',"currentEvent":0,"hasRetainedRange":true,"retainedFirst":0,"retainedLast":1,"hasExactRange":true,"exactFirst":0,"exactLast":1,"canSeek":true,"canReverse":false}' >/dev/null
printf '%s\n' "$output" | grep -F '"request_seq":'"$STALE_SEEK_SEQUENCE"',"command":"elisa/seek","success":false,"message":"timeline snapshot is stale; query the timeline again"' >/dev/null
printf '%s\n' "$output" | grep -F '"request_seq":'"$INVALID_SEEK_SEQUENCE"',"command":"elisa/seek","success":false' >/dev/null
test "$(printf '%s\n' "$output" | grep -F -c '"command":"elisa/getTimeline","success":true,"body":{"version":1,"stopGeneration":'"$FINAL_STOP_GENERATION"',"currentEvent":0,"hasRetainedRange":true,"retainedFirst":0,"retainedLast":1,"hasExactRange":true,"exactFirst":0,"exactLast":1,"canSeek":true,"canReverse":false}')" -eq "$EXPECTED_UNCHANGED_TIMELINE_COUNT"
test "$(printf '%s\n' "$output" | grep -o '"event":"stopped"' | wc -l | tr -d ' ')" -eq "$EXPECTED_STOP_EVENT_COUNT"
assert_frame_lengths "$output"
