#!/bin/sh
set -eu

server=${1:?expected DAP server path}
initialize_payload='{"seq":1,"type":"request","command":"initialize","arguments":{"linesStartAt1":false}}'
launch_payload='{"seq":2,"type":"request","command":"launch","arguments":{"program":"build/edir-fixture.edir"}}'
breakpoint_payload='{"seq":3,"type":"request","command":"setBreakpoints","arguments":{"source":{"sourceReference":7},"breakpoints":[{"line":9}]}}'
next_response_payload='{"seq":4,"type":"request","command":"threads"}'
expected_frame_count=5
input=''

for payload in "$initialize_payload" "$launch_payload" "$breakpoint_payload" "$next_response_payload"; do
    payload_length=$(printf '%s' "$payload" | wc -c | tr -d ' ')
    frame=$(printf 'Content-Length: %s\r\n\r\n%s' "$payload_length" "$payload")
    input="${input}${frame}"
done

output=$(printf '%s' "$input" | "$server")
printf '%s' "$output" |
    sed 's/}Content-Length:/}\
Content-Length:/g' |
    tr '\015' '\012' |
    awk -v expected_frame_count="$expected_frame_count" '
        /^Content-Length: / { expected_bytes = $2; next }
        /^\{/ {
            if (expected_bytes == "" || length($0) != expected_bytes) {
                print "DAP frame Content-Length does not match its response body" > "/dev/stderr"
                exit 1
            }
            if (index($0, "\"command\":\"setBreakpoints\"")) {
                if (index($0, "\"line\":9") == 0) {
                    print "zero-based breakpoint response line is incorrect" > "/dev/stderr"
                    exit 1
                }
                saw_breakpoint = 1
            }
            frame_count++
            expected_bytes = ""
        }
        END {
            if (frame_count != expected_frame_count || !saw_breakpoint || expected_bytes != "") {
                print "DAP response stream did not contain four complete frames" > "/dev/stderr"
                exit 1
            }
        }
    '

header_padding_width=128
header_padding=$(printf '%*s' "$header_padding_width" '')
initialize_length=$(printf '%s' "$initialize_payload" | wc -c | tr -d ' ')
if printf 'Content-Length:%s%s\r\n\r\n%s' "$header_padding" "$initialize_length" "$initialize_payload" | "$server" >/dev/null; then
    printf '%s\n' "DAP server accepted an oversized Content-Length header" >"/dev/stderr"
    exit 1
else
    server_status=$?
    if [ "$server_status" -ne 2 ]; then
        printf '%s\n' "DAP server returned an unexpected status for an oversized header" >"/dev/stderr"
        exit 1
    fi
fi
