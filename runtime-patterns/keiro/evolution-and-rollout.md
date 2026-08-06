---
type: Standard
title: "Evolution gates and rollout ordering"
description: "The six-layer evolution gate model, composed-workspace compatibility, structural mapping evidence, replay audits, and durable-value rollout ordering"
timestamp: 2026-08-05T19:47:25-07:00
resource: mori://shinzui/keiro-runtime-patterns/docs/keiro-evolution-and-rollout
tags: [keiro, evolution-and-rollout]
status: current
reviews:
  - kind: model
    reviewer: claude-code
    reviewed_at: 2026-07-30T00:43:08Z
    document_timestamp: 2026-07-29T12:40:01-07:00
    scope: technical-accuracy
    outcome: approved
    provider: anthropic
    model: claude-fable-5
    effort: unspecified
    context: >-
      Model technical-accuracy review against the mori-resolved keiro checkout (0.4.0.1 tags plus post-release workspace commits), keiki 0.4.0.0, kiroku-store source, and Hackage release state; verified exported symbols, signatures, version claims, and links.
---

# Evolution gates and rollout ordering

**Catch each evolution hazard at the earliest boundary with enough evidence, then order the rollout by what every live binary may still have to read.**

This standard governs changing a service that already holds durable data. It defines the gate ladder that must pass before deployment and the ordering rules that keep a mixed-version window safe.

## Pass the gates in order

The rule is one sentence: each gate answers a question the earlier ones cannot, so none of them substitutes for another.

1. **The Haskell compiler** checks generated imports and exact types, total `StructuralBinding` signatures, create-once hole implementations, and exact nominal `genericStructuralBinding` correspondence.
2. **`keiro-dsl check` and `diff --since REF`** check one composed service graph and its cross-version change classes. The input may be one `.keiro` file or a `.keiro-workspace` manifest. They cover upcaster chains, event retirement, resolved mapped-type graphs, compatibility vectors, fold/decide changes, and named rollout obligations, but cannot inspect hand-written binding or hole bodies.
3. **The generated conformance harness and historical codec evidence** exercise the executable transducer, current and old payloads, binding laws, mapping branches, projection witnesses, and forward-versus-replay equality. Capture genuine production goldens before declaring a brownfield mapping; synthesized goldens never overwrite them.
4. **Validated stream construction** is the runtime assembly boundary. `mkEventStream` rejects transducer warnings and a codec whose schema version, event tags, or upcaster chain fail `mkCodec`; hand-written streams get the same fail-fast treatment. See [runtime assembly](runtime-assembly.md).
5. **The database-backed replay audit** answers what finite fixtures cannot: whether *real stored histories* still decode, invert, and fold under the candidate binary.
6. **Typed runtime failures and verification telemetry** keep residual failures loud. `HydrationDecodeFailed`, `HydrationReplayFailed`, and `EncodeFailed` remain operational incidents, and post-append replay/snapshot divergence metrics require alerts; they are a backstop, not permission to skip earlier gates.

A decode golden proves decode compatibility only. It is never evidence that an old event still has an inverting edge or folds to the same state.

## Read Compatibility By Surface

`keiro-dsl diff` derives each `ADDITIVE`, `WARNING`, or `BREAKING` headline from six surfaces: `private-history-read`, `old-binary-read-new-events`, `snapshot-hydration`, `public-consumer`, `persisted-identity`, and `consumer-build`. Use `--explain` to see containing paths, failing directions, rollout constraints, and remedies; use `--report-out FILE` for automation. Repeat `--gate SURFACE` only when the service intentionally wants a stricter blocking policy than the default.

Mapped declaration findings are recursive through every command, event, and register use site. A binding symbol or `binding-version` change is not inspectable from specification text, so the differ points to binding laws, fixtures, historical codec comparison, and replay evidence instead of claiming semantic compatibility.

Keep structural coverage as a separate named inventory:

```bash
keiro-dsl check SERVICE-INPUT --coverage-report build/coverage.json
keiro-dsl diff SERVICE-INPUT --since HEAD^ \
  --coverage-report build/coverage-diff.json
```

The reports name structural, opaque, explicit-`Json`, snapshot, and unsupported boundaries; they do not produce one misleading percentage. `--fail-on-opaque` and `--fail-on-opaque-increase` are opt-in operator gates, not universal defaults.

For a workspace, `diff` reconstructs the old manifest and old member set from Git and emits one compatibility stream, coverage report, and replay-impact verdict. Shared changes are classified at every aggregate use site with both declaring and consuming member locations. An unchanged declaration or aggregate moved between members emits `OwnershipMoved` and requires a whole-workspace rescaffold; a service, context, module, or layout authority change emits `WorkspaceAuthorityChanged` beside any actual persisted-identity break.

Tooling should branch on the machine-readable `DiagnosticCode` — `UpcasterChainGap`, `AggGuardTightened`, `AggFoldSurfaceChanged`, `DeprecatedEventReplayHazard`, `EventRetirementInProgress`, `RouterDecideSurfaceChanged`, `ProcessDecideSurfaceChanged`, `ProcessTimerPayloadChanged`, `OwnershipMoved`, `WorkspaceAuthorityChanged` — not on the human-readable explanation.

`IdDomainContractChanged` arrived with language version 3 and is the sharpest of the mapped-declaration codes: it is compatible on `private-history-read`, `old-binary-read-new-events`, and `persisted-identity`; advisory on `snapshot-hydration` and `consumer-build`; **breaking** on `public-consumer`; and it carries a producer-last rollout constraint. Old history stays readable through an internal legacy decoder while current command and public decoding reject the same text, so the rollout order is the whole safety argument. See [enforced identifier domains](identifier-domains.md).

Three more code families arrived with the version-2 source language. `SourceLanguageDeclarationChanged` is a declaration-only change: an all-compatible vector and no semantic action. The nominal family lands on the surface its change actually reaches — `NominalRepresentationChanged` is wire-breaking, `NominalBindingChanged` points at binding laws and replay evidence, `NominalInitialChanged` and `NominalCanonicalTypeChanged` reach snapshot and consumer-build, and `NominalIdDecoderTightened` is an advisory that still obliges a committed old-payload fixture and a targeted audit. See [consumer-owned nominal bindings](nominal-bindings.md) and [Keiro DSL language versions](language-versions.md).

## Gate transducer changes with a targeted replay audit

The rule is one sentence: let the differ decide whether an audit is needed, then audit only the affected streams.

```sh
keiro-dsl diff SERVICE-INPUT --since HEAD --replay-impact-out impact.json
```

The verdict is `{"verdict":"replay-neutral"}` or `{"verdict":"affected","aggregates":{...}}` with sorted event arrays. A neutral verdict touches no data. An affected verdict supplies the conservative event-type set for `Keiro.ReplayAudit` in `AuditTargeted` mode; generated services expose one context-wide `auditTargets :: [SomeAuditTarget]` in declaration order.

Run the candidate binary's audit against a production copy or staging database. Selection is read-only, indexed, budget-bounded, parallel, and resumable; the audit never appends, snapshots, or calls `verifyAndSnapshot`. Correctness compares RFC 8785 canonical bytes and SHA-256 digests serve as review identifiers. **`auditExitCode` returning non-zero means do not deploy.**

Reserve `AuditFull` for one-time runtime cutovers and forensics. It is not a routine deployment gate. Hand-written services have no specification to derive an affected set from, so they supply a conservative set explicitly or choose `AuditFull`.

A first brownfield cutover is the deliberate `AuditFull` case. Capture historical bytes, pass structural or opaque mapping evidence, construct validated streams, then audit a production copy before switching exclusive ownership of the affected categories. See [brownfield Keiro adoption](brownfield-adoption.md).

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
- **Structural mapping changes preserve one wire authority.** The `.keiro` declaration and generated codec own current private-event JSON. A historical codec is test or upcaster machinery only; never route current decode failures through it. Snapshot JSON remains a separate cache boundary and must not be described as generated structural event encoding.
- **Adopting the version-3 identifier domain deploys consumers first.** Every reader that must accept the tightened ID form goes out before the producer starts emitting under it, and old snapshots are expected to miss and rebuild rather than be edited. See [enforced identifier domains](identifier-domains.md).
- **Adopting a version-4 contract TypeID deploys the producer first, after a drain.** `ContractTypeIdDomainChanged` is the opposite ordering from the aggregate case, because the tightening lands on what the service emits. Clear in-flight messages written under the looser contract before consumers move.
- **A field alias change is a wire change even when the Haskell selector is untouched.** `EvtFieldWireKeyChanged` moves persisted and published bytes; `FieldWireKeyCollision` and `FieldWireKeyInvalid` are refusals, not warnings. See [Keiro-dsl adoption](dsl-adoption.md).
- **A changed version-2 hole must bump its `FoldVersion`.** The aggregate fold fingerprint incorporates each hole's token, so bumping it invalidates stale snapshots. Change hole predicate or update behavior without the bump and the fingerprint stays equal, the differ sees nothing, and every existing snapshot is silently trusted against logic that no longer produced it. See [aggregate scalar expressions and transition ownership](aggregate-expressions.md).

`mkEventStreamUnchecked` skips every gate at the stream boundary. It is emergency forensics, never a rollout workaround.

For the full narrative and per-rule failure modes, see the keiro repo's `docs/guides/evolution-and-replayability.md` and `docs/user/deploy-ordering.md`.

## Related Patterns

- [Keiro-dsl adoption](dsl-adoption.md)
- [Enforced identifier domains](identifier-domains.md)
- [Behavior conformance and obligations](behavior-conformance.md)
- [Runtime assembly](runtime-assembly.md)
- [Read models and projections](read-models-and-projections.md)
- [Event schema evolution](../keiki/event-schema-evolution.md)
- [Workflow reliability and recovery](workflow-reliability.md)
- [Brownfield Keiro adoption](brownfield-adoption.md)
- [Composable service workspaces](service-workspaces.md)
- [Consumer-owned nominal bindings](nominal-bindings.md)
- [Aggregate scalar expressions and transition ownership](aggregate-expressions.md)
