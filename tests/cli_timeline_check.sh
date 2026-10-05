#!/bin/sh
set -eu

CLI=$1
INITIAL_EVENT_INDEX=0
STALE_SEEK_TARGET_EVENT=1
STALE_STOP_GENERATION=2
EXPECTED_AFTER_STEP='timeline stopGeneration=2 event=1 branch=0 retained=available[0,1] exact=available[0,1] canSeek=true canReverse=true reason=ready'
EXPECTED_AFTER_SEEK='timeline stopGeneration=3 event=0 branch=0 retained=available[0,1] exact=available[0,1] canSeek=true canReverse=false reason=ready'
EXPECTED_STALE_ERROR='error code=3 detail=2'
output=$(printf 'run\npause\nstep\ntimeline\nseek %s %s\ntimeline\nseek %s %s\ntimeline\n' "$INITIAL_EVENT_INDEX" "$STALE_STOP_GENERATION" "$STALE_SEEK_TARGET_EVENT" "$STALE_STOP_GENERATION" | "$CLI")
printf '%s\n' "$output" | grep -F "$EXPECTED_AFTER_STEP" >/dev/null
test "$(printf '%s\n' "$output" | grep -F -c "$EXPECTED_AFTER_SEEK")" -eq 2
printf '%s\n' "$output" | grep -F "$EXPECTED_STALE_ERROR" >/dev/null
