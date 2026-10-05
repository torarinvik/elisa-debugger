#!/bin/sh
set -eu

CLI=$1
INITIAL_EVENT_INDEX=0
EXPECTED_AFTER_STEP='timeline stopGeneration=2 event=1 branch=0 retained=available[0,1] exact=available[0,1] canSeek=true canReverse=true reason=ready'
EXPECTED_AFTER_SEEK='timeline stopGeneration=3 event=0 branch=0 retained=available[0,1] exact=available[0,1] canSeek=true canReverse=false reason=ready'
output=$(printf 'run\npause\nstep\ntimeline\nseek %s\ntimeline\n' "$INITIAL_EVENT_INDEX" | "$CLI")
printf '%s\n' "$output" | grep -F "$EXPECTED_AFTER_STEP" >/dev/null
printf '%s\n' "$output" | grep -F "$EXPECTED_AFTER_SEEK" >/dev/null
