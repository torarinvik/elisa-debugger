# Compiler integration boundary

This records the compiler dependency and the narrow compiler-to-debugger seam
verified on 2026-09-15. It is a compatibility record, not a claim that arbitrary
Elisa programs can be compiled to EDIR.

## Compiler revision

On 2026-09-15, `origin/main` resolved to
`fd2cb3cff470319500db362e5fce2833cbe300de` (`fd2cb3cf`). The isolated debugger
integration worktree is pinned at
`8d7db0561d0f72c1f548fa6a73d071c86b2fe57f` (`8d7db056`), based on the current
shared typed-lowering and optimization head `0f08a3ca` and carrying the schema-3
EDIR function-call emitter. It adds the bounded EDIR emitter, schema-3 function
descriptors and calls, shared typed `ElisaCoreIR` scalar lowering consumed by
EDIR and native LLVM, and maps native DWARF locations back to original source
lines. The checks below use a clean worktree at the integration revision, a
stage1 product rebuilt from that worktree, and its matching runtime object.

The wrapper `scripts/elisac_stage1.sh` rejects a product binary older than any
compiler `.elisa` or `.elisai` source. The guard is timestamp based, not a Git
revision check. Keep `ELISA_ALLOW_STALE_STAGE1=0` for integration checks; setting
it to `1` only bypasses freshness validation and does not establish that the
product matches the source revision. To reproduce the revision assertion and
freshness guard, make a clean worktree at the integration revision and seed the
product from it:

```sh
COMPILER_SOURCE_ROOT="$(cd ../Elisa-compiler && pwd)"
COMPILER_ROOT="${COMPILER_SOURCE_ROOT}-debugger-integration"
git -C "$COMPILER_SOURCE_ROOT" worktree add --detach \
  "$COMPILER_ROOT" 8d7db0561d0f72c1f548fa6a73d071c86b2fe57f
test "$(git -C "$COMPILER_ROOT" rev-parse HEAD)" = \
  8d7db0561d0f72c1f548fa6a73d071c86b2fe57f
test -z "$(git -C "$COMPILER_ROOT" status --porcelain)"
# Set ELISACORE_BIN to the installed stage0 compiler if the wrapper cannot find it.
ELISA_ALLOW_STALE_STAGE1=0 \
  "$COMPILER_ROOT/scripts/elisac_stage1.sh" --seed
```

The seed flow also builds the runtime object from the same compiler source. Keep
that object paired with this stage1 product when building the debugger.

## Strict-freshness build and test path

From this debugger repository, keep `COMPILER_ROOT` set to the clean compiler
worktree above. This direct command checks the stage1 product's timestamp
freshness and emits the arithmetic fixture as EDIR:

```sh
COMPILER_ROOT="$(cd ../Elisa-compiler-debugger-integration && pwd)"
test "$(git -C "$COMPILER_ROOT" rev-parse HEAD)" = \
  8d7db0561d0f72c1f548fa6a73d071c86b2fe57f
test -z "$(git -C "$COMPILER_ROOT" status --porcelain)"
mkdir -p build
ELISA_EDIR_SOURCE_ROOT="$PWD" ELISA_ALLOW_STALE_STAGE1=0 \
  "$COMPILER_ROOT/scripts/elisac_stage1.sh" \
  -emit edir -O0 -o build/compiler_edir_arithmetic.edir \
  tests/compiler_edir_arithmetic_fixture.elisa
```

For the reproducible supported debugger/compiler integration gates, run the
focused Make targets with stale-product rejection explicitly kept on:

```sh
make compiler-edir-check compiler-edir-core-ir-check compiler-edir-loop-check \
  ELISA_COMPILER="$COMPILER_ROOT/scripts/elisac_stage1.sh" \
  ELISA_EDIR_COMPILER="$COMPILER_ROOT/scripts/elisac_stage1.sh" \
  ELISA_RUNTIME="$COMPILER_ROOT/build/runtime/elisacore_runtime.o" \
  ELISA_ALLOW_STALE_STAGE1=0 ELISA_EDIR_ALLOW_STALE_STAGE1=0
```

These targets compile EDIR and native fixtures, check shared lowering and
optimized native execution, inspect locals through DAP, and cover counted-loop
breakpoints and reverse stepping. They are separate from the ordinary smoke
suite because they require the compiler's `-emit edir` mode. Keep the strict
freshness settings: they prove that the product used by the checks includes the
pinned compiler source and its optimization pipeline.

The compiler's native backend smoke suite also contains a command-line `-g`
regression for function, parameter, local, and statement source lines. Run it
against the seeded compiler and its matching runtime with:

```sh
ELISACORE_BIN="$COMPILER_ROOT/bin/elisac-stage1" \
  "$COMPILER_ROOT/test/parity/backend_obj_smoke.sh"
```

The current compiler emits schema-3 EDIR function descriptors and direct calls
for the bounded recursive-call fixture. Run the positive integration check to
verify that the managed VM loads, verifies, and executes the function table,
while the optimized native backend executes the same recursive source with the
expected result:

```sh
make compiler-edir-calls-check \
  ELISA_COMPILER="$COMPILER_ROOT/scripts/elisac_stage1.sh" \
  ELISA_EDIR_COMPILER="$COMPILER_ROOT/scripts/elisac_stage1.sh" \
  ELISA_COMPILER_SOURCE_ROOT="$COMPILER_ROOT" \
  ELISA_RUNTIME="$COMPILER_ROOT/build/runtime/elisacore_runtime.o" \
  ELISA_ALLOW_STALE_STAGE1=0 \
  ELISA_EDIR_ALLOW_STALE_STAGE1=0
```

The compiler's schema-3 producer and the debugger's schema-3 codec/VM call
behavior are both covered by Elisa-authored checks. The fixture is deliberately
bounded; arbitrary source-level calls, closures, generics, and foreign calls
remain outside this integration contract.

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

At the pinned integration revision, `compiler-edir-core-ir-check` also compiles
the shared scalar fixture natively at `-O2` and checks its result against EDIR
and native `-O0`. This exercises the latest LLVM optimization pipeline on that
fixture; it does not exercise `darray[i64]` memory lowering or establish a
general optimized-program replay claim.

## Supported boundary and current limits

The compiler's `-emit edir` mode accepts the scalar and counted-loop fixtures
plus a bounded three-function recursive-call shape with undecorated,
effect-free `i64` signatures. It rejects other syntax and semantics instead of
silently producing a partial artifact. Includes, static-generated source maps,
multiple source files, closures, generics, effects, and arbitrary native
programs are outside this slice.

The current compiler producer emits codec schema 3 artifacts with EDIR program
version 1 in [the EDIR format](../spec/edir-format.md). Schema 3 adds function
descriptors and is required for the bounded recursive-call fixture. The
debugger also accepts legacy schema 2 artifacts and verifies either schema
before managed execution. A relative input source path
becomes the artifact's logical path. For absolute source paths,
`ELISA_EDIR_SOURCE_ROOT` must identify the root to strip; the editor then uses
the corresponding `sourcePathRoot` launch mapping when sending absolute paths to
DAP. EDIR input is not a native executable, so this slice does not provide
reverse execution for compiler-produced native executables or ship and qualify
IDE plugins.

Editor hosts connect through the debugger's documented DAP or headless process
interfaces; they must not depend on compiler internals or duplicate execution
semantics. See the [editor integration guide](integration.md) and
[plugin-author contract](../spec/plugin-integration.md) for those transports.
