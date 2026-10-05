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
optional `writable` property may be omitted or set to `false`; `true` is
rejected because the current guest instruction set only reads virtual files.

Version 1 permits at most 16 snapshots, at most 256 decoded bytes per
snapshot, and at most 1024 UTF-8 bytes per path. Handles must be unique and
contiguous from 1 through N in array order. This matches the resource store's
validated handle invariant; a nonsequential mapping is rejected. Guest
`virtual_file_read_byte` operations address the explicit handle. The first
entry above is therefore read using handle 1.

`path` is a logical identity used to reject duplicate resources and derive a
stable FNV-1a 64-bit resource identity. It is not resolved relative to the
workspace and is never opened by the adapter. The resource generation is 1 for
this version. A hash collision between two logical paths is rejected as a
duplicate mapping.

The adapter validates every snapshot before loading or launching the guest.
It mounts snapshots into the managed service before launch, capturing the
initial bytes at event zero. A mount failure resets the partially configured
service before returning an error. Reads are recorded in the managed resource
journal and restored with reverse navigation and replay.

Malformed fields, duplicate properties or paths, invalid UTF-8, odd or
non-hex contents, invalid handle sequences, and `writable: true` fail launch
with an invalid-argument response. The extension is available for the managed
EDIR engine; native engine sessions do not mount these snapshots.

## Editor integration

An adapter plugin should read the capability before adding the custom launch
field. It should map each guest handle to a stable editor-owned logical path
and provide an immutable byte snapshot. To update contents, start a new launch
with a new snapshot. Version 1 does not support guest writes, file watching,
host path access, or editing a snapshot during a recording.

The headless service API and DAP extension are separate integration surfaces.
The DAP schema is not a cross-language ABI for directly calling Elisa modules.
See [plugin integration](plugin-integration.md) for the editor transport
guidance.
