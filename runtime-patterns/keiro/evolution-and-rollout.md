---
type: Standard
title: "Evolution gates and rollout ordering"
description: "The five evolution gates, the replay-impact verdict and targeted audit, and durable-value rollout ordering"
timestamp: 2026-07-23T16:55:16-07:00
resource: mori://shinzui/keiro-runtime-patterns/docs/keiro-evolution-and-rollout
tags: [keiro, evolution-and-rollout]
status: current
---

# Evolution gates and rollout ordering

**Catch each evolution hazard at the earliest boundary with enough evidence, then order the rollout by what every live binary may still have to read.**

This standard governs changing a service that already holds durable data. It defines the gate ladder that must pass before deployment and the ordering rules that keep a mixed-version window safe.

## Pass the gates in order

The rule is one sentence: each gate answers a question the earlier ones cannot, so none of them substitutes for another.

1. **`keiro-dsl check`** rejects what is provably invalid in one specification: upcaster chain gaps, duplicate rungs, a `retiring` event with no live emitter, a replay-only transition that emits nothing.
2. **`keiro-dsl diff --since REF`** classifies what needs the old and new declarations together: a vanished upcaster rung is `BREAKING`; guard tightening, fold-surface change, decide-surface change, and timer-payload change are advisories that still require operator action.
3. **Validated stream construction** is the runtime boundary. `mkEventStream` now rejects a codec whose schema version, event tags, or upcaster chain fail `mkCodec` — hand-written streams get the same fail-fast treatment as generated ones. See [runtime assembly](runtime-assembly.md).
4. **Versioned JSON goldens** exercise `decodeRaw` against the current codec in conformance CI. Capture them with `keiro-dsl diff --emit-goldens DIR` while both specifications still exist, and embed them with `keiro-dsl scaffold --goldens DIR`. Synthesis never overwrites an existing file, so hand-captured production payloads stay authoritative.
5. **The database-backed replay audit** answers what static fixtures cannot: whether *real stored histories* still invert and fold under the candidate binary.

A decode golden proves decode compatibility only. It is never evidence that an old event still has an inverting edge or folds to the same state.

Tooling should branch on the machine-readable `DiagnosticCode` — `UpcasterChainGap`, `AggGuardTightened`, `AggFoldSurfaceChanged`, `DeprecatedEventReplayHazard`, `EventRetirementInProgress`, `RouterDecideSurfaceChanged`, `ProcessDecideSurfaceChanged`, `ProcessTimerPayloadChanged` — not on the human-readable explanation.

## Gate transducer changes with a targeted replay audit

The rule is one sentence: let the differ decide whether an audit is needed, then audit only the affected streams.

```sh
keiro-dsl diff spec.keiro --since HEAD --replay-impact-out impact.json
```

The verdict is `{"verdict":"replay-neutral"}` or `{"verdict":"affected","aggregates":{...}}` with sorted event arrays. A neutral verdict touches no data. An affected verdict supplies the conservative event-type set for `Keiro.ReplayAudit` in `AuditTargeted` mode; generated services expose one context-wide `auditTargets :: [SomeAuditTarget]` in declaration order.

Run the candidate binary's audit against a production copy or staging database. Selection is read-only, indexed, budget-bounded, parallel, and resumable; the audit never appends, snapshots, or calls `verifyAndSnapshot`. Correctness compares RFC 8785 canonical bytes and SHA-256 digests serve as review identifiers. **`auditExitCode` returning non-zero means do not deploy.**

Reserve `AuditFull` for one-time runtime cutovers and forensics. It is not a routine deployment gate. Hand-written services have no specification to derive an affected set from, so they supply a conservative set explicitly or choose `AuditFull`.

## Retire an event in two stages

Deleting a live edge breaks hydration for every stream that still contains its events. The sanctioned remedy is a **replay-only** transition: an edge never taken by forward stepping that keeps historical events invertible and defines how they fold today.

1. Mark the event `retiring`. Its live emitting transition stays.
2. At cutover, mark the event `deprecated` and change that transition to `replay-only`.

Keep the replay-only edge until every affected stream is terminal, truncated, or passes the replay audit; deleting it earlier recreates exactly the hydration break it fixed. Deprecating an event with no replay-only emitter raises `DeprecatedEventReplayHazard`.

When a live guard tightens and no twin exists, `keiro-dsl diff` computes and prints a paste-ready replay-only twin with the `AggGuardTightened` advisory. It is printed, never applied — whether history stays replayable or gets truncated instead is a business decision.

## Order the rollout by durable value

The rule is one sentence: inventory every durable value whose decoder or decision logic changes, then confirm each binary alive during the window can read everything the others may write.

- **Aggregate codec bumps admit no mixed versions.** One `schemaVersion` serves both writing and decoding, so an old replica hydrating a stream that contains a new-version event returns `VersionAhead`. Use stop-the-world or blue/green with one version exclusively owning a stream category. After the first new-version append the deploy is roll-forward-only; rollback means restore from backup.
- **Versioned job queues deploy workers before producers.** A future `{v,t,data}` envelope returns `JobPayloadFromFuture` and burns the delivery budget; size `maxRetries × defaultRetryDelay` to cover the window. Generated workqueues start at schema version 1 with `keiroJobCodec`. Never switch a non-empty queue between bare and enveloped payloads without a drain or a transitional dual decoder.
- **Router and process-manager decide changes need a drained redelivery window.** Deterministic target-command ids confirm overlaps as benign duplicates, so an undrained change merges old and new fan-out silently with no error. Hole-only decide changes are invisible to the differ; the drain rule applies anyway.
- **Timer payloads, integration contracts, and workflow step results have no automatic migration.** Firers and consumers learn new shapes before producers write them, old decoders stay until backlogs drain, and a changed workflow step result gets a **new step name** rather than a changed type.
- **Every aggregate append goes through the codec boundary.** A direct Kiroku write without `encodeForAppend` is stamped version 1 forever, and the first codec bump then runs a current-shape payload through the version-1 upcaster chain.

`mkEventStreamUnchecked` skips every gate at the stream boundary. It is emergency forensics, never a rollout workaround.

For the full narrative and per-rule failure modes, see the keiro repo's `docs/guides/evolution-and-replayability.md` and `docs/user/deploy-ordering.md`.

## Related Patterns

- [Keiro-dsl adoption](dsl-adoption.md)
- [Runtime assembly](runtime-assembly.md)
- [Read models and projections](read-models-and-projections.md)
- [Event schema evolution](../keiki/event-schema-evolution.md)
- [Workflow reliability and recovery](workflow-reliability.md)
