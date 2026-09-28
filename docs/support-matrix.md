# Support matrix

The matrix describes the current checked-in implementation. Clients should
use the selected process transport's capabilities. Typed Elisa APIs and
protocol method names do not imply that the compact process transport can
carry their operands and results.

| Surface | Managed EDIR | Instrumented native | Attach/postmortem |
| --- | --- | --- | --- |
| Launch | Supported for the bounded managed image | Capability boundary only | Unsupported |
| Attach | Unsupported | Controller contract present | Process attach model present |
| Source and function metadata | Debugger codec supports bounded source/function tables in EDIR codec schema 3 and reads legacy schema 2; the current compiler emits schema 3 descriptors for the bounded recursive-call fixture and schema 3 source rows for scalar/loop fixtures | Symbol table and source spans; bounded DWARF32 v2-v4 lookup maps ELF `.debug_line` link addresses to source rows, but is not yet wired to live interactive source resolution | Symbol table plus bounds-checked ELF/Mach-O artifact headers |
| Source breakpoints | DAP resolves logical paths against the EDIR source table; absolute editor paths use an explicit `sourcePathRoot` launch mapping, and explicit source references remain supported | Resolver contract | Metadata dependent |
| Typed value states | Supported bounded store, including absent and historical states | Capability contract | Availability depends on metadata |
| Expression arithmetic | Bounded side-effect-free evaluator | Provider dependent | Provider dependent |
| Record/replay effects | Generic oracle exactly replays scalar clock samples; other effect kinds mark the oracle incomplete | Not exact | Unsupported |
| Reverse step and seek | Supported within retained EDIR history | Disabled | Unsupported |
| Durable checkpoint codec and restore | Supported for bounded managed EDIR: checkpoints persist the full build identity and canonical whole-image fingerprint; restore rejects mismatched build/image/recording before replay. Integrity checks detect corruption and identity mismatch but do not authenticate untrusted checkpoints. | Not resumable | Core artifacts are inspect-only |
| Deterministic task model | Bounded scheduler and wait graph | Not exact | Unsupported |
| Branch lineage | Bounded immutable branch records and verified branch comparison | Unsupported | Unsupported |
| Historical queries | Cancellable last-write/first-change queries over captured provenance | Capability contract | Unsupported |
| Concurrency diagnostics | Deterministic scheduler, wait graph, bounded alternate schedules, observed races | Capability contract | Unsupported |
| Trace storage | Checksummed chunks, manifests, recovery scan | Format contract | Read-only artifact mode |
| Managed trace capture/export | Exact single-root EDIR boundary events through the typed service API; rewinds and child-branch execution make the capture partial | Unsupported | Unsupported |
| DAP process | Managed EDIR only: verified-artifact launch; source-line breakpoints; one `main` thread; stack/scopes/locals; bounded local pages; memory reads; continue/pause/step-in/over/out and reverse step/continue. Attach, conditional/log/function/data breakpoints, evaluation, assignment, restart, and disassembly are unavailable. | No native operations are wired | No postmortem operations are wired |
| Headless JSON process | Managed EDIR launch, source-line breakpoint replacement by the artifact's normalized logical path, pause/continue/step/reverse-step/seek, one `main` thread, stack/scopes, paged locals, bounded logical managed-memory reads, checkpoint/branch metadata, and read-only `trace.verify` metadata. Breakpoint requests are bounded to 32 lines per source and memory requests to 64 bytes; structured results preserve generation and identity. No attach, evaluation, trace artifact transfer, or shared-session ownership. | No native operations are wired | No postmortem operations are wired |
| macOS live resource snapshot CLI | Not applicable | One read-only `PROC_PIDTASKALLINFO` snapshot by PID: virtual/resident bytes, process/thread CPU time, thread counts, page faults, and process start identity. No suspension, memory reads, allocation tracing, or interactive-session integration. | Not applicable |
| macOS Jetsam report CLI | Not applicable | Not applicable | Bounded read-only `.ips` parsing; PID/UUID identity checks; resident bytes from page count and page size; lifetime maximum, region count, and CPU time; ordered snapshot counter comparison. No live attach, core-dump inspection, or allocation-site attribution. |
| Remote transport | Handshake, quotas, resumable artifact transfer, reconnect state | Not qualified | Not qualified |

## Exactness rules

An exact claim requires a valid build/trace identity, a supported provider,
validated state, and no diverged or incomplete effect, scheduler, or trace
segment. A partial or observational result remains useful for inspection but
must not be advertised as resumable replay.

## Platform qualification

The repository's local development path is macOS arm64 with the sibling Elisa
self-hosted compiler and runtime object. Native platform support is a contract
and test surface rather than a claim that the current host has completed native
attach or native replay qualification. Additional targets must add their FFI,
process, signal, symbol, and cleanup tests before being listed as qualified.

Until a native provider is wired to an interactive real target,
instrumented-native, attached-native, and postmortem capability sets identify
the requested engine kind but advertise no native debugging operations. The
standalone macOS resource snapshot CLI is observational only and does not
change those capability sets. The DAP adapter only advertises
termination for the managed engine and does not advertise native disassembly.
The native controller model retains a reported target-crash detail separately
from an agent transport failure. Its Elisa agent buffer validates monotonic
safe-point acknowledgements and refuses to resume after event loss; a platform
process monitor and target-agent transport are still required before those
transitions can be driven by a live native target.

The headless process advertises its smaller wire surface through discovery.
Source breakpoints, bounded managed-memory reads, checkpoint/branch metadata,
and read-only trace verification are enabled for managed EDIR artifacts and
use the compact request/results described in the session protocol. Trace
export, historical queries, and comparison remain disabled where the required
operands or results are unavailable. A typed in-process
API is not evidence that the compact process can carry those operands and
results. See [editor integration](integration.md) for the process boundary and
host mapping.
