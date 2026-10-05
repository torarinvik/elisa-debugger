#!/bin/sh
set -eu

CLI=$1
output=$(printf 'run\npause\ntimeline\n' | "$CLI")
printf '%s\n' "$output" | grep -F 'timeline stopGeneration=1 event=0 branch=0 retained=available[0,0] exact=available[0,0] canSeek=false canReverse=false reason=at-boundary' >/dev/null
