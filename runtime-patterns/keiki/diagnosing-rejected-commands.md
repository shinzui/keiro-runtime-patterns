---
type: Guide
title: "Diagnosing Rejected Commands with `stepEither`"
description: "Using stepEither and StepFailure to learn why a command was rejected"
timestamp: 2026-07-22T09:35:21-07:00
resource: mori://shinzui/keiro-runtime-patterns/docs/keiki-diagnosing-rejected-commands
tags: [keiki, diagnosing-rejected-commands]
status: current
---

# Diagnosing Rejected Commands with `stepEither`

**Use structured rejection reasons to separate expected command refusal from transducer defects.**

`step` is Keiki's pure entry point for running one command. On success it returns
`Just (nextVertex, nextRegs, events)`; on any failure it returns a single, opaque
`Nothing`. That is fine when all you need is accept/reject, but it hides *why* a command was
rejected — and one of those reasons (ambiguity) is a latent bug you want surfaced, not
swallowed.

`stepEither` is the diagnostic sibling. It returns the reason on the `Left` and the
**identical** success triple on the `Right`:

```haskell
stepEither ::
  (BoolAlg phi (RegFile rs, ci)) =>
  SymTransducer phi rs s ci co ->
  (s, RegFile rs) ->
  ci ->
  Either (StepFailure s) (s, RegFile rs, [co])
```

`step` is unchanged and still available; `stepEither` is purely additive, so adopting it is
zero-risk.

## The three failure reasons

```haskell
data StepFailure s
  = NoOutgoingEdges s                        -- the vertex has no outgoing edges at all
  | NoMatchingEdge  s [RejectedEdgeSummary s] -- edges exist, none matched the command
  | AmbiguousEdges  s [MatchedEdgeSummary s]  -- two or more guards matched (nondeterminism!)
```

- **`NoOutgoingEdges s`** — the current vertex `s` is terminal or simply has no edges. A
  command arriving here is always rejected.
- **`NoMatchingEdge s summaries`** — there were candidate edges but none matched: the
  command's constructor was wrong for every edge, or every matching-constructor guard was
  false. The summaries locate the rejected edges (each by `EdgeRef`) so you can report which
  guard turned the command away.
- **`AmbiguousEdges s summaries`** — **two or more guards matched the same command.** This
  is a single-valuedness violation: `step` silently picks one (or rejects), hiding a real
  modeling bug. `stepEither` makes it visible. It is the runtime witness of the same
  property `validateTransducer`'s `NondeterministicPair` proves at build time — see
  [build-time-validation.md](./build-time-validation.md).

## Use it in command processors

Where a command processor surfaces rejection reasons to a caller, a log, or a metric,
prefer `stepEither`:

```haskell
runCommand vertex regs command =
  case stepEither aggregateTransducer (vertex, regs) command of
    Right (nextVertex, nextRegs, events) ->
      Right (events, nextVertex, nextRegs)
    Left (NoOutgoingEdges s) ->
      Left (Rejected ("no transitions from state " <> show s))
    Left (NoMatchingEdge s _) ->
      Left (Rejected ("command not valid in state " <> show s))
    Left (AmbiguousEdges s _) ->
      -- treat as a defect, not a normal rejection: alert and fail loudly
      Left (Defect ("ambiguous transition in state " <> show s))
```

Treat `AmbiguousEdges` as a defect path, not an ordinary rejection — if it can happen at
runtime, the transducer has overlapping guards that `validateTransducer` /
`checkTransitionDeterminismSym` should have caught. Keep `step` for hot paths where a bare
accept/reject is all you need.

Replay has the same diagnostic shape. `ReplayStepFailure` explains hydration through
`ReplayNoInvertingEdge`, `ReplayAmbiguousInversions`, and `ReplayQueueMismatch`, just as
`StepFailure` explains forward command execution. See
[Structured Replay and Hydration](./structured-replay-and-hydration.md); never replace a
replay failure with a partial state.

## Related Patterns

- [Keiki Transducer Best Practices](./transducer-best-practices.md) explains when to choose `step` or `stepEither`.
- [Build-Time Validation](./build-time-validation.md) prevents the ambiguity defects surfaced here at runtime.
- [Structured Replay and Hydration](./structured-replay-and-hydration.md) covers the replay-side failure taxonomy.
