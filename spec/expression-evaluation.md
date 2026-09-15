# Bounded expression evaluation

`src/inspect/expression_parser.elisa` provides the first string based
expression evaluator for the debugger. It is deliberately small enough to be
embedded by a DAP adapter, a JetBrains adapter, or another host without giving
the expression language access to process state.

The accepted grammar is:

```text
expression  := additive
additive    := multiplicative (('+' | '-') multiplicative)*
multiplicative := unary (('*' | '/') unary)*
unary       := '-' unary | primary
primary     := decimal | '(' expression ')'
decimal     := digit+
```

Spaces, tabs, carriage returns, and line feeds may occur between grammar
elements. A decimal literal is checked against the signed 64-bit positive
limit. Unary negation and every binary operation are checked by
`DebuggerEvaluate::evaluate_expression`, so division by zero and signed
overflow return an explicit debugger error instead of producing a wrapped
value.

The parser enforces a 256-byte source limit, a 32-level parenthesis limit, and
a 32-operand limit. These bounds are part of the API contract and are kept in
the parser's private constant modules. Parsing and evaluation mutate only a
local cursor and result; no machine, replay engine, value store, filesystem,
process, or adapter state is read or written.

`DebuggerExpressionParser::expression_parse(bytes, length)` returns a public
`ExpressionParseResult` containing the checked `i64` value, the number of source bytes
consumed, a validity flag, and a structured `DebuggerError`. Hosts can expose
this result directly in their own request model, preserving the same bounded
error behavior across DAP, VS Code, and JetBrains integrations.

The current generic DAP request envelope still has no expression field and
continues to advertise evaluate as unavailable. A future typed DAP request
can call this parser after decoding its expression string, then attach the
result to the protocol response without changing the parser or introducing
host-specific semantics.
