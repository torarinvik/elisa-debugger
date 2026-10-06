#!/bin/sh
set -eu

cli=${1:?expected CLI path}
fixture=${2:?expected compiler-produced image}
trace=${3:-build/dap-trace-effects.eltr}
last_event=${4:-59}
previous_event=$((last_event - 1))
prefix=${5:-effect}
image="build/cli $prefix image.edir"
corrupt="build/cli $prefix invalid image.edir"
exported="build/cli $prefix replay.eltr"

cp "$fixture" "$image"
printf 'invalid EDIR' > "$corrupt"
original=$(cksum < "$trace")
output=$({
    # All three failures must leave the fresh session usable for launch.
    printf 'launch build/missing-cli-image.edir\nlaunch %s\nopenTrace 0 %s\n' "$corrupt" "$trace"
    printf 'run %s\npause\nopenTrace 0 %s\n' "$image" "$trace"
    # A later launch must preserve the loaded replay and its stop position.
    printf 'launch %s\ntimeline\nstep\ncontinue\nstack\ntimeline\n' "$corrupt"
    printf 'seek 0\nstep\nseek %s\nreverseStep\ntimeline\nseek 0\nsaveTrace %s\n' "$last_event" "$exported"
} | "$cli")
test "$(printf '%s\n' "$output" | grep -c '^error code=')" -eq 4
for expected in \
    'opened trace event=0 generation=' \
    "event=0 branch=0 retained=available[0,$last_event] exact=available[0,$last_event]" \
    "event=$last_event branch=0 retained=available[0,$last_event] exact=available[0,$last_event]" \
    "event=$previous_event branch=0 retained=available[0,$last_event] exact=available[0,$last_event]" \
    'result=-1 returnDepth=0' \
    'saved trace bytes='; do
    printf '%s\n' "$output" | grep -F "$expected" > /dev/null || {
        printf '%s\n' "$output" >&2
        exit 1
    }
done
test "$(cksum < "$exported")" = "$original"
test "$(cksum < "$trace")" = "$original"
