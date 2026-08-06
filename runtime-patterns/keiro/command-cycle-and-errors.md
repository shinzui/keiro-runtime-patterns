---
type: Standard
title: "Command cycle and errors"
description: "Command hydration, decision, append, projection, and prescriptive error handling"
timestamp: 2026-07-30T01:11:55Z
generated:
  by: human:nadeem
  at: "2026-07-30T01:11:55Z"
resource: mori://shinzui/keiro-runtime-patterns/docs/keiro-command-cycle-and-errors
tags: [keiro, command-cycle-and-errors]
status: current
reviews:
  - kind: model
    reviewer: claude-code
    reviewed_at: 2026-07-30T00:43:08Z
    document_timestamp: 2026-07-22T17:48:06Z
    scope: technical-accuracy
    outcome: changes-requested
    provider: anthropic
    model: claude-fable-5
    effort: unspecified
    context: >-
      Model technical-accuracy review against the mori-resolved keiro checkout (0.4.0.1 tags plus post-release workspace commits), keiki 0.4.0.0, kiroku-store source, and Hackage release state; changes requested: subscription failures are misattributed to keiro.keiro_dead_letters; they park in kiroku.dead_letters.
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
      Model re-review of the correction against Keiro.DeadLetter.Schema and docs/user/dead-letters.md: dispatch rejections and subscription failures are now attributed to their owning tables.
---

# Command cycle and errors

**Classify every `CommandError`; treat `CommandAmbiguous` as a bug, never a business rejection.**

This standard defines how command callers and workers interpret keiro's decision, hydration, and append failures.

## Follow the five-stage cycle

The rule is one sentence: hydrate, decide, append, optionally project inline, then return the `CommandResult`.

Hydration reads the stream and replays it through the keiki transducer, using a valid snapshot as an optional seed. The runner calls `stepEither` to decide. It appends emitted events with optimistic concurrency and retries conflicts within `RunCommandOptions`. A transactional runner may update inline projections before commit. The caller finally receives the target, stream version, optional global position, and append count.

## Classify before handling

Use `commandErrorClass :: CommandError -> Text` as the stable, low-cardinality telemetry label. Apply these policies:

- `CommandRejected` is the only normal decision rejection. Return the domain rejection to a synchronous caller, or apply the worker's declared rejection policy.
- `CommandAmbiguous [Int]` means multiple edges matched. Halt or dead-letter the delivery, alert the owning team, and fix the aggregate definition.
- `HydrationDecodeFailed`, `HydrationReplayFailed`, and `HydrationGapDetected` mean stored history cannot reproduce state. Stop that stream and alert; repair the codec/replay contract, or restore the truncated prefix or a covering snapshot for a gap.
- `EncodeFailed` is an application contract defect. Do not retry unchanged input; halt or dead-letter and alert.
- `StoreFailed` is a non-retried store failure at this boundary. Surface service unavailability and retain the cause for operators.
- `RetryExhausted` means optimistic-concurrency attempts were consumed. A request boundary may report a retryable failure; a durable worker follows its retry/dead-letter policy.
- `ConflictFixpoint` usually exposes a soft-deleted stream that still conflicts while reads show no progress. Stop and repair the stream lifecycle rather than loop.

`HydrationReplayFailed` further classifies replay as `HydrationNoInvertingEdge`, `HydrationAmbiguousInversion`, `HydrationQueueMismatch`, or `HydrationTruncatedChain`; each is a stored-history or definition incompatibility, not a transient command rejection.

## Ambiguity is never benign

The glossary rule is normative: **`CommandAmbiguous` is never benign.** Multiple matching edges make the aggregate definition nondeterministic. A worker must not acknowledge and continue. Keiro-dsl enforces the same posture by reporting `AmbiguousMarkedBenign` when a specification maps ambiguity to a fired/success outcome.

## Replay dead letters after repair

Keiro records rejected process-manager and router dispatches in `keiro.keiro_dead_letters`; each row is one failed dispatch whose source subscription event counts as handled and may advance its checkpoint. Terminal subscription failures — including deliveries a `PoisonDeadLetter` policy parks — land in Kiroku-owned `kiroku.dead_letters` instead. After correcting the handler, codec, or definition, use `replaySubscriptionDeadLetters` to re-drive Kiroku subscription dead letters; do not treat replay as a substitute for fixing the cause.

For table layout and operational controls, see the keiro repo's `docs/user/dead-letters.md`.

## Related Patterns

- [Runtime assembly](runtime-assembly.md)
- [Keiki transducer best practices](../keiki/transducer-best-practices.md)
- [The two-schema arrangement](two-schema-arrangement.md)
