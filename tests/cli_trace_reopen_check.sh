#!/bin/sh
set -eu

cli_path=$1
trace_path="build/cli trace restart.eltr"

recorded=$(printf 'run\npause\nstep\nsaveTrace %s\n' "$trace_path" | "$cli_path")
printf '%s\n' "$recorded" | grep -F 'saved trace bytes='

reopened=$(printf 'openTrace 1 %s\ntimeline\n' "$trace_path" | "$cli_path")
printf '%s\n' "$reopened" | grep -F 'opened trace event=1 generation='
printf '%s\n' "$reopened" | grep -E 'timeline .*event=1 .*exact=available\[0,1\]'

history=$(printf 'openTrace 0 %s\ntimeline\nseek 1\ntimeline\n' "$trace_path" | "$cli_path")
printf '%s\n' "$history" | grep -F 'opened trace event=0 generation='
printf '%s\n' "$history" | grep -E 'timeline .*event=0 .*exact=available\[0,1\]'
printf '%s\n' "$history" | grep -E 'timeline .*event=1 .*exact=available\[0,1\]'
