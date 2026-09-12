# EDIR artifact format

EDIR artifacts are little-endian, versioned byte streams decoded by
`DebuggerEDIRCodec`. The decoder verifies the complete image before it can be
passed to the managed VM. A malformed or truncated stream produces an invalid
decode result and must be rejected by the session coordinator.

The current codec schema is `2`. Schema `1` is rejected; the decoder never
interprets a v1 instruction as a v2 source-file table. The header is:

| Field | Width | Meaning |
| --- | ---: | --- |
| schema | 4 | Codec schema, currently `2` |
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
instructions. Its maximum stream size is 24,925 bytes:
`29 + 128*62 + 16*(36+1024)`. These are byte counts in the canonical codec
layout and must stay synchronized with `DebuggerEDIRCodec` and the file loader
bound.

Enum values, booleans, instruction targets, source-table identities and paths,
source ranges, source-file references, line bounds, local initialization, and
required return reachability are checked before an image is accepted. The
artifact contains logical program metadata only. It contains no host pointers,
native addresses, allocator state, file descriptors, or raw Elisa struct
layout.

## Current file launch contract

The managed DAP adapter accepts a local EDIR artifact path in the standard
`launch` request's `arguments.program` field. It opens that path read-only,
reads no more than the 24,925-byte artifact limit plus one byte, requires a
complete file, decodes and verifies the entire artifact, and only then
constructs the managed session with that image. Missing paths, oversized
files, truncated streams, unsupported schemas, and verifier failures are
reported as launch failures. The adapter accepts paths up to 1,024 UTF-8
bytes and decodes JSON escapes, including Unicode surrogate pairs.

This loader runs on the POSIX host boundary; file access is provided by
`open`, `read`, and `close`, while bounds checks, decoding, and EDIR
verification remain in Elisa. Compiler-produced EDIR is not yet integrated
with this source-file table contract; until that producer work lands, the
current artifact fixtures are authored directly as EDIR bytes by Elisa code.
The table stores relative logical paths. For standard DAP clients that send an
absolute editor `source.path`, `launch.arguments.sourcePathRoot` supplies the
explicit workspace root; the adapter strips only that exact prefix at a path
separator boundary before matching. `stackTrace` returns the same mapped path
in its DAP `source` object. Without this setting, clients must send the EDIR
logical path. The adapter does not infer mappings from basenames or suffixes.
This contract does not claim that arbitrary `.elisa` source or native
executables can be launched by the managed engine.
