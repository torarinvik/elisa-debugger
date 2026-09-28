#!/bin/sh
set -eu

server=${1:?expected DAP server path}
fixture=${2:?expected EDIR fixture path}
callee_line=${3:?expected callee source line}

initialize_payload='{"seq":1,"type":"request","command":"initialize"}'
launch_payload=$(printf '{"seq":2,"type":"request","command":"launch","arguments":{"program":"%s"}}' "$fixture")
breakpoint_payload=$(printf '{"seq":3,"type":"request","command":"setBreakpoints","arguments":{"source":{"path":"main.elisa"},"breakpoints":[{"line":%s,"logMessage":"entered callee"}]}}' "$callee_line")
configuration_done_payload='{"seq":4,"type":"request","command":"configurationDone"}'
pause_payload='{"seq":5,"type":"request","command":"pause"}'
input=''

for payload in "$initialize_payload" "$launch_payload" "$breakpoint_payload" "$configuration_done_payload" "$pause_payload"; do
    payload_length=$(printf '%s' "$payload" | wc -c | tr -d ' ')
    frame=$(printf 'Content-Length: %s\r\n\r\n%s' "$payload_length" "$payload")
    input="${input}${frame}"
done

for request_id in 6 7 8 9 10; do
    payload=$(printf '{"seq":%s,"type":"request","command":"stepIn"}' "$request_id")
    payload_length=$(printf '%s' "$payload" | wc -c | tr -d ' ')
    frame=$(printf 'Content-Length: %s\r\n\r\n%s' "$payload_length" "$payload")
    input="${input}${frame}"
done

output=$(printf '%s' "$input" | "$server")
printf '%s\n' "$output" | grep -F '"supportsLogPoints":true' >/dev/null
printf '%s\n' "$output" | grep -F '"command":"setBreakpoints","success":true' | grep -F '"verified":true' >/dev/null
step_in_count=$(printf '%s\n' "$output" | grep -F '"command":"stepIn","success":true' | wc -l | tr -d ' ')
if [ "$step_in_count" -ne 5 ]; then
    printf '%s\n' "DAP stepIn did not return five successful responses" >&2
    exit 1
fi
printf '%s\n' "$output" | grep -F '"event":"output"' | grep -F '"category":"console"' | grep -F '"output":"entered callee\n"' >/dev/null
if printf '%s\n' "$output" | grep -F '"reason":"breakpoint"' >/dev/null; then
    printf '%s\n' "stepIn logpoint stopped execution like a regular breakpoint" >&2
    exit 1
fi
