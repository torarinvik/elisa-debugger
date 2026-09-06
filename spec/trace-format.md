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
| 40 | 8 | payload FNV-1a checksum |

The payload follows immediately and is limited by the storage reader's named
capacity. Event payloads use the recorder's versioned fixed-width envelope;
manifest payloads use the manifest codec. All fields are encoded explicitly by
`DebuggerTraceBinary`.

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
