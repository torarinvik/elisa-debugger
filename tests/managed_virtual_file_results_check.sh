#!/bin/sh
set -eu

check=${1:?expected managed virtual-file mutation executable}
input=build/file-results-host.bin
trace=build/file-results.eltr
reference=build/file-results.reference
trap 'rm -f "$input"' EXIT HUP INT TERM

printf A > "$input"
record_output=$("$check" record)
test -z "$record_output"
test "$(cat "$input")" = A
original_trace=$(cksum "$trace")
original_reference=$(cksum "$reference")

# Fresh processes must use the captured initial image and results. They have
# no host-effect callback and never write to the original host file.
printf Z > "$input"
changed_input_output=$("$check" replay)
test -z "$changed_input_output"
test "$(cat "$input")" = Z
rm "$input"
missing_input_output=$("$check" replay)
test -z "$missing_input_output"
test ! -e "$input"
"$check" tamper
test "$(cksum "$trace")" = "$original_trace"
test "$(cksum "$reference")" = "$original_reference"
