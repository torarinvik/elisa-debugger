#!/bin/sh
set -eu

SESSION_SERVER=$1
DAP_SERVER=$2
POLL_ATTEMPTS=40
POLL_INTERVAL_SECONDS=0.05

check_server_flush() {
    server_name=$1
    server_path=$2
    request_frame=$3
    expected_response=$4
    case_dir=$(mktemp -d "${TMPDIR:-/tmp}/elisa-server-flush.XXXXXX")
    mkfifo "$case_dir/stdin"
    : > "$case_dir/stdout"
    "$server_path" < "$case_dir/stdin" > "$case_dir/stdout" &
    server_pid=$!
    exec 3> "$case_dir/stdin"
    printf '%b' "$request_frame" >&3

    response_ready=0
    poll_attempt=0
    while [ "$poll_attempt" -lt "$POLL_ATTEMPTS" ]; do
        if grep -Fq "$expected_response" "$case_dir/stdout"; then
            response_ready=1
            break
        fi
        poll_attempt=$((poll_attempt + 1))
        sleep "$POLL_INTERVAL_SECONDS"
    done

    exec 3>&-
    wait "$server_pid"
    if [ "$response_ready" -ne 1 ]; then
        printf '%s did not flush its response before stdin closed\n' "$server_name" >&2
        cat "$case_dir/stdout" >&2
        rm -rf "$case_dir"
        return 1
    fi
    rm -rf "$case_dir"
}

check_server_flush \
    'session server' \
    "$SESSION_SERVER" \
    '30 {"method":"initialize","id":1}\n' \
    '"id":"1"'
check_server_flush \
    'DAP server' \
    "$DAP_SERVER" \
    'Content-Length: 49\r\n\r\n{"seq":1,"type":"request","command":"initialize"}' \
    '"command":"initialize","success":true'
