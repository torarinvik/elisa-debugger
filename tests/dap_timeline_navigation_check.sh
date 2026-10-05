#!/bin/sh
set -eu

server=${1:?expected DAP server path}
fixture=${2:?expected EDIR fixture path}

readonly INITIALIZE_SEQUENCE=1
readonly LAUNCH_SEQUENCE=2
readonly CONFIGURATION_DONE_SEQUENCE=3
readonly PAUSE_SEQUENCE=4
readonly NEXT_SEQUENCE=5
readonly FIRST_TIMELINE_SEQUENCE=6
readonly SEEK_SEQUENCE=7
readonly SECOND_TIMELINE_SEQUENCE=8
readonly INVALID_SEEK_SEQUENCE=9
readonly FINAL_TIMELINE_SEQUENCE=10
readonly EXPECTED_TIMELINE_VERSION=1
readonly FIRST_EVENT=0
readonly OUT_OF_RANGE_EVENT=99
readonly EXPECTED_STOP_EVENT_COUNT=3
readonly EXPECTED_UNCHANGED_TIMELINE_COUNT=2

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
first_timeline=$(printf '{"seq":%s,"type":"request","command":"elisa/getTimeline"}' "$FIRST_TIMELINE_SEQUENCE")
seek=$(printf '{"seq":%s,"type":"request","command":"elisa/seek","arguments":{"eventIndex":%s}}' "$SEEK_SEQUENCE" "$FIRST_EVENT")
second_timeline=$(printf '{"seq":%s,"type":"request","command":"elisa/getTimeline"}' "$SECOND_TIMELINE_SEQUENCE")
invalid_seek=$(printf '{"seq":%s,"type":"request","command":"elisa/seek","arguments":{"eventIndex":%s}}' "$INVALID_SEEK_SEQUENCE" "$OUT_OF_RANGE_EVENT")
final_timeline=$(printf '{"seq":%s,"type":"request","command":"elisa/getTimeline"}' "$FINAL_TIMELINE_SEQUENCE")
input="$(frame "$initialize")$(frame "$launch")$(frame "$configuration_done")$(frame "$pause")$(frame "$next")$(frame "$first_timeline")$(frame "$seek")$(frame "$second_timeline")$(frame "$invalid_seek")$(frame "$final_timeline")"
output=$(printf '%s' "$input" | "$server")

printf '%s\n' "$output" | grep -F '"supportsElisaTimelineNavigation":true,"elisaTimelineNavigationVersion":'"$EXPECTED_TIMELINE_VERSION" >/dev/null
printf '%s\n' "$output" | grep -F '"command":"elisa/getTimeline","success":true,"body":{"version":1,"currentEvent":1,"hasRetainedRange":true,"retainedFirst":0,"retainedLast":1,"hasExactRange":true,"exactFirst":0,"exactLast":1,"canSeek":true,"canReverse":true}' >/dev/null
printf '%s\n' "$output" | grep -F '"request_seq":'"$SEEK_SEQUENCE"',"command":"elisa/seek","success":true' >/dev/null
printf '%s\n' "$output" | grep -F '"command":"elisa/getTimeline","success":true,"body":{"version":1,"currentEvent":0,"hasRetainedRange":true,"retainedFirst":0,"retainedLast":1,"hasExactRange":true,"exactFirst":0,"exactLast":1,"canSeek":true,"canReverse":false}' >/dev/null
printf '%s\n' "$output" | grep -F '"request_seq":'"$INVALID_SEEK_SEQUENCE"',"command":"elisa/seek","success":false' >/dev/null
test "$(printf '%s\n' "$output" | grep -F -c '"command":"elisa/getTimeline","success":true,"body":{"version":1,"currentEvent":0,"hasRetainedRange":true,"retainedFirst":0,"retainedLast":1,"hasExactRange":true,"exactFirst":0,"exactLast":1,"canSeek":true,"canReverse":false}')" -eq "$EXPECTED_UNCHANGED_TIMELINE_COUNT"
test "$(printf '%s\n' "$output" | grep -o '"event":"stopped"' | wc -l | tr -d ' ')" -eq "$EXPECTED_STOP_EVENT_COUNT"
assert_frame_lengths "$output"
