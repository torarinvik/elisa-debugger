# Trace format v1

Trace files are a sequence of little-endian records. A record begins with a
48-byte chunk header:

| Offset | Size | Field |
| ---: | ---: | --- |
| 0 | 4 | magic `ELTR` (`69, 76, 84, 82`) |
| 4 | 2 | format version (`1`) |
| 6 | 2 | chunk kind |
| 8 | 8 | sequence |
| 16 | 8 | first logical event |
| 24 | 8 | last logical event |
| 32 | 8 | payload length |
| 40 | 8 | payload FNV-1a checksum (64-bit standard offset basis) |

The payload follows immediately and is limited by the storage reader's named
capacity. Event payloads use the recorder's versioned fixed-width envelope;
manifest payloads use the manifest codec. All fields are encoded explicitly by
`DebuggerTraceBinary`.

New writers use the standard 64-bit FNV-1a offset basis
`14695981039346656037`. Readers also accept the historical Elisa v1 basis
`1469598103934665603` so existing trace files remain readable. Re-encoding a
legacy chunk writes its checksum with the standard basis.

The manifest `checkpoint_count` is the number of `Checkpoint` kind chunks in
the bundle. Event chunk count is tracked independently by the reader. A trace
with no serialized checkpoint chunks records zero; event chunks must never be
used as a substitute for this count.

Chunk sequences start at zero and increase without gaps. The manifest is the
first chunk. Event chunks cannot be empty and their event ranges are contiguous.
Other chunk kinds are accepted only after the manifest and must still match the
manifest schema and sequence rules.

The optional 20-byte footer is encoded as:

| Offset | Size | Field |
| ---: | ---: | --- |
| 0 | 4 | footer magic |
| 4 | 8 | next chunk sequence |
| 12 | 8 | last verified event |

Writers append complete chunks before the footer. Readers scan only complete
headers, bounded payloads, and matching checksums. A torn final chunk is
reported as a truncated prefix; a checksum, sequence, range, or manifest
failure is corrupt. Indexes are disposable and are rebuilt from authoritative
chunks.

Exact replay additionally requires a replayable exact manifest, complete event
chunks, a verified footer, and all required source/build artifacts. Removing a
replay-required blob produces a partial/non-replayable export rather than an
exact claim.

## Managed full checkpoint payload

The managed full-checkpoint codec schema is `3`; its envelope fields are
encoded explicitly in little-endian order. The envelope contains the checkpoint
schema, recording and branch IDs, event ordinal, state hash, complete
`BuildIdentity` (compiler, runtime, source, target, and metadata version), and
a validity-tagged fingerprint of the complete canonical EDIR artifact before
the machine, task, effect, virtual-resource, and adapter snapshots. A checksum
covers the encoded envelope. The image fingerprint is the 64-bit FNV-1a checksum
of `DebuggerEDIRCodec::artifact_encode` bytes, including instructions, source
files, and function descriptors. Restore compares both identities with the
destination before replaying the checkpoint prefix.

The checksum and image fingerprint detect accidental corruption or identity
mismatch; they are not cryptographic authentication. Schema-2 checkpoint
payloads are rejected by the schema-3 decoder and must be regenerated from a
source execution with the intended build and image.

Trace format v1 has no branch-lineage manifest. Exact v1 recordings therefore
accept only root-branch events and root-branch full checkpoints. Structurally
valid non-root or mixed-branch records can still be decoded, but verification
reports them as partial and non-replayable until a later format version stores
and validates the branch's parent, fork event, and required dependency range.
