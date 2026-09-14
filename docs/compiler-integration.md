# Compiler integration boundary

This records the compiler dependency and the narrow compiler-to-debugger seam
observed on 2026-09-14. It is a compatibility record, not a claim that arbitrary
Elisa programs can be compiled to EDIR.

## Compiler revision

On 2026-09-14 the adjacent `../Elisa-compiler` checkout was clean on `main` at
`fd2cb3cff470319500db362e5fce2833cbe300de` (`fd2cb3cf`), exactly matching
`origin/main`. This is the compiler revision for the checks below. The checked-in
source includes the bounded EDIR emitter and lists `edir` in
`cli_emit_mode_supported`.

The wrapper `scripts/elisac_stage1.sh` rejects a product binary older than any
compiler `.elisa` or `.elisai` source. The guard is timestamp based, not a Git
revision check. Keep `ELISA_ALLOW_STALE_STAGE1=0` for integration checks; setting
it to `1` only bypasses freshness validation and does not establish that the
product matches the source revision. To reproduce the revision assertion as
well as the wrapper's freshness guard, check that the compiler checkout is clean
at the revision above, then use the commands below. Rebuild its stage1 product
from that checkout with the compiler's documented seed flow if the wrapper
reports stale; do not bypass the guard to qualify an artifact.

## Strict-freshness build and test path

From this debugger repository, set `COMPILER_ROOT` to the clean compiler
checkout at the revision above. This direct command checks the stage1 product's
timestamp freshness and emits the arithmetic fixture as EDIR:

```sh
COMPILER_ROOT="$(cd ../Elisa-compiler && pwd)"
test "$(git -C "$COMPILER_ROOT" rev-parse HEAD)" = \
  fd2cb3cff470319500db362e5fce2833cbe300de
test -z "$(git -C "$COMPILER_ROOT" status --porcelain)"
mkdir -p build
ELISA_EDIR_SOURCE_ROOT="$PWD" ELISA_ALLOW_STALE_STAGE1=0 \
  "$COMPILER_ROOT/scripts/elisac_stage1.sh" \
  -emit edir -O0 -o build/compiler_edir_arithmetic.edir \
  tests/compiler_edir_arithmetic_fixture.elisa
```

For the reproducible debugger/compiler integration gate, run the focused Make
targets with stale-product rejection explicitly kept on:

```sh
make compiler-edir-check compiler-edir-loop-check compiler-edir-calls-check \
  ELISA_EDIR_COMPILER="$COMPILER_ROOT/scripts/elisac_stage1.sh" \
  ELISA_EDIR_ALLOW_STALE_STAGE1=0
```

These targets compile EDIR and native fixtures, check debugger execution and DAP
inspection, and cover counted-loop breakpoints/reverse stepping and function
calls. They are separate from the ordinary smoke suite because they require
the compiler's `-emit edir` mode. The command is a reproducible test path, not a
claim that all three targets have passed on every checkout.

## Compiler optimization distinction

Current stage1 documents default-on, conservative source-level memory lowering
for proven local `darray[i64]` patterns: helper scratch reuse, capacity-based
reserve inference, and bounded stack placement. Its separate LLVM optimization
pipeline runs `default<O1>`, `default<O2>`, or `default<O3>` when those levels are
requested; `-O0` skips that LLVM pipeline. The memory lowering and LLVM pass
pipeline are distinct mechanisms. The EDIR integration targets intentionally
use `-O0`; their success does not qualify LLVM optimization or the native memory
optimizations. For work that changes native LLVM lowering, run the compiler's
`test/parity/opt_pipeline_smoke.sh` and `test/parity/memory_speed_smoke.sh` in
the compiler checkout as appropriate; use its memory benchmark only when making
a performance claim. See the compiler's
[memory optimization notes](../../Elisa-compiler/docs/memory-speed-automation.md)
and [optimization-level notes](../../Elisa-compiler/docs/stage1_scope.md).

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
