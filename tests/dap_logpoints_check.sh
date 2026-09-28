#!/bin/sh
set -eu

server=${1:?expected DAP server path}
fixture=${2:?expected EDIR fixture path}
logpoint_line=${3:?expected logpoint source line}

initialize_payload='{"seq":1,"type":"request","command":"initialize"}'
launch_payload=$(printf '{"seq":2,"type":"request","command":"launch","arguments":{"program":"%s"}}' "$fixture")
breakpoint_payload=$(printf '{"seq":3,"type":"request","command":"setBreakpoints","arguments":{"source":{"path":"main.elisa"},"breakpoints":[{"line":%s,"logMessage":"value = {local0}"}]}}' "$logpoint_line")
configuration_done_payload='{"seq":4,"type":"request","command":"configurationDone"}'
continue_payload='{"seq":5,"type":"request","command":"continue"}'
input=''

for payload in "$initialize_payload" "$launch_payload" "$breakpoint_payload" "$configuration_done_payload" "$continue_payload"; do
    payload_length=$(printf '%s' "$payload" | wc -c | tr -d ' ')
    frame=$(printf 'Content-Length: %s\r\n\r\n%s' "$payload_length" "$payload")
    input="${input}${frame}"
done

output=$(printf '%s' "$input" | "$server")
printf '%s\n' "$output" | grep -F '"supportsLogPoints":true' >/dev/null
printf '%s\n' "$output" | grep -F '"command":"setBreakpoints","success":true' | grep -F '"verified":true' >/dev/null
printf '%s\n' "$output" | grep -F '"event":"output"' | grep -F '"category":"console"' | grep -F '"output":"value = 17\n"' >/dev/null
printf '%s\n' "$output" | grep -F '"event":"terminated"' >/dev/null
if printf '%s\n' "$output" | grep -F '"reason":"breakpoint"' >/dev/null; then
    printf '%s\n' "logpoint stopped execution like a regular breakpoint" >&2
    exit 1
fi

expected_frame_count=10
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
            frame_count++
            expected_bytes = ""
        }
        END {
            if (frame_count != expected_frame_count || expected_bytes != "") {
                print "DAP logpoint response stream did not contain ten complete frames" > "/dev/stderr"
                exit 1
            }
        }
    '
