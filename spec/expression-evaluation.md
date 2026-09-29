# Bounded expression evaluation

`src/inspect/expression_parser.elisa` implements a pure integer expression
parser. It evaluates against an explicit, bounded environment; the parser
cannot read a machine, value store, process, filesystem, or replay engine.
`DebuggerManagedService::service_evaluate_expression` builds that environment
from the selected stopped frame and current globals, then passes the copied
bindings to the parser.

The accepted grammar is:

```text
expression  := equality
equality    := comparison (('==' | '!=') comparison)*
comparison  := additive (('<' | '<=' | '>' | '>=') additive)*
additive    := multiplicative (('+' | '-') multiplicative)*
multiplicative := unary (('*' | '/') unary)*
unary       := '-' unary | primary
primary     := decimal | identifier | '(' expression ')'
decimal     := digit+
identifier  := (letter | '_') (letter | digit | '_')*
```

Spaces, tabs, carriage returns, and line feeds may occur between grammar
elements. Decimal literals and checked arithmetic use signed 64-bit values;
comparisons return integer `1` for true and `0` for false. Division by zero,
overflow, malformed syntax, unknown names, and unavailable bindings return
structured debugger errors.

The parser limits source text to 256 bytes, nesting to 32 levels, operands to
32, bindings to 48, and each identifier to 32 bytes. The managed service
currently exposes locals as `local0` through `local31` (limited by the
artifact's local count) and globals as `global0` through `global15`. A binding
for an uninitialized slot is present but unavailable, so it cannot be
mistaken for a zero value. The service accepts a frame index and resolves
recursive/shadowed locals against that frame's snapshot.

Adapters can use
`DebuggerExpressionParser::expression_parse_with_environment(bytes, length,
environment)` for an explicit immutable input, or call
`DebuggerManagedService::service_evaluate_expression(service, expression,
expression_length, frame_index)` to evaluate against the stopped managed
session. The latter does not mutate execution state. The compact headless
process also accepts `evaluate` with `arguments.expression`, optional
`arguments.frameIndex`, and optional `expectedStopGeneration`; JSON string
escapes are decoded before the same evaluator runs. Its response encodes the
checked `i64` value as a decimal string. Validate this process exchange against
the [`evaluate` schema](../schemas/session-protocol-v1.evaluate.schema.json).

The Elisa DAP adapter accepts the standard `evaluate` command with a required
`arguments.expression` string and optional `arguments.frameId`. A supplied
frame handle must match the current stop generation. Successful responses
return the signed result as a string, `type: "integer"`, and
`variablesReference: 0`; failures have `success: false`. Initialize advertises
`supportsEvaluateForHovers` for the managed implementation. DAP, VS Code, and
JetBrains clients therefore share the same bounded expression semantics.
