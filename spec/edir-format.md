# EDIR artifact format

EDIR artifacts are little endian, versioned byte streams decoded by
`DebuggerEDIRCodec`. The decoder verifies the complete image before it can be
passed to the managed VM. A malformed or truncated stream produces an invalid
decode result and must be rejected by the session coordinator.

The current schema is `1`. The header is:

| Field | Width | Meaning |
| --- | ---: | --- |
| schema | 4 | Codec schema, currently `1` |
| program version | 4 | EDIR program semantics version |
| instruction count | 8 | Number of encoded instructions |
| local count | 8 | Declared local slots |
| has return | 1 | Boolean encoded as `0` or `1` |

Each instruction is encoded in index order:

| Field | Width |
| --- | ---: |
| opcode | 2 |
| operand `a` | 8, signed value in two's-complement bytes |
| operand `b` | 8, signed value in two's-complement bytes |
| source file ID | 8 |
| start/end byte | 8 each |
| start line/column | 4 each |
| end line/column | 4 each |
| discriminator | 4 |

The codec accepts at most 128 instructions. The encoded stream is bounded by
the shared binary buffer. This limit is a capability of the current managed
provider; a future schema can raise it only with an explicit buffer and
compatibility change. Enum values, booleans, instruction targets, source
ranges, local initialization, and required return reachability are checked by
the EDIR verifier after decoding.

The artifact contains logical program metadata only. It contains no host
pointers, native addresses, allocator state, file descriptors, or raw Elisa
struct layout. Source IDs and build identity are supplied by the surrounding
manifest so editor clients can validate source compatibility before launch.
