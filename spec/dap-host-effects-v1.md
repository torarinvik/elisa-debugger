# Elisa DAP host-effects extension, version 1

This document defines the optional host-effects extension implemented by
`build/elisa-debugger-dap-server`. It lets an IDE-side provider supply values
for managed EDIR host operations while the DAP process keeps ownership of the
debug session and records each accepted result in its managed history.

The extension covers `clockNow`, `randomU64`, `consoleInput`, and
`consoleOutput`.
It can yield while processing DAP `continue`, `next`, `stepIn`, or `stepOut`.
The `stepBack` and `reverseContinue` operations do not request new host values.
Only one host request may be pending per DAP process.

## Capability negotiation

Read the response body from `initialize`. The extension is available only
when both fields match:

```json
{
  "supportsElisaHostEffects": true,
  "elisaHostEffectsVersion": 1
}
```

The capability is separate from standard DAP capabilities. A client that does
not implement version 1 must not promise effectful EDIR programs can run to
completion. The adapter does not call the host clock, random generator, or
console itself; the IDE-side provider selects and performs those operations.

## Yield and event ordering

When an execution request reaches a host operation, its successful response
contains an `elisaHostEffect` object. For example, the following is a response
to a DAP `next` request whose client sequence is `12`:

```json
{
  "seq": 17,
  "type": "response",
  "request_seq": 12,
  "command": "next",
  "success": true,
  "body": {
    "allThreadsContinued": false,
    "elisaHostEffect": {
      "version": 1,
      "requestId": 12,
      "kind": "clockNow",
      "callSite": "f91c637f64439291",
      "invocation": "22e93844e3dcb96c",
      "requestHash": "6910afcd3785940a"
    }
  }
}
```

The response is followed by the ordinary DAP `continued` event and a `stopped`
event with reason `pause`. The client should treat the VM as stopped at the
host-effect boundary, keep the session open, and handle the pending request
before sending another execution request. The three identity fields are
exactly 16 lowercase hexadecimal characters. They are diagnostic/correlation
metadata for the client; the client must not alter or echo them in its reply.

`requestId` is the nonzero DAP sequence number of the `continue` or step
request that yielded. It is the only provider-reply correlation field. The
adapter retains the full typed host request and validates it again at the
managed-service boundary.

## Supplying a result

Send one DAP request named `elisa/provideHostEffect`. `requestId` must match
the pending extension object. Encode every result as two unsigned 32-bit
halves so JSON-number rounding cannot change a 64-bit value.

For a clock sample, include both halves. The combined bits are interpreted as
a signed 64-bit value by the managed clock operation; the extension does not
define a unit or clock source, so the host and EDIR program must agree on that
meaning.

```json
{
  "seq": 18,
  "type": "request",
  "command": "elisa/provideHostEffect",
  "arguments": {
    "requestId": 12,
    "valueHigh": 0,
    "valueLow": 1735689600
  }
}
```

For `randomU64`, use the same fields and combine them as an unsigned 64-bit
value. Both halves must be present and each must be in the range from zero to
`4294967295`, inclusive.

For `consoleOutput`, the extension object contains a decimal byte `payload`.
Write that byte to the IDE's chosen console/output sink, then acknowledge it
without `valueHigh` or `valueLow`:

```json
{
  "seq": 19,
  "type": "request",
  "command": "elisa/provideHostEffect",
  "arguments": { "requestId": 12 }
}
```

For `consoleInput`, the extension object contains a decimal `requested` count.
Version 1 requests exactly one byte from stdin. Read one byte or report EOF,
then return its unsigned byte value in the same two-half encoding used for
`randomU64`. Represent EOF with all bits set (`valueHigh` and `valueLow` both
`4294967295`), which the managed EDIR operation receives as signed `-1`:

```json
{
  "seq": 17,
  "type": "response",
  "request_seq": 12,
  "command": "continue",
  "success": true,
  "body": {
    "allThreadsContinued": false,
    "elisaHostEffect": {
      "version": 1,
      "requestId": 12,
      "kind": "consoleInput",
      "callSite": "f91c637f64439291",
      "invocation": "22e93844e3dcb96c",
      "requestHash": "6910afcd3785940a",
      "requested": 1
    }
  }
}
```

The provider reply for the byte `A` uses `valueHigh: 0` and `valueLow: 65`.
EOF uses `valueHigh: 4294967295` and `valueLow: 4294967295`.

A successful provider request receives a response with `success: true` and
`body.accepted: true`. Accepting a clock or random result records and commits
the effect in the managed session. Accepting console output records the byte
as an effect. Accepting console input records the byte or EOF together with a
stdin journal entry. The DAP target remains stopped; the reply does not issue
a second `continue` or step operation. The user can then choose the next
execution action.

The client must not send extra result fields for console output, omit either
half for clock/random/input, provide input values outside `0..255` (except the
all-bits-set EOF value), or send a second reply. A malformed, mismatched, or
stale reply gets `success: false` and leaves the pending request available for
a corrected reply. A reply when no request is pending also gets
`success: false`. Clients should branch on `success`, not parse the current
human-readable error message. A second execution request while a provider
request is pending is rejected without changing the session.

## Recording and replay

Accepted values are stored in the managed effect journal with the operation's
call-site and invocation identity. Managed reverse navigation restores the
corresponding historical position. Replay consumes recorded provider results
instead of querying the clock, random source, or stdin again; console output
replay does not emit the byte a second time. A new DAP process owns a new
session and does not reopen the prior process's history.

## IDE integration

A host integration must inspect responses to `continue`, `next`, `stepIn`, and
`stepOut`; checking only DAP events is not enough because the typed request is
in the execution response body. It then routes `kind` to a provider, preserves
`requestId` as an integer, splits provider values into exact 32-bit halves,
and submits `elisa/provideHostEffect` on the same DAP session.

In VS Code, an extension can observe adapter messages with a
`DebugAdapterTracker` and send the reply through that session's
`DebugSession.customRequest` method. See the [VS Code API reference for
debugging](https://code.visualstudio.com/api/references/vscode-api#DebugAdapterTracker)
for these host APIs. The tracker observes protocol traffic; the extension still
owns the provider and reply policy.

For JetBrains or another host, use the selected DAP route only if it exposes
both the execution response body and a way to send the custom request through
the same session. A bridge that hides execution responses must surface this
extension itself. Do not open a second debugger process to answer a request:
each process has an independent session and pending-request state.

Version 1 has no cancellation, timeout, queue, or retry protocol. A host
should keep one outstanding provider operation per session, send at most one
reply, and terminate the DAP session if it cannot complete the pending request.
The current process also does not provide a durable session-resume mechanism.
