#!/bin/sh
set -eu

server=${1:?expected DAP server path}
fixture=${2:?expected compiler-produced host-effect EDIR path}

readonly INITIALIZE_SEQUENCE=1
readonly LAUNCH_SEQUENCE=2
readonly CONFIGURATION_DONE_SEQUENCE=3
readonly CLOCK_CONTINUE_SEQUENCE=4
readonly MISMATCHED_CLOCK_REPLY_SEQUENCE=5
readonly CLOCK_REPLY_SEQUENCE=6
readonly RANDOM_CONTINUE_SEQUENCE=7
readonly RANDOM_REPLY_SEQUENCE=8
readonly OUTPUT_CONTINUE_SEQUENCE=9
readonly OUTPUT_REPLY_SEQUENCE=10
readonly COMPLETION_CONTINUE_SEQUENCE=11
readonly CLOCK_VALUE_HIGH=0
readonly CLOCK_VALUE_LOW=3
readonly RANDOM_VALUE_HIGH=0
readonly RANDOM_VALUE_LOW=13
readonly UNMATCHED_PROVIDER_REQUEST_ID=99
readonly CONSOLE_OUTPUT_BYTE=67
readonly EXPECTED_EXIT_CODE=1
readonly HOST_EFFECT_EXTENSION_VERSION=1

frame() {
    payload=$1
    payload_length=$(printf '%s' "$payload" | wc -c | tr -d ' ')
    printf 'Content-Length: %s\r\n\r\n%s' "$payload_length" "$payload"
}

initialize_payload=$(printf '{"seq":%s,"type":"request","command":"initialize"}' "$INITIALIZE_SEQUENCE")
launch_payload=$(printf '{"seq":%s,"type":"request","command":"launch","arguments":{"program":"%s"}}' "$LAUNCH_SEQUENCE" "$fixture")
configuration_done_payload=$(printf '{"seq":%s,"type":"request","command":"configurationDone"}' "$CONFIGURATION_DONE_SEQUENCE")
clock_continue_payload=$(printf '{"seq":%s,"type":"request","command":"continue"}' "$CLOCK_CONTINUE_SEQUENCE")
clock_mismatch_reply_payload=$(printf '{"seq":%s,"type":"request","command":"elisa/provideHostEffect","arguments":{"requestId":%s,"valueHigh":%s,"valueLow":%s}}' "$MISMATCHED_CLOCK_REPLY_SEQUENCE" "$UNMATCHED_PROVIDER_REQUEST_ID" "$CLOCK_VALUE_HIGH" "$CLOCK_VALUE_LOW")
clock_reply_payload=$(printf '{"seq":%s,"type":"request","command":"elisa/provideHostEffect","arguments":{"requestId":%s,"valueHigh":%s,"valueLow":%s}}' "$CLOCK_REPLY_SEQUENCE" "$CLOCK_CONTINUE_SEQUENCE" "$CLOCK_VALUE_HIGH" "$CLOCK_VALUE_LOW")
random_continue_payload=$(printf '{"seq":%s,"type":"request","command":"continue"}' "$RANDOM_CONTINUE_SEQUENCE")
random_reply_payload=$(printf '{"seq":%s,"type":"request","command":"elisa/provideHostEffect","arguments":{"requestId":%s,"valueHigh":%s,"valueLow":%s}}' "$RANDOM_REPLY_SEQUENCE" "$RANDOM_CONTINUE_SEQUENCE" "$RANDOM_VALUE_HIGH" "$RANDOM_VALUE_LOW")
output_continue_payload=$(printf '{"seq":%s,"type":"request","command":"continue"}' "$OUTPUT_CONTINUE_SEQUENCE")
output_reply_payload=$(printf '{"seq":%s,"type":"request","command":"elisa/provideHostEffect","arguments":{"requestId":%s}}' "$OUTPUT_REPLY_SEQUENCE" "$OUTPUT_CONTINUE_SEQUENCE")
completion_continue_payload=$(printf '{"seq":%s,"type":"request","command":"continue"}' "$COMPLETION_CONTINUE_SEQUENCE")

input="$(frame "$initialize_payload")"
input="${input}$(frame "$launch_payload")"
input="${input}$(frame "$configuration_done_payload")"
input="${input}$(frame "$clock_continue_payload")"
input="${input}$(frame "$clock_mismatch_reply_payload")"
input="${input}$(frame "$clock_reply_payload")"
input="${input}$(frame "$random_continue_payload")"
input="${input}$(frame "$random_reply_payload")"
input="${input}$(frame "$output_continue_payload")"
input="${input}$(frame "$output_reply_payload")"
input="${input}$(frame "$completion_continue_payload")"

output=$(printf '%s' "$input" | "$server")
printf '%s\n' "$output" | grep -F "\"supportsElisaHostEffects\":true,\"elisaHostEffectsVersion\":$HOST_EFFECT_EXTENSION_VERSION" >/dev/null
printf '%s\n' "$output" | grep -F '"requestId":4,"kind":"clockNow"' >/dev/null
printf '%s\n' "$output" | grep -F '"requestId":7,"kind":"randomU64"' >/dev/null
printf '%s\n' "$output" | grep -F '"requestId":9,"kind":"consoleOutput"' | grep -F "\"payload\":$CONSOLE_OUTPUT_BYTE" >/dev/null
printf '%s\n' "$output" | grep -F '"command":"elisa/provideHostEffect","success":true' >/dev/null
printf '%s\n' "$output" | grep -F '"command":"elisa/provideHostEffect","success":false,"message":"host-effect reply does not match the pending request"' >/dev/null
printf '%s\n' "$output" | grep -F '"event":"terminated"' >/dev/null
printf '%s\n' "$output" | grep -F "\"event\":\"exited\",\"body\":{\"exitCode\":$EXPECTED_EXIT_CODE}" >/dev/null

if ! printf '%s' "$output" |
    sed 's/}Content-Length:/}\
Content-Length:/g' |
    tr '\015' '\012' |
    awk '
        /^Content-Length: / { expected_bytes = $2; next }
        /^\{/ {
            if (expected_bytes == "" || length($0) != expected_bytes) {
                print "DAP frame Content-Length does not match its response body: expected " expected_bytes ", received " length($0) > "/dev/stderr"
                exit 1
            }
            frame_count++
            expected_bytes = ""
        }
        END {
            if (frame_count == 0 || expected_bytes != "") {
                print "DAP host-effect response stream contains an incomplete frame" > "/dev/stderr"
                exit 1
            }
        }
    '; then
    printf '%s\n' "$output" >&2
    exit 1
fi
