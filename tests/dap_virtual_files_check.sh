#!/bin/sh
set -eu

server=${1:?expected DAP server path}
fixture=${2:?expected compiler-produced virtual-file EDIR path}

readonly INITIALIZE_SEQUENCE=1
readonly LAUNCH_SEQUENCE=2
readonly CONFIGURATION_DONE_SEQUENCE=3
readonly CONTINUE_SEQUENCE=4
readonly EXPECTED_EXIT_CODE=65
readonly EXPECTED_VIRTUAL_FILES_VERSION=1

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
                    print "DAP virtual-file response stream contains an incomplete frame" > "/dev/stderr"
                    exit 1
                }
            }
        '
}

initialize=$(printf '{"seq":%s,"type":"request","command":"initialize"}' "$INITIALIZE_SEQUENCE")
launch=$(printf '{"seq":%s,"type":"request","command":"launch","arguments":{"program":"%s","elisaVirtualFiles":[{"handle":1,"path":"data/input.bin","contentsHex":"41"}]}}' "$LAUNCH_SEQUENCE" "$fixture")
configuration_done=$(printf '{"seq":%s,"type":"request","command":"configurationDone"}' "$CONFIGURATION_DONE_SEQUENCE")
continue_request=$(printf '{"seq":%s,"type":"request","command":"continue"}' "$CONTINUE_SEQUENCE")
input="$(frame "$initialize")$(frame "$launch")$(frame "$configuration_done")$(frame "$continue_request")"
output=$(printf '%s' "$input" | "$server")

printf '%s\n' "$output" | grep -F "\"supportsElisaVirtualFiles\":true,\"elisaVirtualFilesVersion\":$EXPECTED_VIRTUAL_FILES_VERSION" >/dev/null
printf '%s\n' "$output" | grep -F "\"request_seq\":$LAUNCH_SEQUENCE,\"command\":\"launch\",\"success\":true" >/dev/null
printf '%s\n' "$output" | grep -F "\"request_seq\":$CONTINUE_SEQUENCE,\"command\":\"continue\",\"success\":true" >/dev/null
printf '%s\n' "$output" | grep -F "\"event\":\"exited\",\"body\":{\"exitCode\":$EXPECTED_EXIT_CODE}" >/dev/null
assert_frame_lengths "$output"
