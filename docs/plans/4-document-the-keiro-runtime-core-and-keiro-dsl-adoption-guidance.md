---
id: 4
slug: document-the-keiro-runtime-core-and-keiro-dsl-adoption-guidance
title: "Document the keiro runtime core and keiro-dsl adoption guidance"
kind: exec-plan
created_at: 2026-07-22T14:55:29Z
intention: intention_01ky5agv9gehqa8dbw03cdcpwv
master_plan: "docs/masterplans/1-keiro-runtime-standards-docs-and-seihou-blueprints.md"
---

# Document the keiro runtime core and keiro-dsl adoption guidance

This ExecPlan is a living document. The sections Progress, Surprises & Discoveries,
Decision Log, and Outcomes & Retrospective must be kept up to date as work proceeds.
If durable project context changes, update or create ADRs in docs/adr/ in the same change.


## Purpose / Big Picture

After this plan is implemented, this repository has a new `keiro/` documentation area — nine terse, prescriptive Markdown files plus registry entries in `mori.dhall` — that tells a developer or coding agent exactly how to assemble a service on the keiro 0.3 runtime and, crucially, when to adopt the keiro-dsl specification toolchain and when to skip it. Today that knowledge exists only spread across the keiro repository's twenty-two user docs, fourteen guides, two changelogs, and the `jitsurei` example application; nothing states the DSL adoption tradeoff at all, and nothing in this repository covers keiro. After the change, running `mori registry docs shinzui/keiro-runtime-patterns` lists nine new `keiro-*` documents, `keiro/README.md` indexes them all, and every API symbol the docs name can be located verbatim in the keiro source tree at `/Users/shinzui/Keikaku/bokuno/keiro`. These docs are also the *core glossary* the rest of the initiative links to: "validated event stream", "the two-schema arrangement", "snapshots are advisory", and "`CommandAmbiguous` is never benign" are defined here and nowhere else (MasterPlan Integration Point 4).

You can see it working by opening `keiro/README.md`, following any link, and cross-checking any named function against the keiro source — the Validation section gives an exact script that does this mechanically — and by type-checking `mori.dhall` with `dhall`.


## Progress

- [x] Milestone 1: `keiro/` directory created; `keiro/two-schema-arrangement.md` (core glossary entry) written; `keiro/README.md` stub index created. (2026-07-22 17:45Z)
- [ ] Milestone 2: `keiro/runtime-assembly.md` written.
- [ ] Milestone 2: `keiro/command-cycle-and-errors.md` written.
- [ ] Milestone 3: `keiro/read-models-and-projections.md` written.
- [ ] Milestone 3: `keiro/durable-workflows.md` written.
- [ ] Milestone 3: `keiro/telemetry.md` written.
- [ ] Milestone 4: `keiro/dsl-adoption.md` (the centerpiece decision doc) written.
- [ ] Milestone 4: `keiro/gotchas.md` written.
- [ ] Milestone 5: `keiro/README.md` finalized as a complete index.
- [ ] Milestone 5: nine `Schema.DocRef` entries appended to `mori.dhall`; `dhall type` passes.
- [ ] Milestone 5: symbol cross-check script passes against the keiro source tree.
- [ ] Milestone 5: link-integrity check passes (kiroku forward links noted as expected dangles until EP-2).


## Surprises & Discoveries

Document unexpected behaviors, bugs, optimizations, or insights discovered during
implementation. Provide concise evidence.

- Observation: `mkEventStreamOrThrow` is intentionally documented upstream for generated definitions and test fixtures with a sibling proof; hand-authored startup wiring should use `mkEventStream` and handle `Left [EventStreamWarning]` explicitly.
  Evidence: `keiro-core/src/Keiro/EventStream/Validate.hs` documents the throwing helper's narrow use and labels `mkEventStreamUnchecked` for tests or emergency forensics.

- Observation: snapshots are advisory only while the retained log is sufficient to hydrate from the beginning. After per-stream history truncation, a valid snapshot covering the hidden prefix is required or hydration returns `HydrationGapDetected`.
  Evidence: command hydration falls back after missing, corrupt, or shape-mismatched snapshots, but checks the retained lower bound before replaying in `keiro/src/Keiro/Command.hs`.

- Observation: the resume worker is required for suspended workflows and the timer worker is required only when `sleep` is used; `runWorkflowGcWorker` is optional retention housekeeping, not part of progress.
  Evidence: `keiro/src/Keiro/Workflow/{Resume,Sleep,Gc}.hs` separates resumption, one-pass timer polling, and explicitly optional terminal-instance collection.

- Observation: EP-2 already appended its DocRefs after the final keiki block, so the planned insertion point is no longer the end of the registry.
  Evidence: the current `mori.dhall` has complete kiroku and migration blocks after `keiki-json-event-codecs`; EP-4 will append its block without reordering earlier plans' entries.


## Decision Log

- Decision: The doc area is nine files — README index, seven standards docs, and one gotchas doc — rather than three or four larger files.
  Rationale: matches the granularity of the existing `keiki/` corpus (eight focused files), gives each `mori.dhall` DocRef a single crisp subject, and lets EP-5/EP-6 link to exactly one glossary doc per term instead of a section anchor inside a monolith.
  Date: 2026-07-22

- Decision: The four cross-cutting gotchas (alternative-composition trap, `$all` throughput ceiling, transactional-runner resource requirement, Kafka is BYO) get a dedicated `keiro/gotchas.md`, with each topical doc cross-linking to the relevant entry.
  Rationale: three of the four span more than one topical doc; a single discoverable file avoids duplicating the warnings and matches the "terse prescriptive layer" posture.
  Date: 2026-07-22

- Decision: References to keiro's own documentation are written as "keiro repo: `docs/user/<file>.md`" plus the instruction to locate the repo with `mori registry show shinzui/keiro --full`, never as absolute filesystem paths and never as relative links.
  Rationale: relative links cannot cross repositories; absolute paths are machine-specific; mori is the fleet-standard discovery mechanism (per this repo's global instructions).
  Date: 2026-07-22

- Decision: Cross-links to `../keiki/*.md` are used freely (those files exist today); cross-links to `../kiroku/*.md` (owned by EP-2) are written now and allowed to dangle until EP-2 lands.
  Rationale: MasterPlan dependency section explicitly sanctions this ("if EP-4 runs first, it leaves relative links to doc paths the earlier plans will create"). The link checker in Validation whitelists the `../kiroku/` prefix.
  Date: 2026-07-22

- Decision: DocRef kinds are restricted to `Guide` and `BestPractice` — `Guide` for the index, the two-schema arrangement, durable workflows, and the DSL adoption decision; `BestPractice` for runtime assembly, command cycle, read models, telemetry, and gotchas. Audience is `Module` for all nine.
  Rationale: the parent MasterPlan prescribes "audience Module; kinds Guide/BestPractice as fitting" for this plan; decision/orientation content reads as Guide, prescriptive rules read as BestPractice.
  Date: 2026-07-22

- Decision: The docs describe the runtime as "keiro 0.3" but attribute the behavioral contract to the 0.2.0.0 release, stating this explicitly in `keiro/README.md`.
  Rationale: 0.3.0.0 (2026-07-14) was a dependency-realignment release with no source changes to `keiro-core`, `keiro`, or `keiro-dsl`; every behavioral fact below (dedicated `keiro` schema, mandatory registration, strict validation, dead letters) landed in 0.2.0.0 (2026-07-13). Saying so prevents readers from hunting the 0.3 changelog for semantics that are not there.
  Date: 2026-07-22

- Decision: Hand-authored service assembly uses `mkEventStream` with explicit startup failure reporting, while generated code and fixtures may use `mkEventStreamOrThrow` when the validation proof is colocated.
  Rationale: this follows the helper's source-level contract and preserves structured warnings at the application boundary.
  Date: 2026-07-22

- Decision: The snapshot standard includes a truncation exception: deletion is safe only while the event store retains a replayable prefix.
  Rationale: stating that snapshots are unconditionally disposable would turn a performance mechanism into an unnoticed correctness dependency after compaction.
  Date: 2026-07-22

- Decision: Deploy workflow workers by capability: resume for suspended workflows, timer polling for `sleep`, external signal delivery for awakeables, and optional GC according to retention policy.
  Rationale: the implementation exposes independent progress mechanisms; claiming that all three bundled workers are mandatory would overstate the runtime contract.
  Date: 2026-07-22


## Outcomes & Retrospective

Summarize outcomes, gaps, and lessons learned at major milestones or at completion.
Compare the result against the original purpose. Before marking the plan complete,
distill durable project context from the Decision Log, Surprises & Discoveries, and
this section into docs/adr/. Keep task-local execution details here.

(To be filled during and after implementation.)


## Context and Orientation

This repository, `/Users/shinzui/Keikaku/bokuno/keiro-runtime-patterns`, is a documentation-only corpus: terse, agent-facing patterns and best practices for the keiro runtime stack. It currently contains one doc area, `keiki/` (eight files about the keiki transducer library), a `mori.dhall` registry file at the repo root that registers docs so `mori` can discover them, and the planning material under `docs/`. There is no build system and no code — "implementing" this plan means writing Markdown and editing one Dhall file.

`docs/adr/` does not exist in this repository yet, so there are no relevant ADRs to consult. This plan's distillation pass (see Outcomes & Retrospective) is expected to seed the first ones; the MasterPlan names "the two-schema arrangement" and the DSL adoption boundary as candidate ADR topics.

The subject of the docs is **keiro**, an event-sourcing framework and workflow engine for Haskell, whose source lives at `/Users/shinzui/Keikaku/bokuno/keiro` (a cabal multi-package workspace; locate it authoritatively with `mori registry show shinzui/keiro --full`). Keiro is a library, not a server: an application assembles its own workers and command handlers from keiro's functions. The workspace packages that matter here are `keiro-core` (stable contracts, including event-stream validation and the schema constant), `keiro` (the runtime: commands, read models, projections, process managers, timers, inbox/outbox, dead letters, workflows, telemetry), `keiro-dsl` (a build-time specification toolchain and CLI — it does not depend on `keiro`; it is pure code generation), `keiro-migrations` (the `pg-migrate` component and `keiro-migrate` CLI that own keiro's database tables), and `jitsurei` (runnable worked examples; `jitsurei/app/Main.hs` is the canonical end-to-end wiring example every assembly claim below is grounded in). Keiro sits on top of **kiroku** (a PostgreSQL append-only event store, a separate project), **keiki** (pure typed state-machine transducers that define aggregate behavior), and **shibuya** (supervised queue/subscription processing).

Keiro ships extensive documentation of its own: twenty-two files under `docs/user/` and fourteen guides under `docs/guides/` in the keiro repo. The docs this plan writes are deliberately **not** a duplicate of that material. They are the prescriptive layer: short rule-first standards that state what our fleet does, with pointers into keiro's own docs for the long-form treatment. When a topic is fully served by an upstream doc (durable workflows is the prime example), our doc is a one-page orientation plus rules plus a pointer.

Terminology used throughout this plan, defined once:

- An **event stream** (`EventStream`, from `keiro-core`) bundles a keiki transducer with codecs and snapshot policy — it is the definition of one aggregate type. A **validated event stream** (`ValidatedEventStream`, `keiro-core/src/Keiro/EventStream/Validate.hs`) is the newtype proof that the definition passed keiki's replay-safety validation; every command runner, process manager, and router demands the validated form.
- The **two-schema arrangement** is the fact that a keiro service touches two PostgreSQL schemas with different owners: the kiroku store schema (default `kiroku`), which holds the event log and drives LISTEN/NOTIFY, and the dedicated `keiro` schema, which holds keiro's framework tables (snapshots, timers, outbox, inbox, dead letters, workflow bookkeeping). Application read-model tables typically live in a third, application-owned schema.
- A **read model** is a queryable projection of events into ordinary tables; a **projection** is the event-to-SQL application step (inline in the command transaction, or asynchronous via a subscription).
- A **hole**, in keiro-dsl vocabulary, is a hand-owned module or value the code generator deliberately refuses to generate; the **firewall** is the machine-checked invariant that generated modules never contain domain decision logic.

Sibling plans and ownership: this plan owns the `keiro/` directory and its `mori.dhall` block (MasterPlan Integration Point 1) and the core glossary (Integration Point 4). EP-1 owns `keiki/` (exists today), EP-2 owns `kiroku/` and `migrations/` (not yet created — forward links expected to dangle), EP-5 owns `messaging/` and will link back to the glossary defined here (process managers, inbox/outbox, and messaging transports are EP-5's remit, so this plan mentions them only where the runtime surface requires it — dead-letter replay, traceparent columns, the DSL's intake/emit nodes). The documentation style contract (Integration Point 2) is restated in full in the Plan of Work so this plan stands alone.

One known upstream staleness to be aware of while writing: `Keiro.version` in `keiro/src/Keiro.hs` still says `"0.1.0.0"` although the cabal version is 0.3.0.0. Do not cite `Keiro.version` as an authority anywhere; fixing it is EP-3's remit, not ours.


## Plan of Work

All new files are created under `/Users/shinzui/Keikaku/bokuno/keiro-runtime-patterns/keiro/`. The only pre-existing file edited is `/Users/shinzui/Keikaku/bokuno/keiro-runtime-patterns/mori.dhall`. Work proceeds in five milestones; each ends with the repository in a consistent, committable state.

Every doc follows the corpus style contract (MasterPlan Integration Point 2): no YAML frontmatter; a single `#` H1 title; directly under it a **bold one-line tagline**; then a one-paragraph scope statement; then prescriptive, rule-first prose ("The rule is one sentence: …"); code samples in fenced blocks with language tags (`haskell`, `sql`, `sh`, `text`), using `-- CORRECT` / `-- WRONG` contrast pairs where a rule can be violated; relative Markdown cross-links between docs in this repository; references to keiro's own docs written as "keiro repo: `docs/user/<name>.md`"; and a trailing `## Related Patterns` section linking sibling docs. Keep each doc tight — the target is one to three screens, except `dsl-adoption.md` which may run longer because it is the decision centerpiece.

Every factual claim below was verified against the keiro working tree on 2026-07-22. The implementer must re-verify each named symbol while writing (the Validation section automates the final sweep) because the corpus may have moved; if a symbol has moved or changed, follow the source, update the doc accordingly, and record the drift in Surprises & Discoveries.


### Milestone 1 — the core glossary doc and the directory skeleton

Scope: create `keiro/` with the two-schema arrangement doc — the single most-linked glossary entry in the initiative — and a stub `README.md` so the directory is navigable from the first commit. At the end of this milestone the directory exists, the glossary entry is complete, and the stub index links it. Acceptance: both files exist, the style contract is followed, and every symbol named below greps in the keiro tree.

Create `keiro/two-schema-arrangement.md`. Tagline: something equivalent to "**One service, two framework schemas: `kiroku` owns the log and the NOTIFY channel, `keiro` owns the framework tables — qualify everything.**" Content it must convey, in prescriptive prose:

- Since keiro 0.2.0.0, keiro's framework tables live in a dedicated PostgreSQL schema named `keiro`, which keiro's migrations create and own. Every runtime query keiro issues is schema-qualified (`keiro.keiro_snapshots`, `keiro.keiro_timers`, `keiro.keiro_outbox`, `keiro.keiro_dead_letters`, …) and no longer depends on `search_path`. The single source of truth for the schema name is the constant `Keiro.Schema.keiroSchema` (value `"keiro"`, defined in `keiro-core/src/Keiro/Schema.hs`); never hard-code the literal in application code.
- The kiroku store connection `schema` stays `"kiroku"` (the kiroku default) and must not be pointed at `keiro`: in kiroku the connection schema is authoritative for both event-log table resolution *and* the LISTEN/NOTIFY channel (`LISTEN <schema>.events`) — moving it breaks change notification. This is the reason there are two schemas at all: the store schema is kiroku's contract, the `keiro` schema is keiro's.
- Application/projection tables conventionally live in a third, application-owned schema; `keiroConnectionSettings connString appSchema` (from `Keiro.Connection`) wires that schema into the store pool's `extraSearchPath` so projections can reach it. Rule: application SQL that touches framework or cross-schema tables must qualify with `Keiro.Connection.qualifyTable` (signature `qualifyTable :: Text -> Text -> Text`, producing a double-quoted `"schema"."table"` reference), e.g. `"SELECT ... FROM " <> qualifyTable keiroSchema "keiro_timers"`. Include a `-- CORRECT` (qualified via `qualifyTable`) versus `-- WRONG` (bare `keiro_timers`, relying on `search_path`) SQL-in-Haskell pair.
- Tables are created by migrations only: run `keiro-migrate up` (from `keiro-migrations`; a native `pg-migrate` plan that composes kiroku's migration component before keiro's) before starting the application. There is no in-app `CREATE TABLE`. Cross-link `../kiroku/README.md` (forward link, EP-2) for store-side details and keiro repo: `docs/user/migrations.md`, `docs/user/upgrading-to-the-keiro-schema.md`.

Create `keiro/README.md` as a stub: H1 `# Keiro runtime patterns`, tagline, scope paragraph stating these docs are the prescriptive fleet standard for the keiro 0.3 runtime (behavioral contract set by 0.2.0.0) and that keiro repo: `docs/user/README.md` is the long-form reference, then a link list that this milestone populates with the one finished doc and each later milestone extends.


### Milestone 2 — runtime assembly and the command cycle

Scope: the two docs a developer needs to get from an empty `main` to a working command handler with correct error handling. Acceptance: both docs exist, are indexed in the README, and their symbols grep in keiro source.

Create `keiro/runtime-assembly.md`. Tagline: "**Acquire the store once with `withKirokuStore`, validate every event stream at startup, and thread options through lenses.**" Content:

- The assembly standard, mirroring the canonical example `jitsurei/app/Main.hs` in the keiro repo (name it as the reference). Store acquisition is one bracket: `runEff $ StoreResource.withKirokuStore (keiroConnectionSettings connString appSchema) $ withEffToIO SeqUnlift \unlift -> ...`. The effect row used throughout a keiro service is `Eff '[Store, Error StoreError, KirokuStoreResource, IOE]` (modules `Kiroku.Store.Effect` and `Kiroku.Store.Effect.Resource`; interpret with `runErrorNoCallStack . runStoreResource`). Show the wiring as one short `haskell` block.
- Event streams are validated at startup, once, and the validated value is what everything else consumes: define the raw `EventStream`, then call `mkEventStreamOrThrow "order" orderDef` to get a `ValidatedEventStream`. `mkEventStream` (the `Either` form) rejects on **any** keiki 0.2 replay-safety warning — including the four checks new in keiki 0.2: head-recoverability, inversion ambiguity, unguarded input read, and state-changing silent edges — so a transducer that was "clean" under keiki 0.1 can fail here after an upgrade; that is by design, and the fix is in the transducer, not in bypassing validation. `mkEventStreamUnchecked` exists (its own Haddock says so) *only for tests and emergency forensics*; using it in production wiring is a standards violation. Cross-link `../keiki/build-time-validation.md` for what the checks mean. This doc is where the term **validated event stream** is normatively defined for the fleet (glossary duty).
- Command runners: `runCommand` for a plain append; `runCommandWithSql` / `runCommandWithSqlEvents` (module `Keiro.Command`) to run extra SQL in the same transaction as the append; `runCommandWithProjections` (module `Keiro.Projection`) to apply inline projections in that transaction. Rule: the transactional variants require the `KirokuStoreResource` effect (acquired by `withKirokuStore`, interpreted by `runStoreResource`); plain `runCommand` does not. Getting this wrong is a compile error that confuses newcomers, so say it plainly and link the gotchas entry.
- The options idiom: every options record (`RunCommandOptions`, worker options, workflow options) starts from its `default*` value and is customized with `generic-lens` `OverloadedLabels` lenses, canonically `defaultRunCommandOptions & #metrics .~ metrics` (verbatim in `jitsurei/app/Main.hs`). Show one `-- CORRECT` (lens update of the default) versus `-- WRONG` (constructing the record positionally, which breaks on every field addition) pair.
- Close with the startup checklist as prose: migrate (`keiro-migrate up`), acquire store, validate streams, register read models (link the Milestone 3 doc), start workers.

Create `keiro/command-cycle-and-errors.md`. Tagline: "**Classify every `CommandError`; treat `CommandAmbiguous` as a bug, never a business rejection.**" Content:

- The command cycle in five sentences: hydrate (read + replay through the keiki transducer, snapshot-seeded), decide (`stepEither`), append (optimistic concurrency), optionally project inline, return `CommandResult`.
- The `CommandError` taxonomy from `keiro/src/Keiro/Command.hs`, grouped by class using `commandErrorClass :: CommandError -> Text` (the low-cardinality metric label): hydration failures (`HydrationDecodeFailed`, `HydrationReplayFailed` with its `HydrationReplayReason`, `HydrationGapDetected`), the decision outcomes (`CommandRejected` — the one *normal* business rejection; `CommandAmbiguous ![Int]` — two or more transducer edges matched), append-side failures (`EncodeFailed`, `StoreFailed`, `RetryExhausted`, `ConflictFixpoint`). One prescriptive handling rule per class (retry, surface to caller, page a human).
- **The glossary rule, stated normatively here:** `CommandAmbiguous` is never benign. Several matched edges means the aggregate definition itself is nondeterministic — a bug — so workers must halt or dead-letter, never ack-and-continue; the keiro-dsl checker enforces the same posture by rejecting `on-ambiguous => Fired` as `AmbiguousMarkedBenign`. EP-5's process-manager docs will link here rather than restate.
- Dead letters: keiro 0.2 added durable dead letters (`Keiro.DeadLetter`, `Keiro.DeadLetter.Schema`, table `keiro.keiro_dead_letters`, created by keiro migration `0018`); worker policies (`RejectedDeadLetter`, `PoisonDeadLetter`) persist poisoned or rejected deliveries there, and `Keiro.DeadLetter.Replay.replaySubscriptionDeadLetters` re-drives them through a handler after the underlying cause is fixed. Keep this to a paragraph plus pointer — keiro repo: `docs/user/dead-letters.md` — since operational depth belongs upstream and process-manager policy belongs to EP-5.


### Milestone 3 — read models, workflows, telemetry

Scope: the three remaining runtime standards. Acceptance: three docs exist, indexed, symbols grep.

Create `keiro/read-models-and-projections.md`. Tagline: "**Register every read model at startup; fence every rebuild; snapshots are advisory.**" Content:

- Since 0.2.0.0 read models do not auto-register. Rule one: call `registerReadModel` for every model during projection startup, before serving queries; a query against an unregistered model fails with `ReadModelUnregistered`. The `ReadModel` record's `strongScope :: StrongScope` field declares which event-log head a `Strong`-consistency query waits for, and its `schema` field is Haskell-level wiring (deliberately not persisted in the registry) naming where the model's tables live.
- Queries go through `runQuery` (module `Keiro.ReadModel`), which enforces the model's consistency contract at query start.
- Inline versus async: inline projections run in the same transaction as the command append (`runCommandWithProjections`) and are for models the command side reads back; async projections are applied by subscription workers via `applyAsyncProjection`, whose `AsyncApplyOutcome` result (`AsyncApplied` / `AsyncDuplicate` / `AsyncFenced`) the worker must honor — on `AsyncFenced` the worker must *not* checkpoint past the event (a rebuild owns the table at that moment); fail or park the delivery.
- Rebuild fencing: `Keiro.ReadModel.Rebuild.startRebuild` atomically clears the model and installs the fence, replay uses `applyAsyncProjectionUnfenced`, and `finishRebuild` lifts the fence. Present as a three-step recipe.
- **Glossary rule, normative here:** snapshots are advisory, never load-bearing. A snapshot (`Keiro.Snapshot`, table `keiro.keiro_snapshots`) only accelerates hydration; deleting every snapshot must always be safe, and any snapshot/live shape mismatch falls back to full replay. Pointer: keiro repo: `docs/user/read-models-and-projections.md`, `docs/user/snapshots.md`, and guide `docs/guides/project-read-models.md`.

Create `keiro/durable-workflows.md` — deliberately the tersest doc, an orientation plus rules. Tagline: "**Workflows are event-sourced journals with resume, timer, and GC workers — run all three or nothing resumes.**" Content: a workflow runs via `runWorkflowWith runOptions name wfId body` and is driven to suspension; its journal is an ordinary event stream named `wf:<name>-<id>` on the same log, decoded with `workflowJournalCodec`; progress after suspension requires the three workers — resume (`resumeWorkflowsOnce` for single passes, `runWorkflowResumeWorker`/`...Push`/`...With` for continuous operation), durable timers (`runWorkflowTimerWorker`), and garbage collection (`runWorkflowGcWorker`); external events complete awaitables via `signalAwakeable`. Options nest by lens: `defaultWorkflowResumeOptions & #runOptions .~ (defaultWorkflowRunOptions & #metrics .~ metrics)`. Rules: deploy the three workers alongside any workflow-using service; workflow bodies must be deterministic replay-safe code (side effects only through recorded operations); evolution of a live workflow definition goes through the DSL's `patch`/`continueAsNew` support and the diff gate (link `dsl-adoption.md`). Everything else — authoring model, awaitables, child workflows, sleep semantics — is upstream: keiro repo: `docs/user/durable-workflows.md` and `docs/guides/durable-workflows.md`.

Create `keiro/telemetry.md`. Tagline: "**`Keiro.Telemetry` is the single OTel seam: pass a tracer and metrics in options, propagate W3C context through the tables, and bring your own logger.**" Content:

- `Keiro.Telemetry` (in the `keiro` package) is the only module in keiro that touches `hs-opentelemetry-api`; applications integrate by handing it a `Tracer` and a `Meter`, never by instrumenting keiro internals. With no tracer supplied every helper is a pass-through — OTel is opt-in.
- Spans: `withProducerSpan`, `withConsumerSpan`, `withCommandSpan`, `withWorkflowSpan`, with messaging/db semantic-convention attributes plus bespoke `keiro_*` attributes (stream name, retry attempt, events appended, replay divergence, workflow name/id/step).
- Metrics: create once with `newKeiroMetrics meter` (giving a `KeiroMetrics` of ~40 instruments covering command, snapshot, projection lag, outbox/inbox, timers, dispatch, workflow) and thread it everywhere via the `#metrics` lens on `RunCommandOptions`, worker options, and workflow options — the same idiom as `runtime-assembly.md`, cross-link it. `Keiro.Telemetry.kirokuEventBridge` installs on the kiroku connection's `eventHandler` so store-level retry exhaustion is observed too.
- W3C propagation: `traceContextFromCurrentSpan`, `traceContextFromHeaders`, `injectTraceContext` carry `traceparent`/`tracestate`; the outbox and inbox tables persist these as columns, so a trace continues across the async publish/consume boundary with a remote parent. State this as the standard; EP-5 documents the messaging flow itself.
- The logging posture, stated plainly because it surprises people: keiro ships **no structured-logging framework** (no katip/co-log/monad-logger) and no request logging — observability is metrics and traces first. The only logging seams are caller-supplied hooks: the subscription shard worker's error hook (`Keiro.Subscription.Shard.Worker` — "wire to the application logger in production") and the workflow resume worker's logging hook (`Keiro.Workflow.Resume`, defaulting to a compact stderr renderer). Rule: production services must wire both hooks into the application logger; the doc shows the two hook points and leaves logger choice to the service.


### Milestone 4 — the centerpiece decision doc and the gotchas

Scope: `keiro/dsl-adoption.md`, the document this plan exists to produce, plus `keiro/gotchas.md`. Acceptance: both exist, indexed; the adoption doc contains the decision rule, the ownership boundary, the eight hole kinds, the named escape hatches, the CLI surface, and the diff gate; every symbol greps in `keiro-dsl` source.

Create `keiro/dsl-adoption.md`. Tagline: "**Adopt keiro-dsl for cross-node contracts and evolution safety; skip it only when there is nothing for it to check; domain decide logic is always yours either way.**" Structure and content:

*What it is.* keiro-dsl is a build-time toolchain over a typed `.keiro` specification file: parser, checker, scaffolder, harness emitter, and evolution differ. It is not a runtime interpreter — generated code calls the same public keiro APIs a hand-written service would, and the `keiro-dsl` package does not even depend on `keiro` (it is pure code generation). Node families a spec can express: aggregates (with event versions/upcasters, projections, snapshot policies), process managers and durable timers, effectful routers, integration contracts, inbox intake, outbox emits, publishers, PGMQ workqueues and read-model-driven dispatch, first-class read models, and durable workflows (named operations, `patch`, `continueAsNew`).

*What the DSL owns* — the cross-node contracts that are dangerous to reconstruct by hand and that the checker verifies mechanically: disposition-table completeness for intake and workqueues (every failure case mapped to ack/retry/dead-letter, with the two dangerous inversions rejected); FIFO-requires-group-key for ordered queues; snapshot codec identity and live shape-hash agreement; workflow signal/await matching, label uniqueness, and `continueAsNew`-is-terminal; total/exact status maps; contiguous upcaster chains; resolved cross-node references; the `CommandAmbiguous`-follows-rejection-policy rule. Plus byte-identical scaffolding (two agents scaffolding the same spec produce the same bytes) and the evolution gate: `keiro-dsl diff --since <git-ref>` classifies every spec change as `ADDITIVE`, `WARNING`, or `BREAKING` per node family and **exits non-zero on any BREAKING change — it is a deploy gate, not a warning**; it must run from the spec's git repository because `--since` resolves via `git show`.

*What the DSL never owns — the firewall.* Domain decide logic is ALWAYS a hole. The scaffolder emits two module kinds: `Generated.*` modules carrying an `-- @generated` banner, overwritten on every scaffold run; and create-once `Holes.hs` modules, never overwritten, where all business logic lives. The machine-checked invariant (`FirewallSurface` / `firewallBreaches` in `Keiro.Dsl.Scaffold`): no generated module ever contains a keiki symbolic operator (`./=`, `.==`, `.||`, `lit`, `B.slot`, `B.requireGuard`). Rule, stated as the fleet standard: **never edit a `Generated.*` module** — regenerate it; put every change in holes or in the spec.

*The eight hole kinds*, listed with one line each (source: `Keiro.Dsl.Grammar`, "The eight hole-kind types"): 1 deterministic id/string derivations (opaque strategies must carry a captured fixture, not prose); 2 failure→action disposition tables; 3 explicit value→value mappings; 4 envelope-field layering / dedupe policy; 5 define-once names (referenced, never retyped); 6 body decode-strictness; 7 emit-map optionality (the explicit `_ => skip` catch-all); 8 deployment configuration (Kafka brokers/groupId/offsetReset — delegated to deployment, never in the spec).

*Named escape hatches*, so readers reach for the sanctioned ones: `ResolveHole` (a router resolver declared as a typed hole instead of a read model); `via hole` group keys (opaque group-key derivation stays hand-owned); the dispatch dedup raw-SQL hole; the Kafka config hole (kind 8); and the one flagged as a footgun — `scaffold --force-generated-overwrite` bypasses only the missing-`@generated`-banner safety check and will clobber a hand-edited generated file, which is only ever needed to repair a violation of the never-edit rule.

*The CLI surface*, as a short `sh` block with one-line annotations: `keiro-dsl parse FILE` (parse and pretty-print back), `check FILE [--emit]` (validate; non-zero on any error), `scaffold FILE --out DIR [--module-root ROOT] [--collocate] [--force-generated-overwrite]`, `diff FILE --since GIT-REF` (the deploy gate), `new KIND` (print a minimal skeleton; kinds: aggregate, process, router, contract, intake, emit, publisher, workqueue, dispatch, workflow, operation).

*The decision rule*, the paragraph everything above supports. Adopt keiro-dsl when the service has more than one node family, any integration surface (intake/emit/queues), or any expected schema/workflow evolution — the checker and the diff gate are the payoff, and they only get more valuable as the twenty-service fleet evolves contracts in lockstep. A single-aggregate service with trivial cross-node policy (no queues, no integration contracts, no workflow evolution) may skip the DSL and hand-write against the public API — it would gain little beyond scaffolding, and the firewall means its decide logic would be hand-written anyway. Skipping is a decision to *revisit*, not a permanent posture: the moment a second node family or an evolution concern appears, write the spec (`keiro-dsl new` + `check` makes retrofitting cheap). Either way the module discipline is EP-6's layout standard (`Generated.*` ring plus one `Holes.hs` per concept) — link `../architecture/` once EP-6 lands (forward reference by name only, not a hard link, since EP-6's filenames are not fixed yet; put the name in Related Patterns prose). Pointer: keiro repo: `docs/user/typed-spec-toolchain.md`.

Create `keiro/gotchas.md`. Tagline: "**Four traps that cost real debugging time.**" One titled short section per gotcha:

- *The `alternative` composition trap.* Mounting a keiki `alternative` composite of two machines as one `EventStream` forces them to share one stream identity, version counter, and snapshot — almost never what sibling aggregates want. Dividing rule (from keiro repo: `docs/guides/choosing-a-primitive.md`): inside one consistency boundary, compose in keiki; across streams, use a runtime primitive (router or process manager). Cross-link `../keiki/transducer-best-practices.md`.
- *The `$all` throughput ceiling.* Every append serializes on kiroku's single-row `$all` global-position lock; this is a documented, deliberate ceiling (stated in the `Keiro` module Haddock), not a bug to work around with clever SQL. Plan capacity accordingly; keep transactional-append continuations minimal because they run while that lock is held.
- *Transactional runners need `KirokuStoreResource`.* `runCommandWithSql`, `runCommandWithSqlEvents`, and `runCommandWithProjections` require the `KirokuStoreResource` effect (acquire with `withKirokuStore`, interpret with `runStoreResource`); plain `runCommand` does not. If the compiler demands an effect you did not expect, this is why. Cross-link `runtime-assembly.md`.
- *Kafka is BYO.* `keiro` has no `hw-kafka-client` dependency. `Keiro.Outbox.Kafka.outboxRowToKafkaRecord` / `integrationEventToKafkaRecord` convert outbox rows to a transport-neutral `KafkaProducerRecord`; the application owns the actual producer/consumer, and broker/group configuration is DSL hole-kind 8 (deployment-owned). Transport standards are EP-5's remit — link `../messaging/` by name in prose (forward reference).


### Milestone 5 — index, registry, validation sweep

Scope: finalize `keiro/README.md` as the complete index, register all nine docs in `mori.dhall`, and run the full validation suite. Acceptance: the three checks in Validation and Acceptance pass.

Finalize `keiro/README.md`: scope paragraph (as in Milestone 1) plus a short "start here" ordering — read `runtime-assembly.md` first, `two-schema-arrangement.md` second, `dsl-adoption.md` before writing any new service — and a link list of all eight sibling docs with a one-line description each. Also state the version note from the Decision Log (docs describe keiro 0.3; behavioral contract set by 0.2.0.0) and the relationship to keiro's own docs (this corpus is the prescriptive layer; keiro repo `docs/user/` is the reference layer).

Edit `mori.dhall`: append nine `Schema.DocRef` entries to the `docs` list, after the existing `keiki-json-event-codecs` entry, without touching any existing entry (Integration Point 1: each plan appends only its own block). Keys and kinds:

- `keiro-overview` — Guide — `keiro/README.md`
- `keiro-runtime-assembly` — BestPractice — `keiro/runtime-assembly.md`
- `keiro-two-schema-arrangement` — Guide — `keiro/two-schema-arrangement.md`
- `keiro-command-cycle-and-errors` — BestPractice — `keiro/command-cycle-and-errors.md`
- `keiro-read-models-and-projections` — BestPractice — `keiro/read-models-and-projections.md`
- `keiro-durable-workflows` — Guide — `keiro/durable-workflows.md`
- `keiro-telemetry` — BestPractice — `keiro/telemetry.md`
- `keiro-dsl-adoption` — Guide — `keiro/dsl-adoption.md`
- `keiro-gotchas` — BestPractice — `keiro/gotchas.md`

All nine use `audience = Schema.DocAudience.Module`, `location = Schema.DocLocation.LocalFile "keiro/<file>"`, and a one-sentence `description = Some "..."`. Follow the exact record shape of the existing `keiki-*` entries in the same file. `shinzui/keiro` is already in the `dependencies` list — do not add or reorder dependencies. Then run the validation suite (next sections).


## Concrete Steps

All commands run from the repository root, `/Users/shinzui/Keikaku/bokuno/keiro-runtime-patterns`, unless stated otherwise. Set a convenience variable for the keiro source tree first (confirm the path with `mori registry show shinzui/keiro --full` if it has moved):

```sh
KEIRO=/Users/shinzui/Keikaku/bokuno/keiro
```

1. Create the directory and write the Milestone 1 files:

   ```sh
   mkdir -p keiro
   ```

   Write `keiro/two-schema-arrangement.md` and the stub `keiro/README.md` per Milestone 1. While writing, verify each claim at its source, e.g.:

   ```sh
   grep -n 'keiroSchema' "$KEIRO/keiro-core/src/Keiro/Schema.hs"
   grep -n 'qualifyTable ::' "$KEIRO/keiro/src/Keiro/Connection.hs"
   ```

   Expected output shape:

   ```text
   16:keiroSchema :: Text
   17:keiroSchema = "keiro"
   58:qualifyTable :: Text -> Text -> Text
   ```

2. Write `keiro/runtime-assembly.md` and `keiro/command-cycle-and-errors.md` per Milestone 2, grounding the wiring block in `$KEIRO/jitsurei/app/Main.hs` (the `withJitsureiStore` function and the `commandOptions` helper) and the error taxonomy in `$KEIRO/keiro/src/Keiro/Command.hs` (the `data CommandError` block and `commandErrorClass`).

3. Write the three Milestone 3 docs, grounding in `$KEIRO/keiro/src/Keiro/ReadModel.hs` (registration, `strongScope`, `runQuery`), `$KEIRO/keiro/src/Keiro/Projection.hs` (`AsyncApplyOutcome`, `runCommandWithProjections`), `$KEIRO/keiro/src/Keiro/ReadModel/Rebuild.hs`, `$KEIRO/keiro/src/Keiro/Workflow.hs` and `Workflow/{Resume,Sleep,Gc,Awakeable,Types}.hs`, and `$KEIRO/keiro/src/Keiro/Telemetry.hs`.

4. Write the two Milestone 4 docs, grounding in `$KEIRO/keiro-dsl/app/Main.hs` (CLI), `$KEIRO/keiro-dsl/src/Keiro/Dsl/Grammar.hs` (hole kinds, `ResolveHole`), `$KEIRO/keiro-dsl/src/Keiro/Dsl/Scaffold.hs` (firewall), `$KEIRO/keiro-dsl/src/Keiro/Dsl/Validate.hs` (`AmbiguousMarkedBenign`), and keiro repo `docs/user/typed-spec-toolchain.md` and `docs/guides/choosing-a-primitive.md`.

5. Finalize `keiro/README.md`; append the nine DocRef entries to `mori.dhall` per Milestone 5.

6. Run the validation suite (next section) and fix anything it flags.

Each step ends at a consistent state; update the Progress checklist at every stopping point. Do not commit as part of this plan's authoring; when implementation commits happen they follow Conventional Commits (e.g. `docs(keiro): add runtime assembly and two-schema docs`).


## Validation and Acceptance

Three mechanical checks plus one human check. All commands run from the repository root.

**1. Symbol cross-check.** Every load-bearing symbol the docs name must exist verbatim in the keiro source tree. Run:

```sh
KEIRO=/Users/shinzui/Keikaku/bokuno/keiro
for sym in withKirokuStore keiroConnectionSettings KirokuStoreResource \
  mkEventStream mkEventStreamOrThrow mkEventStreamUnchecked ValidatedEventStream \
  runCommand runCommandWithSql runCommandWithSqlEvents runCommandWithProjections \
  defaultRunCommandOptions commandErrorClass CommandAmbiguous CommandRejected \
  HydrationReplayReason keiroSchema qualifyTable \
  registerReadModel ReadModelUnregistered strongScope runQuery \
  applyAsyncProjection applyAsyncProjectionUnfenced AsyncApplyOutcome AsyncFenced \
  startRebuild finishRebuild \
  replaySubscriptionDeadLetters \
  runWorkflowWith resumeWorkflowsOnce runWorkflowResumeWorker runWorkflowTimerWorker \
  runWorkflowGcWorker signalAwakeable workflowJournalCodec \
  KeiroMetrics newKeiroMetrics withCommandSpan withProducerSpan withConsumerSpan \
  withWorkflowSpan injectTraceContext kirokuEventBridge \
  FirewallSurface firewallBreaches ResolveHole AmbiguousMarkedBenign ; do
  grep -rqI --include='*.hs' -- "$sym" "$KEIRO/keiro" "$KEIRO/keiro-core" "$KEIRO/keiro-dsl" \
    && echo "OK   $sym" || echo "MISS $sym"
done
```

Acceptance: every line reads `OK`; any `MISS` means either a typo in a doc or upstream drift — resolve by reading the source, fix the doc, and record drift in Surprises & Discoveries.

**2. Dhall type check.** The registry must still be a well-typed `Schema.Project`:

```sh
dhall type --file mori.dhall > /dev/null && echo "mori.dhall OK"
```

Acceptance: prints `mori.dhall OK` (the first run may pause to fetch and verify the pinned schema import). Also confirm the nine keys are present:

```sh
grep -c 'key = "keiro-' mori.dhall
```

Acceptance: prints `9`.

**3. Index and link integrity.** Every doc is linked from the README, and every relative link resolves (forward links into `../kiroku/` are whitelisted until EP-2 lands):

```sh
for f in keiro/*.md; do b=$(basename "$f"); [ "$b" = README.md ] && continue; \
  grep -q "($b)" keiro/README.md && echo "INDEXED $b" || echo "UNINDEXED $b"; done
grep -RhoE '\]\(\.\./[^)#]+|\]\([a-zA-Z0-9._-]+\.md' keiro/*.md | sed 's/^\](//' | sort -u | \
  while read -r l; do case "$l" in ../kiroku/*) echo "FORWARD $l";; \
  ../*) [ -f "keiro/$l" ] && echo "OK $l" || echo "BROKEN $l";; \
  *) [ -f "keiro/$l" ] && echo "OK $l" || echo "BROKEN $l";; esac; done
```

Acceptance: eight `INDEXED` lines, no `UNINDEXED`, no `BROKEN`; `FORWARD ../kiroku/...` lines are expected and fine.

**4. Human check (the behavior beyond compilation).** Open `keiro/dsl-adoption.md` and confirm a reader who knows nothing about keiro-dsl can answer, from that one file: what the tool is, the five CLI subcommands, why they must never edit a `Generated.*` module, what the eight hole kinds are, what `diff` gates and where it must run, and — for a described service shape — whether to adopt or skip the DSL. Then open `keiro/two-schema-arrangement.md` and confirm it answers "why does my query for `keiro_timers` fail?" (unqualified name) in under a minute. Style spot-check every file against the contract in Plan of Work: H1, bold tagline, scope paragraph, language-tagged fences, Related Patterns section, no YAML frontmatter.


## Idempotence and Recovery

Everything here is additive file creation plus one append-only edit, so every step can be re-run safely. Rewriting a doc file is harmless — content converges on the specification in Plan of Work. The `mori.dhall` edit is the only step needing care: before appending, `grep -c 'key = "keiro-' mori.dhall` — if it already prints `9`, skip the edit; if it prints something between 1 and 8, a previous session stopped mid-append, so open the file, find the last complete `keiro-*` DocRef record, and add only the missing ones (the Milestone 5 list is the authoritative order). If `dhall type` fails after an edit, the error names the offending line; the fix is always local to the appended block because nothing else was touched. If the keiro source has drifted since this plan was written (a `MISS` in check 1), the source wins: update the doc text, not the check list, unless the symbol was renamed — then update both and log it in Surprises & Discoveries. No step touches any file outside `keiro/` and `mori.dhall`; recovery from any bad state is `git checkout -- <file>` for the affected file and a re-run of the milestone.


## Interfaces and Dependencies

No code is built and nothing is compiled; the "interfaces" of this plan are the documented API surface (which the docs must name exactly as the source spells it) and the two file formats we produce.

Ground-truth source tree: `/Users/shinzui/Keikaku/bokuno/keiro` (verify location via `mori registry show shinzui/keiro --full`). The authoritative files per topic, all repo-relative to that tree: assembly idiom `jitsurei/app/Main.hs`; validation boundary `keiro-core/src/Keiro/EventStream/Validate.hs` (`mkEventStream`, `mkEventStreamOrThrow`, `mkEventStreamWith`, `mkEventStreamUnchecked`, `ValidatedEventStream`); schema constant `keiro-core/src/Keiro/Schema.hs` (`keiroSchema :: Text` = `"keiro"`); connection helpers `keiro/src/Keiro/Connection.hs` (`keiroConnectionSettings :: Text -> Text -> ConnectionSettings`, `qualifyTable :: Text -> Text -> Text`); command cycle `keiro/src/Keiro/Command.hs` (`runCommand`, `runCommandWithSql`, `runCommandWithSqlEvents`, `RunCommandOptions`, `defaultRunCommandOptions`, `data CommandError` with the constructors listed in Milestone 2, `HydrationReplayReason`, `commandErrorClass :: CommandError -> Text`); inline/async projections `keiro/src/Keiro/Projection.hs` (`runCommandWithProjections`, `applyAsyncProjection :: AsyncProjection -> RecordedEvent -> Tx.Transaction AsyncApplyOutcome`, `applyAsyncProjectionUnfenced`, `AsyncApplyOutcome` = `AsyncApplied | AsyncDuplicate | AsyncFenced`); read models `keiro/src/Keiro/ReadModel.hs` (`registerReadModel`, `runQuery`, `strongScope`, `ReadModelUnregistered`) and `keiro/src/Keiro/ReadModel/Rebuild.hs` (`startRebuild`, `finishRebuild`); dead letters `keiro/src/Keiro/DeadLetter.hs` and `keiro/src/Keiro/DeadLetter/Replay.hs` (`replaySubscriptionDeadLetters`); workflows `keiro/src/Keiro/Workflow.hs` (`runWorkflowWith`) plus `Workflow/Resume.hs` (`resumeWorkflowsOnce`, `runWorkflowResumeWorker`, `...Push`, `...With`), `Workflow/Sleep.hs` (`runWorkflowTimerWorker`), `Workflow/Gc.hs` (`runWorkflowGcWorker :: WorkflowGcPolicy -> Int -> Eff es ()`), `Workflow/Awakeable.hs` (`signalAwakeable :: ... AwakeableId -> r -> Eff es Bool`), `Workflow/Types.hs` (`workflowJournalCodec`); telemetry `keiro/src/Keiro/Telemetry.hs` (`KeiroMetrics`, `newKeiroMetrics`, `withProducerSpan`, `withConsumerSpan`, `withCommandSpan`, `withWorkflowSpan`, `traceContextFromCurrentSpan`, `traceContextFromHeaders`, `injectTraceContext`, `kirokuEventBridge`); DSL CLI `keiro-dsl/app/Main.hs` (subcommands `parse`, `check`, `scaffold`, `diff`, `new` with the flags listed in Milestone 4); DSL grammar `keiro-dsl/src/Keiro/Dsl/Grammar.hs` (the eight hole-kind types, `ResolveHole`, the hole-kind numbering in Haddock comments); scaffolder firewall `keiro-dsl/src/Keiro/Dsl/Scaffold.hs` (`FirewallSurface`, `firewallBreaches`, the `-- @generated` banner, `--force-generated-overwrite` semantics); checker `keiro-dsl/src/Keiro/Dsl/Validate.hs` (`AmbiguousMarkedBenign`). Kiroku-side facts (store `schema` drives `LISTEN <schema>.events`; `extraSearchPath` is the projection-schema seam) come from the kiroku project (`mori registry show shinzui/kiroku --full`), module `Kiroku/Store/Connection.hs` — the docs state these facts but EP-2 owns their full treatment.

Registry format: `mori.dhall` uses the pinned mori-schema import already at the top of the file; a DocRef is `Schema.DocRef::{ key : Text, kind : Schema.DocKind, audience : Schema.DocAudience, description : Optional Text, location : Schema.DocLocation }` with `location = Schema.DocLocation.LocalFile "<repo-relative path>"`. Only `DocKind.Guide` and `DocKind.BestPractice` and `DocAudience.Module` are used by this plan. Tooling required on PATH: `dhall` (any 1.4x; 1.42.3 verified present) and standard POSIX shell utilities; nothing else.

At the end of each milestone the deliverable interface is simply the set of files named in that milestone existing with the content contract described in Plan of Work; there are no types or function signatures to produce, only to *cite correctly* — which is what Validation check 1 enforces.
