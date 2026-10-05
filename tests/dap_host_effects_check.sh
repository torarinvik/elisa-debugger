#!/bin/sh
set -eu

server=${1:?expected DAP server path}
fixture=${2:?expected compiler-produced host-effect EDIR path}
input_fixture=${3:?expected compiler-produced console-input EDIR path}

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
readonly STEP_INITIALIZE_SEQUENCE=1
readonly STEP_LAUNCH_SEQUENCE=2
readonly STEP_CONFIGURATION_DONE_SEQUENCE=3
readonly STEP_PAUSE_SEQUENCE=4
readonly STEP_EFFECT_SEQUENCE=5
readonly STEP_REPLY_SEQUENCE=6
readonly STEP_CLOCK_VALUE_HIGH=0
readonly STEP_CLOCK_VALUE_LOW=3
readonly STEP_INPUT_VALUE_HIGH=0
readonly STEP_INPUT_VALUE_LOW=66
readonly INPUT_INITIALIZE_SEQUENCE=20
readonly INPUT_LAUNCH_SEQUENCE=21
readonly INPUT_CONFIGURATION_SEQUENCE=22
readonly INPUT_CONTINUE_SEQUENCE=23
readonly INPUT_INVALID_REPLY_SEQUENCE=24
readonly INPUT_REPLY_SEQUENCE=25
readonly INPUT_COMPLETION_SEQUENCE=26
readonly INPUT_BYTE_HIGH=0
readonly INPUT_BYTE_LOW=65
readonly INPUT_INVALID_BYTE_LOW=256
readonly INPUT_EOF_HIGH=4294967295
readonly INPUT_EOF_LOW=4294967295
readonly INPUT_BYTE_EXIT_CODE=65
readonly INPUT_EOF_EXIT_CODE=-1

frame() {
    payload=$1
    payload_length=$(printf '%s' "$payload" | wc -c | tr -d ' ')
    printf 'Content-Length: %s\r\n\r\n%s' "$payload_length" "$payload"
}

assert_frame_lengths() {
    frame_output=$1
    if ! printf '%s' "$frame_output" |
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
        printf '%s\n' "$frame_output" >&2
        exit 1
    fi
}

check_step_host_effect() {
    step_command=$1
    step_initialize_payload=$(printf '{"seq":%s,"type":"request","command":"initialize"}' "$STEP_INITIALIZE_SEQUENCE")
    step_launch_payload=$(printf '{"seq":%s,"type":"request","command":"launch","arguments":{"program":"%s"}}' "$STEP_LAUNCH_SEQUENCE" "$fixture")
    step_configuration_payload=$(printf '{"seq":%s,"type":"request","command":"configurationDone"}' "$STEP_CONFIGURATION_DONE_SEQUENCE")
    step_pause_payload=$(printf '{"seq":%s,"type":"request","command":"pause"}' "$STEP_PAUSE_SEQUENCE")
    step_effect_payload=$(printf '{"seq":%s,"type":"request","command":"%s"}' "$STEP_EFFECT_SEQUENCE" "$step_command")
    step_reply_payload=$(printf '{"seq":%s,"type":"request","command":"elisa/provideHostEffect","arguments":{"requestId":%s,"valueHigh":%s,"valueLow":%s}}' "$STEP_REPLY_SEQUENCE" "$STEP_EFFECT_SEQUENCE" "$STEP_CLOCK_VALUE_HIGH" "$STEP_CLOCK_VALUE_LOW")
    step_input="$(frame "$step_initialize_payload")"
    step_input="${step_input}$(frame "$step_launch_payload")"
    step_input="${step_input}$(frame "$step_configuration_payload")"
    step_input="${step_input}$(frame "$step_pause_payload")"
    step_input="${step_input}$(frame "$step_effect_payload")"
    step_input="${step_input}$(frame "$step_reply_payload")"
    step_output=$(printf '%s' "$step_input" | "$server")
    printf '%s\n' "$step_output" | grep -F "\"request_seq\":$STEP_EFFECT_SEQUENCE,\"command\":\"$step_command\",\"success\":true,\"body\":{\"allThreadsContinued\":false" | grep -F "\"requestId\":$STEP_EFFECT_SEQUENCE,\"kind\":\"clockNow\"" >/dev/null
    printf '%s\n' "$step_output" | grep -F '"command":"elisa/provideHostEffect","success":true' >/dev/null
    assert_frame_lengths "$step_output"
}

check_step_console_input() {
    step_command=$1
    step_initialize=$(printf '{"seq":%s,"type":"request","command":"initialize"}' "$STEP_INITIALIZE_SEQUENCE")
    step_launch=$(printf '{"seq":%s,"type":"request","command":"launch","arguments":{"program":"%s"}}' "$STEP_LAUNCH_SEQUENCE" "$input_fixture")
    step_configuration=$(printf '{"seq":%s,"type":"request","command":"configurationDone"}' "$STEP_CONFIGURATION_DONE_SEQUENCE")
    step_pause=$(printf '{"seq":%s,"type":"request","command":"pause"}' "$STEP_PAUSE_SEQUENCE")
    step_effect=$(printf '{"seq":%s,"type":"request","command":"%s"}' "$STEP_EFFECT_SEQUENCE" "$step_command")
    step_reply=$(printf '{"seq":%s,"type":"request","command":"elisa/provideHostEffect","arguments":{"requestId":%s,"valueHigh":%s,"valueLow":%s}}' "$STEP_REPLY_SEQUENCE" "$STEP_EFFECT_SEQUENCE" "$STEP_INPUT_VALUE_HIGH" "$STEP_INPUT_VALUE_LOW")
    step_input="$(frame "$step_initialize")$(frame "$step_launch")$(frame "$step_configuration")$(frame "$step_pause")$(frame "$step_effect")$(frame "$step_reply")"
    step_output=$(printf '%s' "$step_input" | "$server")
    printf '%s\n' "$step_output" | grep -F "\"request_seq\":$STEP_EFFECT_SEQUENCE,\"command\":\"$step_command\",\"success\":true,\"body\":{\"allThreadsContinued\":false" | grep -F "\"requestId\":$STEP_EFFECT_SEQUENCE,\"kind\":\"consoleInput\"" | grep -F '"requested":1' >/dev/null
    printf '%s\n' "$step_output" | grep -F '"command":"elisa/provideHostEffect","success":true' >/dev/null
    assert_frame_lengths "$step_output"
}

check_console_input() {
    input_high=$1
    input_low=$2
    expected_exit_code=$3
    include_invalid_reply=$4
    initialize=$(printf '{"seq":%s,"type":"request","command":"initialize"}' "$INPUT_INITIALIZE_SEQUENCE")
    launch=$(printf '{"seq":%s,"type":"request","command":"launch","arguments":{"program":"%s"}}' "$INPUT_LAUNCH_SEQUENCE" "$input_fixture")
    configuration=$(printf '{"seq":%s,"type":"request","command":"configurationDone"}' "$INPUT_CONFIGURATION_SEQUENCE")
    continue_for_input=$(printf '{"seq":%s,"type":"request","command":"continue"}' "$INPUT_CONTINUE_SEQUENCE")
    invalid_reply=$(printf '{"seq":%s,"type":"request","command":"elisa/provideHostEffect","arguments":{"requestId":%s,"valueHigh":%s,"valueLow":%s}}' "$INPUT_INVALID_REPLY_SEQUENCE" "$INPUT_CONTINUE_SEQUENCE" "$INPUT_BYTE_HIGH" "$INPUT_INVALID_BYTE_LOW")
    reply=$(printf '{"seq":%s,"type":"request","command":"elisa/provideHostEffect","arguments":{"requestId":%s,"valueHigh":%s,"valueLow":%s}}' "$INPUT_REPLY_SEQUENCE" "$INPUT_CONTINUE_SEQUENCE" "$input_high" "$input_low")
    completion=$(printf '{"seq":%s,"type":"request","command":"continue"}' "$INPUT_COMPLETION_SEQUENCE")
    input_stream="$(frame "$initialize")$(frame "$launch")$(frame "$configuration")$(frame "$continue_for_input")"
    if [ "$include_invalid_reply" = true ]; then
        input_stream="${input_stream}$(frame "$invalid_reply")"
    fi
    input_stream="${input_stream}$(frame "$reply")$(frame "$completion")"
    input_output=$(printf '%s' "$input_stream" | "$server")
    printf '%s\n' "$input_output" | grep -F '"kind":"consoleInput"' | grep -F '"requested":1' >/dev/null
    if [ "$include_invalid_reply" = true ]; then
        printf '%s\n' "$input_output" | grep -F '"command":"elisa/provideHostEffect","success":false' >/dev/null
    fi
    printf '%s\n' "$input_output" | grep -F '"command":"elisa/provideHostEffect","success":true' >/dev/null
    printf '%s\n' "$input_output" | grep -F "\"event\":\"exited\",\"body\":{\"exitCode\":$expected_exit_code}" >/dev/null
    assert_frame_lengths "$input_output"
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
assert_frame_lengths "$output"
check_step_host_effect "next"
check_step_host_effect "stepIn"
check_step_host_effect "stepOut"
check_step_console_input "next"
check_step_console_input "stepIn"
check_step_console_input "stepOut"
check_console_input "$INPUT_BYTE_HIGH" "$INPUT_BYTE_LOW" "$INPUT_BYTE_EXIT_CODE" true
check_console_input "$INPUT_EOF_HIGH" "$INPUT_EOF_LOW" "$INPUT_EOF_EXIT_CODE" false
