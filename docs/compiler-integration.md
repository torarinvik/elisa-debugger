# Compiler integration boundary

This records the compiler dependency and qualified compiler-to-debugger seam.
The supported EDIR subset and qualification dates below define its scope.

## Compiler revision

Current qualification uses stage1 provenance revision
`23a0e16a854cddec3016746a0cb9480db0c4db22` and its matching runtime on Linux
x86_64 (2026-10-07), with stale-stage1 refusal enabled. Earlier focused gates
passed on Darwin arm64 (2026-10-06), before the subsequent Linux portability,
immutable retained replay, and trace-publication generation repairs. The
compiler emits EDIR codec schema 4 and program version 5 for the supported clock/random, console byte/EOF, and
virtual-file byte-read instructions. `managed-trace-effects-check` compiles a
recursive program at O0/O2, records it in one process, and restores every
boundary in fresh processes after changing and deleting its original host
file. A separately compiled O2 test executable passes the same regression.
`dap-trace-effects-check` saves and reopens this program across adapter
processes and advances through captured effects without provider requests.
These focused gates do not qualify broader language or native replay support.
The older pinned integration procedure below remains historical evidence.

`cli-trace-effects-check` opens that same DAP trace with an explicit EDIR image
in a fresh CLI process, advances and reverses through captured effects, and
exports an identical artifact after rewinding. Missing/corrupt image loads,
an incompatible trace, and a repeated launch leave the session usable.
`replay-divergence-clients-check` changes an event state hash and reseals all
transport checksums. Both clients report the first mismatch at event 58 with
58 verified preceding boundaries, preserve the live stop, and accept the
original artifact on retry. The DAP diagnostic passes Content-Length and JSON
validation.

The Linux run completed `make -j12 check module-check smoke`. Separate O2
executables passed managed effect replay, CLI/DAP effectful trace reopening,
first-divergence diagnostics, editor timeline navigation, EDIR loading,
transactional trace-file I/O, spawn-action storage, child capture, and agent
transport. Draft 2020-12 validation covered both the rejected divergence
response and successful trace-open retry. Negative regressions reproduced
retained-history mutation and delayed provider-reply acceptance before their
repairs. The source snapshot used for the final full run was
`cfac83eabd71a5def7daf22f863935f168e9c6144beff1153be418728fadaa2b`;
the seven O2 integration builds used the same implementation sources. Extra
O2 file-loader and trace-file executables also passed. Later documentation
edits do not imply additional runtime qualification. The remote compiler
source is an isolated pinned snapshot; changes to neighboring checkouts are
not incorporated into these results.

The current provenance guard hashes compiler sources, runtime sources, build
recipes, and the stage1 product. It checks content rather than timestamps.
The source-tree SHA-256 is
`58e3e1ffa12306bef27875b95697768819c376f1646565b8f62a8abd25a7fe48`;
the build-recipe SHA-256 is
`7b4267cbd9e406c71e7bb89bfb93980d8d3e9c6cc33746340cba67adc27d6e10`.

| Provenance host | Stage1 product SHA-256 | Runtime object SHA-256 |
| --- | --- | --- |
| Darwin arm64, earlier focused gates | `d397d5e37ac1d37ee070d56e5f7076466d7dd47251518bcf1b2f2c24be007fe2` | `4bfbc5841c65981a9574c7c81ff60e48cd8f4f059d4c92123b43149e1b06c080` |
| Linux x86_64 | `b24730757cad1f181f1a6647b2dfe52d6c46e262c91e4a179f9db0ed25451b14` | `9d7bbd0119182a7047825ec61ce72ff9c5d32ef3cf61c42a68eb3a315ca1b4ab` |

Linux qualification uses Clang/LLVM 21, explicit
`ELISA_HOST_LINUX=1 ELISA_HOST_X86_64=1`, and
`ELISA_NO_LINUX_SHIM=1`. A runtime built without the Linux host flag referenced
Darwin `sysctlbyname`; rebuilding with the correct flags resolved that link
failure. The runtime is compiled with `ELISA_STAGE1_JOBS=1` to retain private
helper linkage. Compiling both runtime and application with multiple stage1
partitions exposes a duplicate `elisa.part.__elisa_darray_grow` definition on
this compiler revision. Application builds use four partitions after the
single-object runtime build. No unresolved-symbol or duplicate-definition
linker override is used.

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

At the historical integration revision, the wrapper `scripts/elisac_stage1.sh` rejects a product binary older than any
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

## Historical integration build and test path

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

## Historical boundary and current limits

At the historical integration revision, `-emit edir` accepts the scalar and counted-loop fixtures
plus a bounded three-function recursive-call shape with undecorated,
effect-free `i64` signatures. It rejects other syntax and semantics instead of
silently producing a partial artifact. Includes, static-generated source maps,
multiple source files, closures, generics, effects, and arbitrary native
programs are outside this slice.

That compiler producer emits codec schema 3 artifacts with EDIR program
version 1 in [the EDIR format](../spec/edir-format.md). Schema 3 adds function
descriptors and is required for the bounded recursive-call fixture. The
debugger now emits schema 4, reads legacy schemas 2/3, and verifies each schema
before managed execution. The current narrow effects boundary is described in
the qualification section above. A relative input source path
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
