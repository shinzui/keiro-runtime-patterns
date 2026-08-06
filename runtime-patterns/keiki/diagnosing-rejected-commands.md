---
type: Guide
title: "Diagnosing Rejected Commands with `stepEither`"
description: "Using stepEither and StepFailure to learn why a command was rejected"
timestamp: 2026-08-03T02:56:33Z
generated:
  by: human:nadeem
  at: "2026-08-03T02:56:33Z"
resource: mori://shinzui/keiro-runtime-patterns/docs/keiki-diagnosing-rejected-commands
tags: [keiki, diagnosing-rejected-commands]
status: current
reviews:
  - kind: model
    reviewer: claude-code
    reviewed_at: 2026-07-30T00:43:08Z
    document_timestamp: 2026-07-22T16:35:21Z
    scope: technical-accuracy
    outcome: changes-requested
    provider: anthropic
    model: claude-fable-5
    effort: unspecified
    context: >-
      Model technical-accuracy review against the mori-resolved keiki v0.4.0.0 checkout, its changelogs, and the keiro consumer source; changes requested: the NoMatchingEdge taxonomy predates keiki 0.3's Live-edge filtering of forward candidates.
  - kind: model
    reviewer: claude-code
    reviewed_at: 2026-07-30T01:11:55Z
    document_timestamp: 2026-07-30T01:11:55Z
    scope: technical-accuracy
    outcome: approved
    provider: anthropic
    model: claude-fable-5
    effort: unspecified
    context: >-
      Model re-review of the correction against Keiki.Core stepEither: the taxonomy now reflects Live-edge candidate filtering and step's rejection on ambiguity.
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
  false. Since Keiki 0.3, only `Live` edges are forward candidates, yet the summaries
  still describe every edge — a `ReplayOnly` twin can therefore appear among the rejected
  summaries even though it was never eligible to fire. The summaries locate the rejected
  edges (each by `EdgeRef`) so you can report which guard turned the command away.
- **`AmbiguousEdges s summaries`** — **two or more guards matched the same command.** This
  is a single-valuedness violation: `step` rejects the command with no explanation, hiding a real
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

## Take `stepDetailedEither` When Success Needs Evidence

`stepEither` reports why a command was rejected but says nothing about *which* edge accepted
one. Keiki 0.7 adds `stepDetailedEither`, whose `Right` is a `StepSuccess` carrying the
construction-local `EdgeRef`, the selected `EdgeMode` (always `Live` for forward execution),
the post-state, the register file, and the ordered output word — including `[]` for an
accepted epsilon-output edge.

```haskell
case stepDetailedEither aggregateTransducer (vertex, regs) command of
  Right success ->
    recordAcceptedEdge (stepSuccessEdge success) (stepSuccessOutputs success)
  Left failure -> reject failure
```

Use it for conformance reports, coverage accounting, and audit trails that must name the
rule that fired. Failures are identical to `stepEither`'s, and `stepEither` keeps its
signature by erasing this evidence — so the choice is per call site, not per service.

Replay has the same diagnostic shape. `ReplayStepFailure` explains hydration through
`ReplayNoInvertingEdge`, `ReplayAmbiguousInversions`, and `ReplayQueueMismatch`, just as
`StepFailure` explains forward command execution. See
[Structured Replay and Hydration](./structured-replay-and-hydration.md); never replace a
replay failure with a partial state.

## Related Patterns

- [Keiki Transducer Best Practices](./transducer-best-practices.md) explains when to choose `step` or `stepEither`.
- [Build-Time Validation](./build-time-validation.md) prevents the ambiguity defects surfaced here at runtime.
- [Structured Replay and Hydration](./structured-replay-and-hydration.md) covers the replay-side failure taxonomy.
