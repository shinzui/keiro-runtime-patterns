---
type: Standard
title: "Command cycle and errors"
description: "Command hydration, decision, append, projection, and prescriptive error handling"
timestamp: 2026-07-22T10:48:06-07:00
resource: mori://shinzui/keiro-runtime-patterns/docs/keiro-command-cycle-and-errors
tags: [keiro, command-cycle-and-errors]
status: current
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

Keiro stores durable dispatch and subscription failures in `keiro.keiro_dead_letters`. Policies such as `RejectedDeadLetter` and `PoisonDeadLetter` retain deliveries that cannot safely advance. After correcting the handler, codec, or definition, use `replaySubscriptionDeadLetters` to re-drive Kiroku subscription dead letters; do not treat replay as a substitute for fixing the cause.

For table layout and operational controls, see the keiro repo's `docs/user/dead-letters.md`.

## Related Patterns

- [Runtime assembly](runtime-assembly.md)
- [Keiki transducer best practices](../keiki/transducer-best-practices.md)
- [The two-schema arrangement](two-schema-arrangement.md)
