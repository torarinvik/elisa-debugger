# EDIR artifact format

EDIR artifacts are little-endian, versioned byte streams decoded by
`DebuggerEDIRCodec`. The decoder verifies the complete image before it can be
passed to the managed VM. A malformed or truncated stream produces an invalid
decode result and must be rejected by the session coordinator.

The current codec schema is `3`. Schema `1` is rejected. Schema `2` remains
readable as a legacy stream with no function table; schema `3` adds an explicit
function-descriptor table after the instruction stream. The header is:

| Field | Width | Meaning |
| --- | ---: | --- |
| schema | 4 | Codec schema, currently `3` |
| program version | 4 | EDIR program semantics version |
| instruction count | 8 | Number of encoded instructions |
| local count | 8 | Declared local slots |
| has return | 1 | Boolean encoded as `0` or `1` |
| source-file count | 4 | Number of source-file rows immediately following the header |

Each source-file row is encoded before the instruction stream:

| Field | Width | Meaning |
| --- | ---: | --- |
| file ID | 8 | Stable nonzero identity used by `SourceSpan.file` |
| logical-path ID | 8 | Stable nonzero identity of the logical source path |
| content digest | 8 | Stable nonzero identity of the source contents |
| line count | 8 | Number of one-based source lines |
| path length | 4 | Number of exact UTF-8 path bytes that follow |
| path bytes | variable | Logical path bytes, without a terminator |

The table contains at most 16 rows. Each path contains 1 to 1,024 bytes, is a
relative logical path encoded as valid UTF-8, contains no NUL or control
characters, uses `/` separators, has no drive prefix, and has no empty, `.` or
`..` path segments. A file ID and logical-path ID may each appear only once;
the content digest may be shared by files with identical contents. The decoder
preserves the path bytes exactly and never applies host path normalization.

Each instruction is encoded in index order after the complete source-file
table:

| Field | Width | Meaning |
| --- | ---: | --- |
| opcode | 2 | EDIR opcode |
| operand `a` | 8 | Signed value in two's-complement bytes |
| operand `b` | 8 | Signed value in two's-complement bytes |
| source file ID | 8 | Zero for an instruction without source mapping; otherwise resolves to a table row |
| start/end byte | 8 each | Source byte range |
| start line/column | 4 each | One-based source start location |
| end line/column | 4 each | Source end location |
| discriminator | 4 | Distinguishes locations sharing a source range |

For every nonzero source file ID, both span lines must be nonzero and no greater
than the referenced row's line count. A zero file ID remains valid for
instructions without source locations. The codec accepts at most 128
instructions.

The current compiler's schema-3 producer serializes parser spans verbatim:
lines are one-based, columns are one-based UTF-8 byte counts, and byte offsets
are zero-based with an exclusive end. The wire format has no coordinate-unit
tag. These producer columns do not satisfy the session protocol's zero-based
UTF-16 column contract; the DAP adapter currently changes the column base but
does not convert UTF-8 bytes to UTF-16 code units. Line breakpoints remain
usable, while compiler-artifact column breakpoints are unsupported until the
producer emits normalized coordinates or the artifact carries enough source
content for a consumer to convert them safely.

Schema 3 appends a function count and its descriptors after all instructions.
The bounded compiler call fixture emits three descriptors (`main`, `descend`,
and `add_ten`) and call targets that point at their entry instructions. Other
source-level calls remain outside the producer contract. The function table
layout is:

| Field | Width | Meaning |
| --- | ---: | --- |
| function count | 4 | Number of descriptors that follow |
| function ID | 8 | Stable nonzero function identity, unique within the artifact |
| entry instruction | 8 | Included instruction index at which the function starts |
| end instruction exclusive | 8 | First instruction index outside the function's half-open range |
| source span | 44 | Function source identity and source range, encoded as above |
| name length | 4 | Number of exact UTF-8 name bytes that follow |
| name bytes | variable | Compiler-supplied function name, without a terminator |

The table is bounded to 64 descriptors and 128 name bytes per descriptor.
Names must be nonempty valid UTF-8 without control characters. Each range must
satisfy `entry < end <= instruction count`; each source span must resolve to a
source-file row and fit within its line count. Duplicate function IDs and
invalid source references are rejected. Function ranges in one artifact may
not overlap, so an instruction can resolve to at most one function descriptor;
adjacent half-open ranges are valid. The debugger does not infer descriptors
from instruction addresses or call targets. A schema-2 artifact decodes with an
empty function table, so it cannot provide function-name resolution.

The maximum schema-3 stream size is 37,729 bytes:
`29 + 128*62 + 16*(36+1024) + 4 + 64*(72+128)`. These are byte counts in the
canonical codec layout and must stay synchronized with `DebuggerEDIRCodec` and
the file loader bound.

Enum values, booleans, instruction targets, source-table identities and paths,
source ranges, source-file references, function IDs/names/ranges/source
references, line bounds, local initialization, and required return reachability
are checked before an image is accepted. The artifact contains logical program
metadata only. It contains no host pointers, native addresses, allocator state,
file descriptors, or raw Elisa struct layout.

## Current file launch contract

The managed DAP adapter accepts a local EDIR artifact path in the standard
`launch` request's `arguments.program` field. It opens that path read-only,
reads no more than the 37,729-byte artifact limit plus one byte, requires a
complete file, decodes and verifies the entire artifact, and only then
constructs the managed session with that image. Missing paths, oversized
files, truncated streams, unsupported schemas, and verifier failures are
reported as launch failures. The adapter accepts paths up to 1,024 UTF-8
bytes and decodes JSON escapes, including Unicode surrogate pairs.

This loader runs on the POSIX host boundary; file access is provided by
`open`, `read`, and `close`, while bounds checks, decoding, and EDIR
verification remain in Elisa. The current adjacent compiler checkout at the
revision recorded in [`docs/compiler-integration.md`](../docs/compiler-integration.md)
emits schema-3 artifacts for its explicitly supported single-file scalar,
counted-loop, and bounded recursive-call fixtures, with source-table identities,
original source spans, and function descriptors for the call fixture. Legacy
schema-2 artifacts remain loadable for compatibility. The producer rejects
includes and unsupported syntax instead of emitting a partial image; the
Elisa-authored fixtures continue to cover VM instructions beyond that initial
compiler subset.
Relative compiler source paths become logical paths directly. For absolute
source paths, set `ELISA_EDIR_SOURCE_ROOT` to the workspace root so the producer
can strip that exact prefix and retain a safe relative path in the artifact.
The table stores relative logical paths. For standard DAP clients that send an
absolute editor `source.path`, `launch.arguments.sourcePathRoot` supplies the
explicit workspace root; the adapter strips only that exact prefix at a path
separator boundary before matching. `stackTrace` returns the same mapped path
in its DAP `source` object. Without this setting, clients must send the EDIR
logical path. The adapter does not infer mappings from basenames or suffixes.
This contract does not claim that arbitrary `.elisa` source or native
executables can be launched by the managed engine.
