#!/bin/sh
set -eu

attach_check_binary=$1
attach_check_child_pid=
readonly ATTACH_CHECK_CHILD_RUNTIME_SECONDS=30

cleanup() {
    if [ -n "$attach_check_child_pid" ]; then
        kill -KILL "$attach_check_child_pid" >/dev/null 2>&1 || true
        wait "$attach_check_child_pid" >/dev/null 2>&1 || true
    fi
}

trap cleanup EXIT HUP INT TERM
/bin/sleep "$ATTACH_CHECK_CHILD_RUNTIME_SECONDS" &
attach_check_child_pid=$!
"$attach_check_binary" "$attach_check_child_pid"
