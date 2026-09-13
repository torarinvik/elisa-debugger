# Compiler integration boundary

This records the compiler dependency and the narrow compiler-to-debugger seam
observed on 2026-09-13. It is a compatibility record, not a claim that arbitrary
Elisa programs can be compiled to EDIR.

## Compiler revision

The adjacent `../Elisa-compiler` checkout is on
`da64c5103228721385466e894b864c886584821e` (`fix/stage0-parity-try-regions-privacy`)
and has 22 modified or untracked paths. Its checked-in stage1 driver does not
list `edir` in `cli_emit_mode_supported`; this checkout cannot produce EDIR.
The debugger Makefile's default `ELISA_EDIR_COMPILER` points at that adjacent
checkout, so compiler integration targets must be given an EDIR-capable compiler
explicitly.

The compatible compiler source observed in this workspace is the clean local
revision `91d63d51e91e382bdfbfc3ed1e73455dcf9d29a5` on branch
`codex/debugger-edir` in the Elisa-compiler repository. That commit adds bounded
counted-loop EDIR emission. It is currently a local commit without a remote
branch or release tag; projects and CI need to make this exact source revision
available before treating it as a reproducible external dependency. Build or
seed its stage1 product from that revision, and keep the worktree clean for
integration validation.

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

The exact compiler invocation was exercised against revision
`91d63d51e91e382bdfbfc3ed1e73455dcf9d29a5`; the artifact header reported codec
schema 2, program version 1, five instructions, and one local. To run the
repository's broader arithmetic/native parity check, use:

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
