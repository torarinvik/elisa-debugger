#!/bin/sh
set -eu

server=${1:?expected DAP server path}
fixture=${2:?expected EDIR fixture path}
initialize_sequence=1
launch_sequence=2
function_breakpoint_sequence=3
configuration_done_sequence=4
continue_sequence=5
minimum_frame_count=5

initialize_payload=$(printf '{"seq":%s,"type":"request","command":"initialize"}' "$initialize_sequence")
launch_payload=$(printf '{"seq":%s,"type":"request","command":"launch","arguments":{"program":"%s"}}' "$launch_sequence" "$fixture")
function_breakpoint_payload=$(printf '{"seq":%s,"type":"request","command":"setFunctionBreakpoints","arguments":{"functionBreakpoints":[{"name":"callee","condition":"local0 == 29","hitCondition":"1"}]}}' "$function_breakpoint_sequence")
configuration_done_payload=$(printf '{"seq":%s,"type":"request","command":"configurationDone"}' "$configuration_done_sequence")
continue_payload=$(printf '{"seq":%s,"type":"request","command":"continue"}' "$continue_sequence")
input=''

for payload in "$initialize_payload" "$launch_payload" "$function_breakpoint_payload" "$configuration_done_payload" "$continue_payload"; do
    payload_length=$(printf '%s' "$payload" | wc -c | tr -d ' ')
    frame=$(printf 'Content-Length: %s\r\n\r\n%s' "$payload_length" "$payload")
    input="${input}${frame}"
done

output=$(printf '%s' "$input" | "$server")
printf '%s\n' "$output" | grep -F '"supportsFunctionBreakpoints":true' >/dev/null
printf '%s\n' "$output" | grep -F '"command":"setFunctionBreakpoints","success":true' | grep -F '"breakpoints":[{"id":1,"verified":true}]' >/dev/null
printf '%s\n' "$output" | grep -F '"event":"stopped"' | grep -F '"reason":"breakpoint"' >/dev/null

printf '%s' "$output" |
    sed 's/}Content-Length:/}\
Content-Length:/g' |
    tr '\015' '\012' |
    awk -v minimum_frame_count="$minimum_frame_count" '
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
            if (frame_count < minimum_frame_count || expected_bytes != "") {
                print "DAP function-breakpoint response stream omitted a request response" > "/dev/stderr"
                exit 1
            }
        }
    '
