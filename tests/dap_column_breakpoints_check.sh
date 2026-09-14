#!/bin/sh
set -eu

fixture_writer=${1:?expected Elisa EDIR fixture writer}
transcript_driver=${2:?expected Elisa DAP transcript driver}
server=${3:?expected DAP server path}

"$fixture_writer" > build/dap-column-fixture.edir
"$transcript_driver" --default-input | "$server" > build/dap-column-response.jsonl
"$transcript_driver" --check-default
"$transcript_driver" --zero-based-input | "$server" > build/dap-column-response.jsonl
"$transcript_driver" --check-zero-based
