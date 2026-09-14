# Compiler integration boundary

This records the compiler dependency and the narrow compiler-to-debugger seam
observed on 2026-09-14. It is a compatibility record, not a claim that arbitrary
Elisa programs can be compiled to EDIR.

## Compiler revision

The adjacent `../Elisa-compiler` checkout was clean at
`9791a8e1cd924bb03e43cb46da2d3530b4c9fbb0` on `main` (also referenced by
`codex/wasm-sdk`). Its checked-in source lists `edir` in
`cli_emit_mode_supported`, and includes the bounded EDIR emitter. The emitter's
initial implementation was introduced by `91d63d51e91e382bdfbfc3ed1e73455dcf9d29a5`,
which is an ancestor of the current revision.

The adjacent stage1 product is stale relative to the current compiler source.
On 2026-09-14 the strict EDIR emit command below exited with status 2 and named
`src/driver/elisac.elisa` as newer than `bin/elisac-stage1`. Do not set
`ELISA_ALLOW_STALE_STAGE1=1` for integration qualification: it only bypasses
the freshness check and does not prove the product matches this revision. Seed
or rebuild stage1 from the pinned clean source revision before claiming a fresh
artifact build. Keep that build and any compiler changes in an isolated
compiler worktree.

The wrapper `scripts/elisac_stage1.sh` rejects a product binary older than any
compiler `.elisa` or `.elisai` source. The guard is timestamp based, not a Git
revision check. Keep `ELISA_ALLOW_STALE_STAGE1=0` for integration checks; setting
it to `1` only bypasses freshness validation and does not establish that the
product matches the source revision.

## Verified emit command

From this debugger repository, with `COMPILER_ROOT` set to a clean checkout at
the pinned revision above, this command emitted a 419-byte schema-2 artifact
with stale-product rejection enabled:

```sh
COMPILER_ROOT=/path/to/clean/Elisa-compiler
ELISA_EDIR_SOURCE_ROOT="$PWD" ELISA_ALLOW_STALE_STAGE1=0 \
  "$COMPILER_ROOT/scripts/elisac_stage1.sh" \
  -emit edir -O0 -o build/compiler_edir_arithmetic.edir \
  tests/compiler_edir_arithmetic_fixture.elisa
```

Historical evidence from 2026-09-13: the exact compiler invocation was exercised
against revision `91d63d51e91e382bdfbfc3ed1e73455dcf9d29a5`; the artifact
header reported codec schema 2, program version 1, five instructions, and one
local. That revision is an ancestor of the current compiler source, but this
does not replace rebuilding and rerunning the command against the current
stage1 product. To run the repository's broader arithmetic/native parity
check after rebuilding, use:

```sh
make compiler-edir-check \
  ELISA_EDIR_COMPILER="$COMPILER_ROOT/scripts/elisac_stage1.sh" \
  ELISA_EDIR_ALLOW_STALE_STAGE1=0
```

`make compiler-edir-loop-check` exercises the counted-loop EDIR artifact,
source breakpoints, and reverse stepping. Those Make targets are separate from
the ordinary smoke suite because they require this compiler branch. The direct
emit command was verified for this record; the full Make targets are not thereby
claimed as passing.

## Supported boundary and current limits

The compiler's `-emit edir` mode accepts only one top-level, undecorated,
effect-free `def main() -> i64` with no parameters. Its body may return an
integer literal, supported literal arithmetic, one explicitly typed `i64`
local followed by a supported return, or the emitter's bounded counted-loop
shape. It rejects other syntax and semantics instead of silently producing a
partial artifact. Includes, static-generated source maps, multiple source
files, general functions and calls, general control flow, effects, and arbitrary
native programs are outside this slice.

The seam is the portable EDIR v2 byte format in [the EDIR specification](../spec/edir-format.md):
the compiler emits a verified-format artifact with source identity and spans;
the Elisa debugger decodes and verifies it before managed execution. A relative
input source path becomes the artifact's logical path. For absolute source
paths, `ELISA_EDIR_SOURCE_ROOT` must identify the root to strip; the editor then
uses the corresponding `sourcePathRoot` launch mapping when sending absolute
paths to DAP. EDIR input is not a native executable, so this slice does not
provide reverse execution for compiler-produced native executables or ship and
qualify IDE plugins.

Editor hosts connect through the debugger's documented DAP or headless process
interfaces; they must not depend on compiler internals or duplicate execution
semantics. See the [editor integration guide](integration.md) and
[plugin-author contract](../spec/plugin-integration.md) for those transports.
