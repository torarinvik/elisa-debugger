# Managed concurrency analysis

The managed concurrency analyzer accepts an observed access stream and emits a
bounded race report. It is an analysis of the supplied recording; it is not a
proof that an execution is race free.

## Observed access contract

Each access carries:

- an event ordinal and logical task ID;
- an `AllocationIdentity` containing allocation ID, generation, and offset;
- `Read` or `Write` access kind;
- a vector clock captured at the access; and
- an optional source span.

Allocation generation is part of the identity. A slot reused by a later
allocation therefore cannot be reported as racing with an earlier lifetime.
Logical task IDs are used instead of OS thread IDs, so restoring a checkpoint
on another host does not merge unrelated tasks.

## Finding rule

The analyzer reports a pair when all of these conditions hold:

1. both accesses identify the same allocation generation and offset;
2. the accesses belong to different logical tasks;
3. at least one access is a write; and
4. neither vector clock happens before the other.

Read/read pairs, accesses ordered by the captured synchronization relation,
different offsets, and different allocation generations do not produce a
finding. Each pair is emitted once, in the order in which the later observed
access was added.

## Bounds and incompleteness

The current report accepts at most 256 accesses and retains at most 128 race
findings. Invalid access identities, out-of-order event ordinals, and writes
after finalization are rejected with typed errors. Capacity exhaustion marks
the report incomplete and retryable. A complete report only means that every
supplied access was analyzed within those bounds.

The report explicitly carries `observed_only`. Clients must preserve that
qualification in their UI and output. A controlled deterministic scheduler
can expose only the schedules and accesses that were recorded; it cannot
establish native weak-memory race freedom. Future runtime instrumentation may
feed this contract without changing the finding rule.
