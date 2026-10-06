#!/bin/sh
set -eu

check=${1:?expected managed trace effects executable}
input=build/trace-effects-host.bin
trace=build/trace-effects.eltr
reference=build/trace-effects.reference
trap 'rm -f "$input"' EXIT HUP INT TERM

printf A > "$input"
record_output=$("$check" record)
test -z "$record_output"
original_trace=$(cksum "$trace")
original_reference=$(cksum "$reference")

# Fresh processes must use the captured initial image and results. They have
# no host-effect callback and may not redisplay recorded target output.
printf Z > "$input"
changed_input_output=$("$check" replay)
test -z "$changed_input_output"
rm "$input"
missing_input_output=$("$check" replay)
test -z "$missing_input_output"
"$check" tamper
test "$(cksum "$trace")" = "$original_trace"
test "$(cksum "$reference")" = "$original_reference"
