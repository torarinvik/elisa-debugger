#!/bin/sh
set -eu

cli=${1:?expected CLI path}
fixture=${2:?expected compiler-produced image}
trace=build/dap-trace-effects.eltr
image='build/cli effect image.edir'
corrupt='build/cli invalid image.edir'
exported='build/cli effect replay.eltr'

cp "$fixture" "$image"
printf 'invalid EDIR' > "$corrupt"
original=$(cksum < "$trace")
output=$({
    # All three failures must leave the fresh session usable for launch.
    printf 'launch build/missing-cli-image.edir\nlaunch %s\nopenTrace 0 %s\n' "$corrupt" "$trace"
    printf 'run %s\npause\nopenTrace 0 %s\n' "$image" "$trace"
    # A later launch must preserve the loaded replay and its stop position.
    printf 'launch %s\ntimeline\nstep\ncontinue\nstack\ntimeline\n' "$corrupt"
    printf 'seek 0\nstep\nseek 59\nreverseStep\ntimeline\nseek 0\nsaveTrace %s\n' "$exported"
} | "$cli")
test "$(printf '%s\n' "$output" | grep -c '^error code=')" -eq 4
for expected in \
    'opened trace event=0 generation=' \
    'event=0 branch=0 retained=available[0,59] exact=available[0,59]' \
    'event=59 branch=0 retained=available[0,59] exact=available[0,59]' \
    'event=58 branch=0 retained=available[0,59] exact=available[0,59]' \
    'result=-1 returnDepth=0' \
    'saved trace bytes='; do
    printf '%s\n' "$output" | grep -F "$expected" > /dev/null || {
        printf '%s\n' "$output" >&2
        exit 1
    }
done
test "$(cksum < "$exported")" = "$original"
test "$(cksum < "$trace")" = "$original"
