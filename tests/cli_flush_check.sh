#!/bin/sh
set -eu

CLI=$1
POLL_ATTEMPTS=40
POLL_INTERVAL_SECONDS=0.05
case_dir=$(mktemp -d "${TMPDIR:-/tmp}/elisa-cli-flush.XXXXXX")
cli_pid=

cleanup() {
    if [ -n "$cli_pid" ]; then
        kill "$cli_pid" 2>/dev/null || true
    fi
    rm -rf "$case_dir"
}

trap cleanup 0 HUP INT TERM
mkfifo "$case_dir/stdin"
: > "$case_dir/stdout"
"$CLI" < "$case_dir/stdin" > "$case_dir/stdout" &
cli_pid=$!
exec 3> "$case_dir/stdin"
printf 'launch\n' >&3

response_ready=0
poll_attempt=0
while [ "$poll_attempt" -lt "$POLL_ATTEMPTS" ]; do
    if grep -Fq 'ok generation=' "$case_dir/stdout"; then
        response_ready=1
        break
    fi
    poll_attempt=$((poll_attempt + 1))
    sleep "$POLL_INTERVAL_SECONDS"
done

exec 3>&-
wait "$cli_pid"
cli_pid=
if [ "$response_ready" -ne 1 ]; then
    printf 'CLI did not flush its response before stdin closed\n' >&2
    cat "$case_dir/stdout" >&2
    exit 1
fi
