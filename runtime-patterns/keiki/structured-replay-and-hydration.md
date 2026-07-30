---
type: Guide
title: "Structured Replay and Hydration"
description: "Diagnosing hydration failures with reconstituteEither, replayEvents, and ReplayFailure"
timestamp: 2026-07-23T16:55:16-07:00
resource: mori://shinzui/keiro-runtime-patterns/docs/keiki-structured-replay-and-hydration
tags: [keiki, structured-replay-and-hydration]
status: current
reviews:
  - kind: model
    reviewer: claude-code
    reviewed_at: 2026-07-30T00:43:08Z
    document_timestamp: 2026-07-23T16:55:16-07:00
    scope: technical-accuracy
    outcome: approved
    provider: anthropic
    model: claude-fable-5
    effort: unspecified
    context: >-
      Model technical-accuracy review against the mori-resolved keiki v0.4.0.0 checkout, its changelogs, and the keiro consumer source; verified exported symbols, signatures, version claims, and links.
---

# Structured Replay and Hydration

**Use the `Either` replay surface so a corrupt, ambiguous, or truncated event log can never look like an ordinary cache miss.**

Replay—also called hydration or reconstitution—rebuilds a transducer's control state and registers from persisted private events. Keiki 0.2 makes structured replay the primary API: use `reconstituteEither` for a complete stream, `replayEvents` for resumable pages, and the lower-level `Either` functions when a caller owns the starting state or consumes one event at a time.

## Prefer Structured Replay Over `Maybe`

The historical `reconstitute`, `applyEvents`, and `applyEventStreaming` functions remain compatibility wrappers. They discard the failure reason and return `Nothing`, so new runtime code should use their structured counterparts.

```haskell
-- WRONG: every replay defect collapses into an opaque Nothing.
case reconstitute orderTransducer storedEvents of
  Nothing -> loadWithoutKnowingWhy
  Just hydrated -> useHydrated hydrated

-- CORRECT: record the exact failing position and reason.
case reconstituteEither orderTransducer storedEvents of
  Right (state, regs) -> useHydrated (state, regs)
  Left ReplayFailure
    { replayFailedIndex
    , replayFailureReason
    } -> reportReplayFailure replayFailedIndex replayFailureReason
```

Do not fall back to a partial state after `Left`. The returned failure describes why the supplied log cannot establish a valid durable state.

## Choose The Replay Function By Boundary

`reconstituteEither` replays a complete event log from the transducer's `initial` vertex and `initialRegs`. It succeeds only at a stable vertex and returns `Either (ReplayFailure s co) (s, RegFile rs)`.

`applyEventsEither` starts from a caller-supplied stable `(state, registers)` pair and replays one complete chunk. It rejects a chunk that ends part-way through a multi-event edge.

`applyEventStreamingEither` consumes one observed event from an `InFlight` wrapper and a register file. It is the primitive for event-at-a-time readers.

`replayEvents` folds that primitive over a list from an arbitrary wrapper seed. It may return a final `InFlight` value when a page ends mid-chain, allowing the next page to resume safely:

```haskell
case replayEvents
  orderTransducer
  (Settled startingState, startingRegs)
  pageOfEvents of
  Right (nextWrapper, nextRegs) ->
    saveReplayCursor nextWrapper nextRegs
  Left failure ->
    reportFailure failure
```

Use `replayEvents` for pagination. Use `applyEventsEither` or `reconstituteEither` when reaching the end of input must prove that no event remains pending.

## Understand `Settled` And `InFlight`

`InFlight s co` represents streaming replay state:

- `Settled s` means replay is at a stable control vertex. The next observed event must be the head emission of exactly one outgoing edge.
- `InFlight s [co]` means replay has already selected a multi-event edge, applied its register update, and reached its target vertex `s`. The queue contains the remaining evaluated events in order.

While in flight, each observed event is equality-checked against the queue head. Register updates are not applied again; they happened when replay moved from `Settled` into `InFlight`.

This explains the head-event rule. Edge selection and command inversion happen before the tail queue exists, so every consumed command field must be recoverable from the first emitted event. A clean `validateTransducer defaultValidationOptions` result, subject to honest constructor descriptors, guarantees that the transducer can replay every log it produces.

## Diagnose One-Event Failures

`ReplayStepFailure s co` explains why one event could not advance the wrapper:

- `ReplayNoInvertingEdge s [RejectedEdgeSummary s]` means no outgoing edge's head event matches the observed event. An empty summary list means the vertex has no outgoing edges.
- `ReplayAmbiguousInversions s [MatchedEdgeSummary s]` means more than one edge could have produced the event. This is the replay twin of forward execution's `AmbiguousEdges`.
- `ReplayQueueMismatch s co [co]` means an in-flight event differs from the next expected event; the list is the remaining queue.

These diagnostics deliberately carry no register values. They summarize state-machine structure without dumping durable application state. Events are included only where they identify the failed comparison, because the event log is already observable data.

## Account For Replay-Only Edges When Reading A Failure

From keiki 0.3, an `Edge` carries an `EdgeMode` of `Live` or `ReplayOnly`. A replay-only edge is never taken by forward stepping; it exists so events emitted under a retired rule keep an inverting edge, and its update defines how that history folds today.

Inversion is two-phase. Candidates are sought among `Live` edges first, and `ReplayOnly` edges are tried only when no live edge matches. Ambiguity is judged within the phase that produced the candidates, so a live edge and its replay-only twin cannot conflict with each other — an overlap yields a deterministic live-first preference instead.

This changes how to read a failure. A `ReplayNoInvertingEdge` after a guard tightening usually means the required replay-only twin was never added, or was deleted before every affected stream was terminal or truncated. Add or restore the twin; do not loosen the live guard to make replay succeed. See [evolution gates and rollout ordering](../keiro/evolution-and-rollout.md).

## Diagnose Whole-Log Failures

`ReplayFailureReason s co` wraps a one-event failure as `ReplayEventFailed`, or reports `ReplayLogTruncated [co]` when a strict replay reaches end of input with a non-empty in-flight queue.

`ReplayFailure s co` adds three fields:

- `replayFailedIndex` is the zero-based position of the event that failed. For truncation it equals the input length—the position where the next event was expected.
- `replayFailedState` is the `InFlight` wrapper immediately before failure.
- `replayFailureReason` is the structured reason above.

Log the index and reason with the stream identity. Treat `ReplayAmbiguousInversions`, unexpected `ReplayNoInvertingEdge`, and queue mismatches as durable-data or model defects that require investigation; do not recategorize them as normal command rejection.

## Test Both Complete And Paged Replay

For every aggregate and orchestrator transducer, generate events through forward `stepEither`, then prove that `reconstituteEither` returns the same stable state and registers. Add a paged case where one page ends in `InFlight` and the next page resumes. For every multi-event edge, remove the final event and assert that strict replay reports `ReplayLogTruncated` at the input length.

## Related Patterns

- [Build-Time Validation](./build-time-validation.md) prevents the replay shapes described here from being emitted.
- [Keiki Transducer Best Practices](./transducer-best-practices.md) defines the head-event and emit-every-field authoring rules.
- [Diagnosing Rejected Commands](./diagnosing-rejected-commands.md) covers the parallel forward-execution diagnostics.
- [Upgrading to Keiki 0.2](./upgrading-to-keiki-0-2.md) explains why the structured surface replaces the removed Decider facade.
