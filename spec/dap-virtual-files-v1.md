# Elisa DAP virtual-file snapshots, version 1

This optional DAP launch extension mounts bounded, deterministic file contents
inside a managed EDIR session. The DAP adapter does not read the named paths
from the host file system. An IDE supplies the bytes in the launch request, so
the initial resource state is available to checkpoints and replay.

## Capability negotiation

Use the extension only when the `initialize` response contains both fields:

```json
{
  "supportsElisaVirtualFiles": true,
  "elisaVirtualFilesVersion": 1
}
```

## Launch payload

Add `elisaVirtualFiles` to the normal DAP `launch` request's `arguments`:

```json
{
  "seq": 2,
  "type": "request",
  "command": "launch",
  "arguments": {
    "program": "build/app.edir",
    "elisaVirtualFiles": [
      {
        "handle": 1,
        "path": "data/input.bin",
        "contentsHex": "00417f",
        "writable": false
      }
    ]
  }
}
```

Each entry requires a positive `handle`, a non-empty UTF-8 `path`, and a
`contentsHex` string containing an even number of hexadecimal digits. Hex may
use either case and represents bytes directly, including zero bytes. The
optional `writable` property defaults to `false`. A host may set it to `true`
when initialize additionally advertises `supportsElisaVirtualFileWrites: true`
and `elisaVirtualFileWritesVersion: 1`. This permits guest writes to the virtual
copy without modifying any host file.

Version 1 permits at most 16 snapshots, at most 256 decoded bytes per
snapshot, and at most 1024 UTF-8 bytes per path. Handles must be unique and
contiguous from 1 through N in array order. This matches the resource store's
validated handle invariant; a nonsequential mapping is rejected. Guest
`virtual_file_read_byte`, `virtual_file_write_byte`, and `virtual_file_seek`
operations address the explicit handle. The first
entry above is therefore read using handle 1.

`path` is a logical identity used to reject duplicate resources and derive a
stable FNV-1a 64-bit resource identity. It is not resolved relative to the
workspace and is never opened by the adapter. The resource generation is 1 for
this version. A hash collision between two logical paths is rejected as a
duplicate mapping.

The adapter validates every snapshot before loading or launching the guest.
It mounts snapshots into the managed service before launch, capturing the
initial bytes at event zero. A mount failure resets the partially configured
service before returning an error. Reads, byte writes, and absolute seeks are
recorded in the managed resource journal and restored with reverse navigation
and replay. Seek accepts an offset through the current file length; writes can
overwrite or append through the 256-byte bound. Read-only writes, invalid
handles/offsets, and exhausted journal capacity fail before advancing execution.

Malformed fields, duplicate properties or paths, invalid UTF-8, odd or
non-hex contents, invalid handle sequences, and non-boolean `writable` values
fail launch with an invalid-argument response. The extension is available for the managed
EDIR engine; native engine sessions do not mount these snapshots.

The adapter additionally advertises `supportsElisaVirtualFileResults: true`
and `elisaVirtualFileResultsVersion: 1`. With a matching version-7 EDIR producer,
`virtual_file_try_read_byte`, `virtual_file_try_write_byte`, and
`virtual_file_try_seek` return captured guest error values: invalid handle `-2`,
permission denied `-3`, or invalid offset `-4`. EOF remains `-1`. A failed guest
call advances execution without mutating file bytes or cursor; its effect record
is replayed from the captured resources and checked at that exact boundary.
Resource exhaustion and invalid debugger state still return debugger failures.
Legacy calls retain their debugger-failure behavior.

The `supportsElisaVirtualFileLifecycle: true` capability with
`elisaVirtualFileLifecycleVersion: 1` adds program-8 logical close/reopen.
`virtual_file_try_close` returns `0` on success. `virtual_file_try_reopen`
returns the same captured handle and resets its cursor to zero. Close preserves
bytes, path identity, and cursor; all try-I/O on a closed handle returns `-5`.
Closing an already closed handle returns `-5`; reopening an open handle returns
`-6`; unknown handles return `-2`. These results and successful lifecycle
operations are journaled and validated at every replay boundary. Reverse
navigation derives openness from the consumed journal prefix. No host file is
opened, closed, written, or allocated by these guest instructions.

## Editor integration

An adapter plugin should read the capability before adding the custom launch
field. It should map each guest handle to a stable editor-owned logical path
and provide an immutable byte snapshot. To update contents, start a new launch
with a new snapshot. The launch snapshot contract does not provide general guest path opens, host
descriptor reuse, file watching, host path access, sparse files, or editing a
snapshot during a recording. Logical close/reopen requires the separately
negotiated lifecycle capability.

The headless service API and DAP extension are separate integration surfaces.
The DAP schema is not a cross-language ABI for directly calling Elisa modules.
See [plugin integration](plugin-integration.md) for the editor transport
guidance and the [launch-configuration schema](../schemas/dap-launch-configuration.schema.json)
for the VS Code-style client configuration shape.
