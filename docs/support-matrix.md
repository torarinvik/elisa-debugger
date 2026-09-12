# Support matrix

The matrix describes the current checked-in implementation. A client should
use discovery and per-session capabilities at runtime; this document is a
human-readable guide, not a substitute for negotiation.

| Surface | Managed EDIR | Instrumented native | Attach/postmortem |
| --- | --- | --- | --- |
| Launch | Supported for the bounded managed image | Capability boundary only | Unsupported |
| Attach | Unsupported | Controller contract present | Process attach model present |
| Source and function metadata | Bounded source/function tables; EDIR v2 binds source IDs to normalized paths and content digests | Symbol table and source spans | Symbol table plus bounds-checked ELF/Mach-O artifact headers |
| Source breakpoints | DAP resolves logical paths against the EDIR v2 table; absolute editor paths use an explicit `sourcePathRoot` launch mapping, and explicit source references remain supported | Resolver contract | Metadata dependent |
| Typed value states | Supported bounded store, including absent and historical states | Capability contract | Availability depends on metadata |
| Expression arithmetic | Bounded side-effect-free evaluator | Provider dependent | Provider dependent |
| Record/replay effects | Generic oracle exactly replays scalar clock samples; other effect kinds mark the oracle incomplete | Not exact | Unsupported |
| Reverse step and seek | Supported within retained EDIR history | Disabled | Unsupported |
| Durable checkpoint codec | Supported for the current EDIR machine state | Not resumable | Core artifacts are inspect-only |
| Deterministic task model | Bounded scheduler and wait graph | Not exact | Unsupported |
| Branch lineage | Bounded immutable branch records and verified branch comparison | Unsupported | Unsupported |
| Historical queries | Cancellable last-write/first-change queries over captured provenance | Capability contract | Unsupported |
| Concurrency diagnostics | Deterministic scheduler, wait graph, bounded alternate schedules, observed races | Capability contract | Unsupported |
| Trace storage | Checksummed chunks, manifests, recovery scan | Format contract | Read-only artifact mode |
| Managed trace capture/export | Exact single-root EDIR boundary events through the typed service API; rewinds and child-branch execution make the capture partial | Unsupported | Unsupported |
| DAP | Bounded adapter | Capability dependent | Capability dependent |
| Headless session service | EDIR launch, managed lifecycle/time travel, frame/scope/local inspection | Capability dependent | Capability dependent |
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

Until a native provider is wired to a real target, instrumented-native,
attached-native, and postmortem capability sets identify the requested engine
kind but advertise no native operations. The DAP adapter only advertises
termination for the managed engine and does not advertise native disassembly.
