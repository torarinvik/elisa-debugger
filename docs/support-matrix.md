# Support matrix

The matrix describes the current checked-in implementation. A client should
use discovery and per-session capabilities at runtime; this document is a
human-readable guide, not a substitute for negotiation.

| Surface | Managed EDIR | Instrumented native | Attach/postmortem |
| --- | --- | --- | --- |
| Launch | Supported for the bounded managed image | Capability boundary only | Unsupported |
| Attach | Unsupported | Controller contract present | Process attach model present |
| Source and function metadata | Bounded source/function tables | Symbol table and source spans | Symbol table and artifact checks |
| Source breakpoints | Resolver and pending statuses | Resolver contract | Metadata dependent |
| Typed value states | Supported bounded store | Capability contract | Availability depends on metadata |
| Expression arithmetic | Bounded side-effect-free evaluator | Provider dependent | Provider dependent |
| Record/replay effects | Effect oracle contract with mismatch detection | Not exact | Unsupported |
| Reverse step and seek | Supported within retained EDIR history | Disabled | Unsupported |
| Durable checkpoint codec | Supported for the current EDIR machine state | Not resumable | Core artifacts are inspect-only |
| Deterministic task model | Bounded scheduler and wait graph | Not exact | Unsupported |
| Branch lineage | Bounded immutable branch records | Unsupported | Unsupported |
| Trace storage | Checksummed chunks, manifests, recovery scan | Format contract | Read-only artifact mode |
| DAP | Bounded adapter | Capability dependent | Capability dependent |
| Headless session service | Versioned compact framing | Capability dependent | Capability dependent |
| Remote transport | Handshake, quotas, artifact transfer checks | Not qualified | Not qualified |

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
