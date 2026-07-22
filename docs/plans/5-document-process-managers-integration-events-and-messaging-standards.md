---
id: 5
slug: document-process-managers-integration-events-and-messaging-standards
title: "Document process managers, integration events, and messaging standards"
kind: exec-plan
created_at: 2026-07-22T14:55:29Z
intention: intention_01ky5agv9gehqa8dbw03cdcpwv
master_plan: "docs/masterplans/1-keiro-runtime-standards-docs-and-seihou-blueprints.md"
---

# Document process managers, integration events, and messaging standards

This ExecPlan is a living document. The sections Progress, Surprises & Discoveries,
Decision Log, and Outcomes & Retrospective must be kept up to date as work proceeds.
If durable project context changes, update or create ADRs in docs/adr/ in the same change.


## Purpose / Big Picture

About twenty Haskell microservices are being written on or refactored onto the keiro
runtime, and the connective tissue between them — how one service orchestrates a
multi-step process internally, and how services talk to each other — currently has no
single prescriptive standard. The knowledge exists, but it is scattered across the keiro
framework's own user docs, the shibuya framework's module haddocks, the pgmq adapter's
source, and two worked-example repositories (danwa and keiro-runtime-jitsurei). A
developer or coding agent starting service number seven today has to rediscover, every
time, when to reach for a full process manager versus a hand-rolled worker, how to
publish an event another service may consume without losing it, and which queue
transport to pick.

After this plan is complete, the repository `keiro-runtime-patterns` contains a new
`messaging/` documentation directory — eleven terse, prescriptive, agent-facing standard
documents covering process managers and durable timers, the domain-event versus
integration-event boundary, the outbox and inbox patterns, the shibuya processing
semantics every worker inherits, an evidence-based transport selection matrix (pgmq
versus Kafka versus kiroku subscriptions), the keiro-pgmq typed job standard, the
kiroku-to-shibuya subscription bridge rules, and a consolidated gotcha catalogue. Every
document is registered in `mori.dhall` with a `messaging-<slug>` key so developers and
agents can discover them through the mori registry.

You can see it working three ways: `ls messaging/` in the repository root lists the
eleven files and `messaging/README.md` indexes all of them; `dhall type --quiet --file
mori.dhall` exits 0 with the eleven new DocRef entries present; and every API symbol a
document names can be found verbatim in the source repositories this plan cites (the
Concrete Steps section gives the exact grep commands and expected hits).


## Progress

- [x] (2026-07-22T18:14:45Z) M1: `messaging/` directory created; `messaging/glossary.md` written; `messaging/README.md` stub written.
- [x] (2026-07-22T18:18:23Z) M2: `messaging/process-managers.md` written (record anatomy, atomicity and idempotency, worker policies, durable timers, decision ladder).
- [x] (2026-07-22T18:20:51Z) M3: `messaging/integration-events.md`, `messaging/outbox.md`, `messaging/inbox.md` written.
- [x] (2026-07-22T18:24:32Z) M4: `messaging/shibuya-processing.md`, `messaging/transport-selection.md`, `messaging/pgmq-jobs.md`, `messaging/kiroku-subscriptions.md` written.
- [x] (2026-07-22T18:27:21Z) M5: `messaging/gotchas.md` written; `messaging/README.md` finalized as a complete index; eleven `messaging-*` DocRefs appended to `mori.dhall`.
- [x] (2026-07-22T18:29:01Z) M5 validation: source-symbol checks, `dhall type`, README index, relative links, style, DocRef locations, and Mori registry refresh pass.
- [x] (2026-07-22T18:29:01Z) ADR distillation: `docs/adr/0003-pgmq-vs-kafka-transport-selection.md` records the transport boundary.
- [x] (2026-07-22T18:29:01Z) MasterPlan registry row for EP-5 flipped to Complete; Outcomes & Retrospective written.


## Surprises & Discoveries

Findings made while authoring this plan (verifying the research reports against the
sources); the implementer should confirm they still hold and record anything new here.

- The `Keiro.Inbox` export list carries seven `runInboxTransaction*` variants (base,
  `With`, `WithKey`, `WithRetries`, `WithRetriesWith`, `WithRetriesKey`, `Batch`); two
  further `...KeyPersist` functions exist in the module body but are internal plumbing.
  An earlier research memo said "10 variants" — the docs must say seven exported.
  Evidence: export list at `keiro/src/Keiro/Inbox.hs` lines 36–42 in the keiro repo.
- `deterministicCommandId` is a UUIDv5 (`UUID.V5.generateNamed UUID.V5.namespaceURL`)
  over `(manager name, correlation id, source event id, emit index)` — the exact same
  technique danwa uses for its deterministic outbox ids. The process-manager doc and the
  outbox doc should point out that these two patterns rhyme deliberately.
  Evidence: `keiro/src/Keiro/ProcessManager.hs` lines 415–421;
  `danwa/danwa-core/src/Danwa/Integration/AddressedMessage.hs` line 52.
- `defaultWorkerOptions` defaults to `PoisonHalt` and `RejectedHalt` — the framework's
  defaults are halt-first ("an operator cannot miss the failure"); the docs should state
  the defaults and when to deliberately relax them.
  Evidence: `keiro/src/Keiro/ProcessManager.hs` lines 284–289.
- The `Keiro.Outbox` module haddock documents a concurrency caveat for the inline
  `enqueueIntegrationEventTx` escape hatch: per-key ordering sorts by `created_at`
  (filled at transaction start), so two concurrent same-key inline enqueues can commit
  in the opposite order of their `created_at` values. The canonical
  `IntegrationProducer` subscription serializes same-key enqueues and does not have this
  problem. This must appear in the outbox doc. Evidence: `keiro/src/Keiro/Outbox.hs`
  module haddock, final paragraph.
- The released `Keiro.ProcessManager` contract is not one all-or-nothing saga
  transaction. The manager-state append and its timers commit together; each target
  command and inline projections then commit in a separate transaction. Deterministic
  ids make source-event replay fill missing target writes after a crash. Evidence:
  `keiro-0.3.0.0:keiro/src/Keiro/ProcessManager.hs`, module haddock and
  `runProcessManagerOnce`.
- Shibuya 0.8.0.1 changed the handler-exception behavior assumed by the planning
  draft: its supervised runner substitutes `AckRetry (RetryDelay 0)` and always calls
  the finalizer. On that cohort a bare Kiroku handler does not leave the ack permanently
  unfilled; `guardKirokuHandler` remains the recommended adapter-specific policy because
  it gives thrown handlers a one-second retry delay instead of an immediate storm.
  Evidence: `shibuya-core` v0.8.0.1
  `Shibuya.Internal.Runner.Supervised.processOne` and
  `shibuya-kiroku-adapter` v0.4.0.0 `guardKirokuHandler`.
- The released `IntegrationProducer` surface defines and validates the mapper and
  provides `enqueueProducerEventTx`, but it does not ship a subscription runner that
  atomically owns a Kiroku checkpoint. The standard must require caller-owned
  at-least-once subscription wiring and stable outbox/message identities instead of
  attributing checkpoint atomicity to the helper. Evidence:
  `keiro-0.3.0.0:keiro/src/Keiro/Outbox.hs` and a repository-wide symbol search.
- `deterministicCommandId` covers the manager-state append and target-command appends,
  not durable timers. `TimerRequest.timerId` is supplied by the caller, so the pure
  reaction must derive it from stable business facts or redelivery can create a second
  deadline. Evidence: `keiro-0.3.0.0:keiro/src/Keiro/ProcessManager.hs` and
  `keiro/src/Keiro/Timer.hs`.
- `enqueueProducerEventTx` mints a fresh `messageId` every time it is invoked. Reusing
  only its caller-supplied `OutboxId` therefore does not make a replayed invocation
  coalesce on the actual `(source, message_id)` conflict target. Caller-owned source
  wiring must either make checkpoint plus enqueue atomic or build an envelope with
  stable message and outbox identities. Evidence: `mintIntegrationEvent`,
  `enqueueProducerEventTx`, and `enqueueOutboxStmt` in keiro 0.3.0.0.
- `outboxMaintenancePass` reclaims stale publishing rows and samples backlog, but does
  not call `garbageCollectSent`. Retention must be scheduled independently. Evidence:
  `keiro-0.3.0.0:keiro/src/Keiro/Outbox.hs`.
- The current shibuya-pgmq-adapter direct/topic DLQ path sends the DLQ copy and
  deletes the source row in one transaction. Keiro-pgmq's one-shot drain still performs
  those effects separately, and the keiro-pgmq 0.3.0.0 module introduction describes
  the older non-atomic adapter behavior. The standards distinguish the worker and
  one-shot paths. Evidence: shibuya-pgmq-adapter v0.12.0.0
  `Shibuya.Adapter.Pgmq.Internal.deadLetterTransactionally` and keiro-pgmq 0.3.0.0
  `runJobOnceWithContext`.
- The shibuya-kiroku-adapter 0.4.0.0 module introduction still warns that a thrown
  handler leaves the reply unfinalized, but its supported Shibuya 0.8.0.1 runner now
  catches the exception and finalizes `AckRetry 0`. The version-cohort behavior wins;
  `guardKirokuHandler` remains the preferred one-second retry policy. Evidence:
  `Shibuya.Internal.Runner.Supervised.processOne` and
  `Shibuya.Adapter.Kiroku.guardKirokuHandler`.


## Decision Log

- Decision: The `messaging/` area is split into eleven focused files (README, glossary,
  process-managers, integration-events, outbox, inbox, shibuya-processing,
  transport-selection, pgmq-jobs, kiroku-subscriptions, gotchas) rather than three or
  four omnibus documents.
  Rationale: the existing `keiki/` corpus in this repository established the shape —
  small single-concern files, each with its own mori DocRef key, so an agent can pull
  exactly the standard it needs. Eleven keys also give the seihou blueprints (EP-9)
  precise citation targets.
  Date: 2026-07-22

- Decision: Durable timers are documented inside `messaging/process-managers.md` as a
  section, not as a separate file.
  Rationale: timers are scheduled inside the process-manager reaction
  (`ProcessManagerAction.timers`, `scheduleTimerTx` in the same append transaction) and
  fired back into the manager by the timer worker; splitting them would force every
  reader to hold two files for one story. The MasterPlan progress line "Process manager
  and timer standards written" treats them as one deliverable.
  Date: 2026-07-22

- Decision: This plan appends only its own `docs` entries to `mori.dhall` and does not
  touch the `dependencies` list (even though it documents pgmq-hs and the shibuya
  adapters).
  Rationale: MasterPlan Integration Point 1 assigns dependency-list updates
  (`shinzui/pgmq-hs`, adapter projects) to EP-2 to avoid concurrent-edit collisions;
  each plan owns exactly one block.
  Date: 2026-07-22

- Decision: The adapter comparison matrix in `messaging/transport-selection.md` is a
  Markdown table, despite the corpus's prose-first style.
  Rationale: the ExecPlan specification and the corpus style both permit tables where
  prose would obscure meaning; a three-transport by nine-dimension comparison is exactly
  that case, and the MasterPlan explicitly calls for reproducing the comparison table.
  Date: 2026-07-22

- Decision: Forward links from `messaging/` docs to EP-4's territory target
  `../keiro/README.md` (the index EP-4 owns) rather than guessing specific filenames
  EP-4 has not created yet.
  Rationale: EP-4 (`docs/plans/4-document-the-keiro-runtime-core-and-keiro-dsl-adoption-guidance.md`)
  owns the `keiro/` doc directory and the runtime glossary terms (validated event
  stream, the two-schema arrangement, `CommandAmbiguous` semantics, durable workflows).
  MasterPlan Integration Point 4 says later plans link and never redefine. A link to the
  directory index is stable regardless of EP-4's internal file layout; if EP-4 has
  already landed when this plan is implemented, tighten the links to the specific files
  and record that here.
  Date: 2026-07-22

- Decision: The pgmq-versus-Kafka selection rationale is written into
  `messaging/transport-selection.md` and promoted to
  `docs/adr/0003-pgmq-vs-kafka-transport-selection.md`.
  Rationale: EP-4 seeded ADRs 0001 and 0002 before this plan ran, so the completion
  pass took the next free number as required by the MasterPlan.
  Date: 2026-07-22

- Decision: Describe the released process-manager persistence boundary precisely:
  manager state plus timers are one transaction, while each target dispatch is its own
  transaction recovered by deterministic replay.
  Rationale: the 0.3.0.0 source explicitly rejects the planning draft's stronger
  "all three atomically" claim; documenting the narrower guarantee is necessary for
  correct failure handling.
  Date: 2026-07-22

- Decision: Recommend `guardKirokuHandler` for bounded, non-spinning retry behavior,
  but do not claim it is required to make Shibuya 0.8.0.1 finalize a thrown handler.
  Rationale: the current Shibuya runner always finalizes thrown handlers as
  `AckRetry 0`; the guard still improves the adapter policy to `AckRetry 1` and remains
  useful for explicitness and older compatible cores.
  Date: 2026-07-22

- Decision: Treat `IntegrationProducer` as the producer definition and transactional
  enqueue primitive, not as a complete checkpoint-owning worker.
  Rationale: the released public API has no subscription runner. An application must
  supply at-least-once source consumption and stable identities so replayed enqueue
  attempts coalesce.
  Date: 2026-07-22

- Decision: Require caller-derived deterministic timer ids in process-manager
  reactions; do not imply Keiro generates them alongside command ids.
  Rationale: `TimerRequest` owns its `timerId`, and `scheduleTimerTx` upserts by that
  value. Stable ids turn source-event replay into a timer upsert instead of a duplicate
  deadline.
  Date: 2026-07-22

- Decision: Make source-redelivery idempotency an application wiring requirement for
  integration producers and keep sent-row retention separate from outbox maintenance.
  Rationale: the released producer helper owns neither the source checkpoint nor a
  stable replayed message id, and the maintenance pass owns no garbage collection.
  The standard must describe the public behavior rather than the stronger guarantees
  in the planning draft.
  Date: 2026-07-22

- Decision: Document PGMQ DLQ atomicity per execution path and use current Shibuya
  runner behavior when adapter prose conflicts with the supported core release.
  Rationale: the supervised PGMQ adapter and Keiro's direct one-shot drain implement
  different transaction boundaries, while the Kiroku adapter's older warning no longer
  describes Shibuya 0.8.0.1. Version-cohort source behavior is the actionable contract.
  Date: 2026-07-22


## Outcomes & Retrospective

Summarize outcomes, gaps, and lessons learned at major milestones or at completion.
Compare the result against the original purpose. Before marking the plan complete,
distill durable project context from the Decision Log, Surprises & Discoveries, and
this section into docs/adr/. Keep task-local execution details here.

EP-5 is complete. The repository now has eleven indexed messaging documents covering
the shared vocabulary, process managers and timers, integration contracts, transactional
outbox and inbox boundaries, Shibuya semantics, transport selection, typed PGMQ jobs,
Kiroku subscriptions, and eighteen production gotchas. The source audit corrected four
planning assumptions: the process-manager transaction is intentionally split across
target dispatches; timer ids are caller-owned; `IntegrationProducer` owns neither a
checkpoint runner nor a stable replayed message id; and current Shibuya/PGMQ adapter
behavior differs from older module prose.

Acceptance passed for all eleven files and DocRefs: Dhall type-checking, complete index
and relative-link checks, style and tagged-fence checks, seven exported inbox runners,
the full source-symbol audit against the verified release cohort, and Mori registration
refresh. `mori registry docs shinzui/keiro-runtime-patterns` now lists all eleven
`messaging-*` entries. ADR 0003 preserves the transport decision independently of the
implementation notes. No Haskell source or dependency bounds changed.


## Context and Orientation

### What this repository is

`/Users/shinzui/Keikaku/bokuno/keiro-runtime-patterns` is a documentation-only
repository: the terse, agent-facing pattern corpus for the keiro runtime (a separate
Fumadocs website, keiro-runtime-docs, is the polished product documentation — this repo
complements it, it does not duplicate it). Today the repo contains one doc area,
`keiki/` (eight files on the keiki transducer library), plus `mori.dhall` (the mori
registry manifest that makes each doc discoverable), `docs/masterplans/` and
`docs/plans/` (planning documents, including this one), and seihou-managed agent skills
under `agents/`. At authoring time `docs/adr/` did not exist. EP-4 later seeded the
schema-ownership and DSL-adoption decisions; this plan adds ADR 0003 for transport
selection.

This plan creates a second doc area, `messaging/`, at the repository root (sibling of
`keiki/`), and registers each file in `mori.dhall`. This plan is EP-5 of the MasterPlan
at `docs/masterplans/1-keiro-runtime-standards-docs-and-seihou-blueprints.md`, which
assigns `messaging/` and the messaging glossary to EP-5 and declares process managers
and integration events "first-class concerns throughout — the connective tissue between
the twenty services".

### The messaging story in one paragraph

A keiro service is event-sourced: every state change is an immutable event appended to a
stream in the kiroku PostgreSQL event store. Internal orchestration — "when X happens in
aggregate A, do Y to aggregate B, and give up after 48 hours" — is the job of a
*process manager* (also called a saga): a component that reacts to events, keeps its own
durable state, dispatches commands, and schedules *durable timers* (rows in a database
table fired later by a worker). Cross-service communication is the job of *integration
events*: stable, versioned, public messages minted from private domain events, written
to an *outbox* table in the same transaction as the local state change, published to a
transport (Kafka today) by a separate worker, and consumed idempotently through an
*inbox* table on the other side. All asynchronous processing — process-manager workers,
outbox publishers, inbox consumers, background jobs — runs on *shibuya*, a supervised
queue-processing framework in which a handler returns an *ack decision* (an intent
value: succeed, retry, dead-letter, or halt) and the framework owns the mechanics.
Delivery is at-least-once everywhere, so every handler and finalizer in the fleet must
be idempotent. These italicized terms are exactly what `messaging/glossary.md` will
define.

### Source repositories (read these; the docs must match them)

Every claim in the new docs must be verifiable against these sources on disk. Full
paths, since they live outside this repository:

- `/Users/shinzui/Keikaku/bokuno/keiro` — the keiro framework (release train 0.3.0.0).
  Key modules for this plan: `keiro/src/Keiro/ProcessManager.hs` (the saga abstraction),
  `keiro/src/Keiro/Timer.hs` (durable timers), `keiro/src/Keiro/Outbox.hs` and
  `keiro/src/Keiro/Inbox.hs` (outbox/inbox), `keiro-core/src/Keiro/Integration/Event.hs`
  (the integration-event envelope — deliberately in `keiro-core` so it is a stable
  contract), `keiro-pgmq/src/Keiro/PGMQ/{Job,Runtime}.hs` (typed jobs). Maintained user
  docs at `docs/user/` (notably `process-managers-and-timers.md`,
  `integration-events.md`, `outbox.md`, `inbox.md`) and the runnable example package
  `jitsurei/` (`jitsurei/app/Main.hs`, `jitsurei/src/Jitsurei/FulfillmentProcess.hs`,
  `EscalationProcess.hs`). Roadmap doc
  `docs/roadmap/pgmq-as-transport-for-integration-events.md` (the "case A / case B"
  framing the transport matrix cites).
- `/Users/shinzui/Keikaku/bokuno/shibuya-project/shibuya` — shibuya-core 0.8.0.1:
  `shibuya-core/src/Shibuya/{Adapter,Handler,Policy,App,Batch}.hs`,
  `shibuya-core/src/Shibuya/Core/{Types,Ack,Ingested,Retry}.hs`,
  `shibuya-core/src/Shibuya/Internal/Runner/{Supervised,Finalize}.hs`.
- `/Users/shinzui/Keikaku/bokuno/shibuya-project/shibuya-pgmq-adapter` — 0.12.0.0:
  `src/Shibuya/Adapter/Pgmq/{Config,Convert,Internal}.hs` and `src/Shibuya/Adapter/Pgmq.hs`.
- `/Users/shinzui/Keikaku/bokuno/shibuya-project/shibuya-kafka-adapter` — 0.8.0.1:
  `src/Shibuya/Adapter/Kafka.hs` (the module header, lines ~39–90, states the hard
  limits) and `src/Shibuya/Adapter/Kafka/{Convert,Internal}.hs`.
- `/Users/shinzui/Keikaku/bokuno/libraries/pgmq-hs-project/pgmq-hs` — pgmq-hs 0.4.x
  (pgmq-core types, pgmq-effectful `Pgmq` effect and `isTransient` error
  classification, pgmq-config `ensureQueuesEff`).
- `/Users/shinzui/Keikaku/bokuno/kiroku-project/kiroku` — the event store; the piece
  this plan needs is `shibuya-kiroku-adapter/src/Shibuya/Adapter/Kiroku.hs` (0.4.0.0:
  `kirokuAdapter`, `guardKirokuHandler`, `kirokuConsumerGroupProcessors`) plus the
  subscription semantics in `kiroku-store/src/Kiroku/Store/Subscription*` (at-least-once,
  checkpoint per batch, retry 5 total deliveries then dead-letter).
- `/Users/shinzui/Keikaku/bokuno/danwa` — the DDD worked example; the real-world
  evidence for the decision ladder and the deterministic-outbox-id pattern:
  `danwa-core/src/Danwa/Integration/AddressedMessage.hs`,
  `danwa-workers/src/Danwa/Integration/{AddressedMessageWorker,OutboxPublisherWorker}.hs`,
  `danwa-workers/src/Danwa/Conversation/AgentSummaryWorker.hs`,
  `danwa-workers/src/Danwa/Workers/Subscription.hs`, `docs/integration-events.md`.
  Caveat: danwa is pinned to an older cohort (codd, pre-0.2 keiro), so cite it for
  *patterns*, never for current API spellings — verify spellings against keiro 0.3.
- `/Users/shinzui/Keikaku/bokuno/keiro-runtime-jitsurei` — two bounded-context services
  on the current cohort; `services/hospital-capacity/hospital-capacity.keiro` declares
  DSL `process`, `contract`, `publisher`, and queue nodes (evidence that the DSL path is
  real, and for what the generated module ring looks like).

### Terms this plan itself uses

*mori* is the local dependency/documentation registry; `mori.dhall` in this repo's root
declares the project and its `docs` list, each entry a `Schema.DocRef` record with a
unique `key`, a `kind` (Guide, Reference, BestPractice, Pattern, Notes, ...), an
`audience`, a `description`, and a `location` (here always
`Schema.DocLocation.LocalFile "<repo-relative path>"`). *Dhall* is a typed configuration
language; "dhall type-checks" means `dhall type --quiet --file mori.dhall` exits 0.
*seihou* is the project scaffolding system whose blueprints (EP-9) will cite these docs.
An *ADR* (Architecture Decision Record) is a short durable document recording an
architectural decision and its alternatives; they live in `docs/adr/` once that
directory exists.

### Coordination with sibling plans

Per MasterPlan Integration Point 1, this plan owns the `messaging/` directory and DocRef
keys shaped `messaging-<file-slug>`, appends its own block to `mori.dhall` without
reordering existing entries, and leaves the `dependencies` list to EP-2. Per Integration
Point 4, EP-4 owns the runtime glossary (validated event stream, the two-schema
arrangement, snapshot advisory-ness, `CommandAmbiguous` is never benign) and this plan
owns the messaging glossary (domain versus integration event, outbox/inbox, ack
decisions, at-least-once + idempotency); each links to the other and never redefines.
Per Integration Point 3, module *placement* (where worker and integration modules sit in
the vertical slice) is EP-6's standard — the messaging docs describe behavior and name
module paths from the worked examples as evidence, but must not legislate placement;
where placement matters, write "see the structure standard (`architecture/`, EP-6)".
Style follows Integration Point 2, restated fully in the Plan of Work below so this plan
stays self-contained.


## Plan of Work

The work is five milestones. Each writes complete, self-contained documents; each is
independently verifiable (the docs exist, read correctly, and their claims grep-match
the sources). The style contract for every document, from MasterPlan Integration
Point 2: no YAML frontmatter; a single `#` H1 title; a bold one-line tagline directly
under the H1; a one-paragraph scope statement; prescriptive rule-first prose ("The rule
is one sentence: ..."); code samples with language tags using `-- CORRECT` / `-- WRONG`
contrast pairs where a rule can be violated in code; relative cross-links between docs;
a trailing "Related Patterns" section linking siblings. Model the voice on
`keiki/transducer-best-practices.md` in this repository. Docs state rules in the
present tense and cite evidence tersely (module names, not line numbers — line numbers
rot).

### Milestone 1 — glossary and index stub

Scope: create the `messaging/` directory with the shared vocabulary document that every
later document links to instead of redefining terms, plus a README stub so the area is
navigable from the first commit. At the end of this milestone `messaging/glossary.md`
and `messaging/README.md` exist and read complete; acceptance is that every term listed
below has a definition and the two forward-link rules hold.

`messaging/glossary.md` — tagline like "**The shared vocabulary for keiro messaging:
one definition per term, linked everywhere, restated nowhere.**". Define, in plain
language, one short paragraph each:

- *Domain event*: a private, immutable fact recorded in one service's own event stream
  (a kiroku `RecordedEvent`). Its shape may change freely; nothing outside the service
  may read it. THE boundary entry pairs it with:
- *Integration event*: a stable public contract another service may consume — the
  `IntegrationEvent` envelope defined in `Keiro.Integration.Event` (in the `keiro-core`
  package precisely so it is a dependency-light stable contract). The glossary states
  the rule: domain events are private and free to evolve; integration events are public,
  versioned, and minted deliberately — never leak a domain event across a service
  boundary. Link to `integration-events.md` for the full standard.
- *Outbox*: the pattern (and the `keiro.keiro_outbox` table) that makes "decide to
  publish" transactional with local state: rows written in the same database
  transaction as the state change, published later by a separate worker. Link
  `outbox.md`.
- *Inbox*: the mirror-image pattern (`keiro.keiro_inbox`) making consumption idempotent:
  the handler's local effect and the dedupe record commit in one transaction, keyed on
  `(source, messageId)`. Link `inbox.md`.
- *Ack decision*: shibuya's `AckDecision` — `AckOk`, `AckRetry RetryDelay`,
  `AckDeadLetter DeadLetterReason`, `AckHalt HaltReason`. The handler expresses intent;
  the framework owns finalization mechanics. Link `shibuya-processing.md`.
- *At-least-once + idempotency*: every transport in the fleet delivers at least once
  (crash between effect and acknowledgment causes redelivery), therefore every handler,
  finalizer, and timer-fire action must be idempotent. This is the fleet's single most
  load-bearing invariant; state it as such.
- *Process manager (saga)*: a stateful coordinator that reacts to events by stepping its
  own event-sourced state stream, dispatching commands to target aggregates, and
  scheduling timers — `Keiro.ProcessManager`. Contrast in one sentence each with
  *router* (stateless, resolves targets from a read model — `Keiro.Router`), *reactor*
  (a hand-rolled stateless shibuya worker), and *durable workflow* (imperative
  long-running sequence — `Keiro.Workflow`; the workflow standard is the runtime doc
  area's, link `../keiro/README.md`).
- *Durable timer*: a `keiro.keiro_timers` row scheduled transactionally and fired
  at-least-once by a timer worker; the mechanism behind saga timeouts and delays.
- *Adapter*, *envelope*, *message/ingested split*: shibuya's transport plug-in
  (`Adapter es msg`: a name, a stream of ingested messages, a shutdown action), the
  transport-neutral `Envelope` (messageId, cursor, partition, attempt, traceContext,
  payload), and the rule that handlers receive a read-only `Message` while the framework
  alone holds the `AckHandle`.
- *Dead letter*: a message set aside durably after retries are exhausted or on poison
  input, instead of blocking the stream — pgmq DLQ queues, `kiroku.dead_letters`,
  `keiro.keiro_dead_letters` are the three concrete homes.
- *Consumer group*, *checkpoint/cursor*: partitioned parallel consumption of one
  subscription with per-member durable positions.
- *Visibility timeout (VT)*: pgmq's lease — an in-flight message is invisible until the
  VT expires, then redelivered; VT (not retry policy) governs crash redelivery cadence.
- *Poison message*: an input that deterministically fails every delivery (undecodable or
  guaranteed-to-crash); policy for these is explicit everywhere (`PoisonPolicy`,
  disposition tables, DLQ).
- *Correlation id / causation id*: correlation groups every event of one business
  process; causation points to the event that directly caused this one; the process
  manager's `correlate` function derives the correlation key that names its stream.

End the glossary with a short "Runtime terms live elsewhere" paragraph: validated event
stream, the two-schema arrangement (`kiroku` store schema versus the dedicated `keiro`
framework schema), snapshot semantics, and `CommandAmbiguous` are defined in the keiro
runtime docs — link `../keiro/README.md` — and this glossary never redefines them.

`messaging/README.md` stub — H1, tagline ("**How keiro services orchestrate internally
and talk to each other: the standards index.**"), scope paragraph, and a list linking
`glossary.md` with one-line description plus placeholder entries for the docs of M2–M5
(so the index is born complete in intent and each later milestone only fills in its
line). Milestone 5 finalizes it.

### Milestone 2 — the process manager standard

Scope: write `messaging/process-managers.md`, the standard for stateful orchestration.
This is the largest single document; at the end of the milestone it exists and every
symbol it names greps in `keiro/src/Keiro/ProcessManager.hs` or
`keiro/src/Keiro/Timer.hs`. It must cover, in this order:

**Anatomy.** The `ProcessManager` definition record and what each field means. Embed the
shape (this is the current 0.3 source, verify before publishing):

```haskell
data ProcessManager input phi rs s ci co targetPhi targetRs targetState targetCi targetCo
  = ProcessManager
      { name              :: Text                 -- stable identity; part of every deterministic write id
      , correlate         :: input -> Text        -- input event -> correlation key (selects the manager instance)
      , eventStream       :: ValidatedEventStream phi rs s ci co
                                                  -- the manager's OWN event-sourced saga stream
      , streamFor         :: Text -> Stream (EventStream phi rs s ci co)
                                                  -- correlation key -> manager stream handle
      , targetEventStream :: ValidatedEventStream targetPhi targetRs targetState targetCi targetCo
      , targetProjections :: Stream targetCi -> [InlineProjection targetCo]
                                                  -- run in the SAME transaction as each dispatched command; [] for append-only
      , handle            :: input -> ProcessManagerAction ci targetCi   -- the PURE reaction
      }
```

State the two defining properties as rules. One: the saga's state *is* its own event
stream — it is itself event-sourced, not a row in a side table, so saga progress is
auditable and replayable like any aggregate. Stream naming convention
`pm:<manager-name>-<correlation-id>`, which puts every instance of one manager in the
kiroku category `pm:<manager-name>`; each process-manager type therefore gets its own
category subscription (never share one subscription across manager types, and prefer a
category subscription over all-streams — danwa's all-streams subscriptions are its
acknowledged non-optimality). Two: `handle` is pure — `input ->
ProcessManagerAction ci targetCi` where `ProcessManagerAction` is
`{ command :: ci, commands :: [PMCommand targetCi], timers :: [TimerRequest] }` — and
`runProcessManagerOnce` applies all three atomically with crash-safe idempotency.
`PMCommand` is `{ target :: Stream targetCi, command :: targetCi }`.

**Idempotency.** Every write the manager makes — its own state append, each dispatched
command, each timer — is keyed by `deterministicCommandId`, a UUIDv5 over
`(name, correlation, source event id, emit index)`. The manager pre-checks each id with
`eventAlreadyIn` and folds the store's duplicate rejection into benign
`PMCommandDuplicate` / `PMStateDuplicate` (helper: `confirmBenignDuplicate`). Replaying
the same source event appends nothing new; that is what makes the worker crash-safe
under at-least-once delivery. Per-dispatch outcomes: `PMCommandResult` is
`PMCommandAppended CommandResult | PMCommandDuplicate EventId | PMCommandFailed
StreamName CommandError`; the manager-state append (`PMStateResult`) has no failure
constructor — a genuine state-append error aborts the whole reaction.

**The worker.** `runProcessManagerWorkerWith :: WorkerOptions es msg ->
RunCommandOptions -> ProcessManager ... -> Adapter es msg -> (msg -> Maybe
(RecordedEvent, input)) -> Eff es ()` — the manager runs as a live consumer of a shibuya
`Adapter` (in practice the kiroku adapter over the `pm:` source category, see
`kiroku-subscriptions.md`). Each ack handle is finalized exactly once: successful and
duplicate dispatches ack `AckOk`; transient store failures ack `AckRetry` (delay from
`transientRetryDelay`); systemic deterministic failures ack `AckHalt`; rejection-class
failures follow `RejectedCommandPolicy`; undecodable messages (the decoder returned
`Nothing`) follow `PoisonPolicy`. `WorkerOptions` is `{ poisonPolicy ::
PoisonPolicy es msg, rejectedCommandPolicy :: RejectedCommandPolicy, transientRetryDelay
:: RetryDelay, metrics :: Maybe KeiroMetrics }`; `PoisonPolicy` is `PoisonHalt |
PoisonSkip | PoisonDeadLetter`; `RejectedCommandPolicy` is `RejectedHalt |
RejectedDeadLetter | RejectedSkip`. Defaults are `PoisonHalt` + `RejectedHalt` — halt
first, so an operator cannot miss a failure; relax to dead-letter policies only once a
dead-letter review loop exists. Transient-versus-deterministic classification is
explicit framework code (`isTransientStoreError`, `isTransientCommandError`,
`isRejectionClass`, `decideForFailures`) — handlers never guess. Note that
`CommandAmbiguous` is never benign (several matched transducer edges is an
aggregate-definition bug; workers halt; the DSL rejects `on-ambiguous => Fired` as
`AmbiguousMarkedBenign`) — one sentence here, definition linked to
`../keiro/README.md`.

**Durable timers** (section within this doc). A reaction schedules timers by returning
`TimerRequest` values; `runProcessManagerOnce` persists them with `scheduleTimerTx` in
the same append transaction — a timer is never scheduled for a state change that did not
commit. The timer worker (`runTimerWorker` / `runTimerWorkerWith`) claims one due
`keiro.keiro_timers` row at a time with `FOR UPDATE SKIP LOCKED` (`claimDueTimer`), so
multiple workers are safe; it hands the row to a caller-supplied fire action that
typically dispatches a command back into the manager, then marks it fired
(`markTimerFired`). A row left in `Firing` by a crash becomes claimable again after
`TimerWorkerOptions.requeueStuckAfter` — at-least-once firing, so timer handlers must be
idempotent (the deterministic-id discipline covers this when the fire action goes
through the manager). `TimerWorkerOptions` also carries `maxAttempts :: Maybe Int`
(exceeding it dead-letters the timer via `deadLetterTimer` instead of firing). Recovery
surface: `countDueTimers`, `countStuckTimers`, `findStuckTimers`, `requeueStuckTimers`,
`cancelTimer`, `deadLetterTimer`.

**DSL note** (one paragraph). `process` and `timer` are first-class keiro-dsl nodes; the
scaffolder emits the `Generated.Process` / `ProcessHarness` ring while the reaction
logic stays a hand-owned hole; node-level `rejected` and `poison` policies are
mandatory, and every timer `fire` must carry an `on-ambiguous` arm. Evidence:
`hospital-capacity.keiro` in keiro-runtime-jitsurei declares a `process` node
(HospitalSurge). DSL adoption guidance is EP-4's doc; link forward.

**THE DECISION LADDER** (its own `##` section — this is the part agents will quote).
Three rungs, each with when-to-choose rules and real evidence:

1. *Hand-rolled stateless reactor* — a plain shibuya worker, no saga stream, no timers.
   Choose when the reaction needs no per-correlation state and no deadline: it is a pure
   event-carried trigger, possibly joining a read model for context. Evidence: danwa's
   `AddressedMessageWorker` (`danwa-workers/src/Danwa/Integration/AddressedMessageWorker.hs`)
   — an all-streams kiroku subscription that fires only on `EmbellishmentAdded` mention
   events, joins the `danwa.danwa_messages` read model for the payload, writes a
   deterministic outbox row, and — the signature move — returns `AckRetry` when the
   message row is not yet projected (`MessageNotYetProjected`), letting at-least-once
   redelivery wait for the projection to catch up instead of coordinating with it.
   Document that reactor + read-model join + retry-until-projected is the sanctioned
   pattern for "react to X with context from Y".
2. *Full keiro `ProcessManager`* — choose when any of: the reaction depends on what has
   already happened in this process instance (state per correlation id that must
   survive crashes and be auditable); the process needs timeouts/deadlines/scheduled
   retries (durable timers); or it dispatches commands to aggregates and needs the
   deterministic-id idempotency and rejected/poison policy machinery for free. Evidence:
   keiro's `jitsurei` package `FulfillmentProcess` and `EscalationProcess`; the DSL
   `process` node in keiro-runtime-jitsurei.
3. *Durable workflow* (`Keiro.Workflow`) — choose when the orchestration reads as one
   long-lived imperative sequence (do A, await B or sleep 2h, then C, maybe
   `continueAsNew`) rather than open-ended reaction to events. The workflow standard
   itself is the runtime doc area's (EP-4); this doc gives only the selection rule and
   links `../keiro/README.md`.

Close the ladder with the rule of thumb, stated once: start at the lowest rung that
holds; a reactor that starts accumulating state or hand-rolled deadline logic is a
process manager wearing a costume — promote it.

**Related Patterns** trailer: `kiroku-subscriptions.md` (the adapter the worker
consumes), `outbox.md` (emitting integration events from a saga via the inline escape
hatch), `shibuya-processing.md` (ack semantics), `gotchas.md`, `../keiki/README.md`
(the manager's own state machine is a keiki transducer).

### Milestone 3 — the integration event standard

Scope: write the three cross-service communication docs. At the end they exist,
grep-check against `keiro-core/src/Keiro/Integration/Event.hs`,
`keiro/src/Keiro/Outbox.hs`, `keiro/src/Keiro/Inbox.hs`, and the danwa evidence files.

`messaging/integration-events.md` — the contract standard.

- **The boundary** (open with it; link the glossary entry rather than redefining): a
  domain event is a private fact, an integration event is a published contract. The
  operational rules that follow: a service may never read another service's tables,
  private event streams, or private event names; consumers consume only the published
  envelope and payload schema (evidence: danwa `docs/integration-events.md` states
  exactly this for its consumers).
- **The envelope.** `IntegrationEvent` in `Keiro.Integration.Event` (keiro-core), field
  by field: `messageId`, `source`, `destination`, `key :: Maybe Text`, `eventType`,
  `schemaVersion :: Int`, `contentType`, `schemaReference`, `sourceEventId`,
  `sourceGlobalPosition`, `payloadBytes :: ByteString`, `occurredAt`, `causationId`,
  `correlationId`, `traceContext`, `attributes`. The envelope is byte-oriented —
  `payloadBytes`, with JSON (`ApplicationJson`) the v1 default `contentType`; the
  contract does not commit to JSON (a future schema-registry/Avro adapter fills
  `schemaReference` and an `OtherContentType` without touching outbox/inbox storage).
  Helpers: `encodeJsonIntegrationEvent`, `decodeJsonIntegrationEvent`,
  `integrationPayload`, `integrationHeaders`. Wire headers are the `keiro-*` family
  (e.g. `keiro-message-id`, `keiro-source`, `keiro-destination`,
  `keiro-schema-version`) plus W3C `traceparent`/`tracestate`.
- **Identity rules** (the heart of the doc; state as numbered rules). (1) `messageId` is
  an application-level, time-ordered id — keiro's canonical producer mints a prefixed
  UUIDv7 TypeID via `mintIntegrationEvent` — and is *stable across publish retries*: the
  same decision to publish carries the same `messageId` no matter how many times the
  publisher worker retries. (2) Consumer dedupe is on `(source, messageId)` — never on
  Kafka topic/partition/offset; broker coordinates are stored for diagnostics only
  (offsets change on repartition, replay, and mirror; `(source, messageId)` never
  does). (3) `destination` carries the contract's major version by convention —
  `"billing.orders.v1"`; a breaking payload change is a new major and a new destination
  topic, run side by side during migration. (4) `schemaVersion :: Int` tracks additive
  (minor) evolution within a destination. (5) `key` is the partition key (normally the
  aggregate id): everything with the same key is delivered in producer order to one
  consumer at a time; events without ordering needs leave it `Nothing`.
- **Trace continuation.** `traceContext` on the envelope, `traceparent`/`tracestate`
  persisted as columns on both outbox and inbox rows, so a consumer span can be created
  with a remote parent across the async boundary — the fleet's telemetry story does not
  break at service edges.
- Related Patterns: `outbox.md`, `inbox.md`, `glossary.md`, `transport-selection.md`.

`messaging/outbox.md` — the publishing standard.

- **The rule first**: never publish to a broker from a command handler or projection —
  the decision to publish must commit atomically with the local state that caused it,
  and only an outbox row does that. Then the pattern in keiro's shape, three moving
  parts:
- **The producer.** `IntegrationProducer` (`mkIntegrationProducer`) defines and validates
  a pure mapping from private events to `IntegrationEventDraft`; it is not a
  checkpoint-owning subscription runner. Application wiring must make source checkpoint
  plus enqueue atomic or reuse stable message and outbox identities across redelivery,
  because `enqueueProducerEventTx` mints a fresh message id on each call. It never
  touches Kafka. The inline escape hatch for
  sagas/process managers that must emit without an intermediate private event is
  `enqueueIntegrationEventTx` (+ `freshOutboxId`) inside the caller's transaction — with
  the documented caveat: per-key ordering sorts by `created_at` (transaction start
  time); the canonical producer serializes same-key enqueues, but concurrent inline
  enqueues for the same key must serialize themselves or accept best-effort order.
- **The publisher worker.** `publishClaimedOutbox` claims rows (`FOR UPDATE SKIP
  LOCKED` plus the configured `OrderingPolicy`, enforcing per-key head-of-line ordering
  at claim time: a failing head row blocks its key, not the world), hands batches to a
  caller-supplied publish function, marks rows sent / retryable / dead after
  `max_attempts` (`markOutboxSent`, `PublishOutcome`). Transport neutrality is
  deliberate: keiro has no `hw-kafka-client` dependency; `Keiro.Outbox.Kafka` provides
  `outboxRowToKafkaRecord` / `integrationEventToKafkaRecord` and the application owns
  the producer. Evidence: danwa's `OutboxPublisherWorker` drives this from a 1-second
  `pollingStream` tick adapter, keeps the real Kafka producer behind a cabal flag, and
  on publish failure marks rows retryable — never dropped.
- **The maintenance pass.** `outboxMaintenancePass` on a separate slower schedule
  reclaims rows stuck in `publishing` by crashed workers (`requeueStuckOutbox`) and
  samples the backlog gauge (`countOutboxBacklog`). Schedule `garbageCollectSent`
  independently for retention.
- **Deterministic outbox ids.** When the producer may run more than once for the same
  triggering fact (any reactor under at-least-once delivery), derive the outbox id
  deterministically from the fact instead of minting fresh per attempt, so redelivery
  coalesces to one row. Evidence: danwa computes a UUIDv5
  (`UUID.V5.generateNamed UUID.V5.namespaceURL`) over
  `"danwa:message-addressed-to-agent:<messageId>:<agentId>"` and its worker spec asserts
  exactly-one-outbox-row under redelivery. Point out the rhyme: keiro's own
  `deterministicCommandId` is the same UUIDv5-over-facts technique — this is the fleet's
  standard idempotency-key recipe.
- Related Patterns: `integration-events.md`, `inbox.md`, `process-managers.md`,
  `gotchas.md`.

`messaging/inbox.md` — the consumption standard.

- **The rule first**: consuming an integration event must be idempotent, and the only
  reliable idempotency is transactional — the handler's local effect and the dedupe
  record commit together. In keiro that is the `runInboxTransaction*` family (seven
  exported variants: base, `With`, `WithKey`, `WithRetries`, `WithRetriesWith`,
  `WithRetriesKey`, `Batch`): each wraps the handler in one database transaction that
  records `(source, messageId)` in `keiro.keiro_inbox` and runs the local effect
  at-most-once per that key. `With`-suffixed variants control success-path persistence
  (`PersistFullEnvelope` versus `PersistDedupeOnly`); `WithRetries` variants add a
  bounded attempt ceiling for transiently-failing handlers; `Batch` resolves a whole
  Kafka poll batch. Kafka topic/partition/offset are stored for diagnostics only —
  restate the identity rule from `integration-events.md` in one sentence and link.
- **Disposition completeness.** Every message class must have a defined outcome before
  the consumer ships: duplicate → acknowledge without re-running the effect; transient
  failure → bounded retry; poison (undecodable or deterministically failing) →
  dead-letter with `markFailedTx`. No implicit fourth bucket. The keiro-dsl `intake`
  node checker enforces a complete disposition table mechanically; hand-written
  consumers must uphold the same completeness by review.
- **Operations surface**: `lookupInbox`, `listInbox`, `countInboxBacklog`,
  `sampleInboxBacklog`, `garbageCollectCompleted`; traceparent/tracestate columns give
  consumer spans a remote parent.
- Related Patterns: `integration-events.md`, `outbox.md`, `shibuya-processing.md`,
  `gotchas.md`.

### Milestone 4 — the transport standards

Scope: write the four transport docs. Grep-checks run against shibuya-core, the two
adapters, keiro-pgmq, and the kiroku adapter.

`messaging/shibuya-processing.md` — the semantics every worker inherits.

- The mantra up front: handlers express *intent* via `AckDecision`; the framework owns
  *mechanics* (finalization, retries, supervision, backpressure, tracing). `Handler es
  msg = Message es msg -> Eff es AckDecision`. Handlers receive a read-only `Message`;
  the `AckHandle` lives on the framework side of the `Ingested`/`Message` split and is
  finalized exactly once per message by the runner — handler code can neither ack twice
  nor forget to ack.
- The decisions and their meanings: `AckOk`; `AckRetry RetryDelay`; `AckDeadLetter
  DeadLetterReason` (`PoisonPill`, `InvalidPayload`, `MaxRetriesExceeded`); `AckHalt
  HaltReason` (`HaltOrderedStream`, `HaltFatal` — stop this processor, do not advance).
- The two safety substitutions, as rules with consequences: a handler that *throws* is
  substituted with `AckRetry (RetryDelay 0)` — never a lost message, but an
  always-throwing handler is a redelivery storm; catch and return explicit decisions for
  poison inputs. A *finalizer* that throws is retried with the *same* decision on a
  `[10ms, 50ms, 250ms]` schedule, then the processor halts — therefore finalizers must
  be idempotent (adapter authors' contract; consumers meet it automatically when using
  the shipped adapters).
- Ordering and concurrency are opt-in policy: `OrderingPolicy = StrictInOrder |
  PartitionedInOrder | Unordered`; `Concurrency = Serial | Ahead n | Async n`;
  `validatePolicy` enforces StrictInOrder ⇒ Serial; `Ahead` preserves yield order, not
  side-effect or ack order.
- Delivery is at-least-once, full stop; there is no core-level dead-letter queue or
  max-retry counter — both are adapter concerns (which is exactly why the transport
  matters; link `transport-selection.md`).
- The batch API for high-throughput consumers: `BatchHandler = BatchInfo -> NonEmpty
  (Message es msg) -> Eff es BatchAck`, `BatchConfig` (size/timeout, defaults 100
  messages / 1 second), `BatchAck { decisions :: Map MessageId AckDecision, fallback }`
  with helpers `ackAllOk` / `ackAll` / `ackExcept` / `withFallback` / `failMessages` —
  resolution must be complete and deterministic per retained message.
- Supervision and shutdown: `runApp AppConfig{strategy, inboxSize}` with
  `SupervisionStrategy = IgnoreFailures | StopAllOnFailure` (default IgnoreFailures,
  inbox 100); `stopAppGracefully` signals adapter shutdown, drains with a 30-second
  default `drainTimeout`, returns False if it had to force.
- Related Patterns: `transport-selection.md`, `pgmq-jobs.md`,
  `kiroku-subscriptions.md`, `process-managers.md`.

`messaging/transport-selection.md` — the adapter selection matrix. Open with the
one-sentence shape of the choice: pgmq and Kafka carry messages *between* systems or for
background work; the kiroku adapter is how a service consumes *its own event log* — it
is not a cross-service transport. Then reproduce the matrix (this table is the document;
keep it current against the adapter sources):

| Dimension | pgmq | kafka | kiroku subscription |
|---|---|---|---|
| Payload | aeson `Value` | `Maybe ByteString` | `RecordedEvent` |
| Delivery | at-least-once | at-least-once | at-least-once, ack-coupled |
| Lease / VT | yes (VT, extendable) | none | none |
| `attempt` counter | yes (readCount) | **no — always `Nothing`** | yes (bounded by RetryPolicy) |
| Concurrency | Serial / Ahead / Async + FIFO groups | **Serial only (unenforced)** | PartitionedInOrder / Serial |
| Retry mechanism | extend visibility timeout | seek back to offset | ack-coupled redelivery |
| Dead letters | yes (archive / direct / topic, transactional) | **none — dropped with a stderr warning** | `kiroku.dead_letters` |
| Ordering | per-group FIFO | per-partition (given Serial) | per-stream within group |
| Configuration | full config value | topics only; consumer props external | subscription target/name |

Spell out the Kafka consumer's hard limits in prose, because a table cell cannot carry
the consequences: the shibuya Kafka adapter must run `Serial` — librdkafka stores the
highest offset per partition with no gap tracking, so `Async`/`Ahead` can commit past a
failed message; this is a caller contract, not enforced at runtime. `Envelope.attempt`
is always `Nothing` — retry-by-count is impossible on Kafka; use `AckHalt` or external
bookkeeping. `AckDeadLetter` on Kafka logs to stderr and stores the offset — the message
is *dropped*; if you need recoverability you must wire your own DLQ producer. Then the
rule of thumb, verbatim as the standard: **pgmq for in-context jobs and anything needing
DLQ, retry caps, leases, or ordered groups without a broker; Kafka for cross-context
event streaming where a cluster exists and you can guarantee serial consumption and
supply your own DLQ/retry bookkeeping.** Note that keiro's outbox/inbox ship Kafka
transport codecs today, and that "pgmq as integration-event transport" (case B in
`keiro/docs/roadmap/pgmq-as-transport-for-integration-events.md`) is roadmap, not
scheduled — do not design against it. Close with an explicit note: this selection
rationale is an ADR candidate per the MasterPlan; when `docs/adr/` is seeded, this doc
links to the ADR and keeps only the matrix. Related Patterns: `shibuya-processing.md`,
`pgmq-jobs.md`, `kiroku-subscriptions.md`, `integration-events.md`.

`messaging/pgmq-jobs.md` — the typed background-job standard (keiro-pgmq).

- Purpose framing: keiro-pgmq exists for transient background jobs that are *not*
  domain events (thumbnails, notification sends, summary generation) — work you would
  regret modeling as events. Declarative job: `Job p = { jobName, jobQueue, jobCodec,
  jobPolicy }`; handlers return `JobOutcome = Done | Retry | RetryDefault | Dead` —
  keiro-pgmq never exposes shibuya wire types to job code. `RetryPolicy { maxRetries,
  defaultRetryDelay, useDeadLetter }`; always construct with `mkRetryPolicy` — it
  rejects `maxRetries = 0`, which the raw constructor allows and which dead-letters
  every message before the handler ever runs (read_ct is already 1 on first delivery).
- Producers: `enqueue`, `enqueueWithHeaders`, `enqueueTraced`, `enqueueToGroup` /
  `enqueueToGroupWithDelay` (FIFO message groups — per-group ordered delivery).
  Consumers: `jobProcessor` builds the shibuya `QueueProcessor`; `runJobWorkers` for the
  continuous supervised cadence, `runJobOnce` / `runJobOnceWithContext` for one-shot
  drains (CLI-driven workers). Queues are provisioned idempotently at boot
  (`ensureJobQueue`, via pgmq-config's additive reconciler).
- The VT rule, prominently: the visibility timeout governs *crash* redelivery cadence —
  not `RetryPolicy.defaultRetryDelay`, which only governs explicit `Retry` outcomes —
  and every VT expiry burns one `read_ct` toward `maxRetries`. Set VT comfortably above
  worst-case handler time or crashes eat the retry budget.
- The `QueueRef` sanitization gotcha, prominently: dotted logical names are sanitized to
  PGMQ-legal physical names (plus a `_dlq` sibling); the mapping is lossy (`"a.b"` and
  `"a_b"` collide) and names longer than 43 characters get an FNV-1a-64 hash suffix —
  renaming a job or queue can silently repoint to a *new empty physical queue* while the
  old one still holds messages. Treat queue logical names as frozen identifiers; if you
  must rename, drain first.
- Evidence: danwa's `AgentSummaryWorker` (pgmq worker with `maxRetries = 3` and a direct
  dead-letter queue; invalid payloads dead-lettered immediately, DB errors retried),
  deliberately placed in the Conversation vertical slice — placement rules belong to the
  structure standard (EP-6).
- Related Patterns: `transport-selection.md`, `shibuya-processing.md`, `gotchas.md`.

`messaging/kiroku-subscriptions.md` — the bridge rules for consuming the event log.

- What it is: `kirokuAdapter store config` wraps a kiroku push subscription
  (`subscriptionAckStream`) into a shibuya `Adapter es RecordedEvent`. It is
  ack-coupled: the underlying kiroku worker blocks per event until the shibuya
  `AckDecision` is finalized, and that decision drives the durable checkpoint. Mapping,
  stated exactly: `AckOk` → `Continue` (checkpoint past the event); `AckRetry delay` →
  `Retry` (redeliver, bounded by the subscription `RetryPolicy` — default 5 total
  deliveries — then dead-letter as `DeadLetterMaxAttempts`); `AckDeadLetter` → record in
  `kiroku.dead_letters` and advance; `AckHalt` → cancel the subscription without
  advancing, so the halting event is redelivered on restart.
- **Prefer `guardKirokuHandler`.** Shibuya 0.8.0.1 catches a thrown handler and finalizes
  `AckRetry (RetryDelay 0)`, so the supported cohort does not leave the ack unfilled.
  The adapter guard changes that fallback to a one-second retry and avoids a hot loop.
  `kirokuConsumerGroupProcessors` applies the guard automatically.
- Consumer groups: `kirokuConsumerGroupProcessors` yields N named processors pinned to
  `(PartitionedInOrder, Serial)` — member concurrency is Serial by policy; streams are
  hashed to members in SQL (`hashtextextended(stream_id::text, 0) % size`); each member
  checkpoints independently under `(subscriptionName, member)`; scale across processes
  by running one adapter per process with a distinct member index.
- Subscription semantics inherited from kiroku, briefly: at-least-once, checkpoint
  per-batch, handlers idempotent; a stopped subscription is *absence* in
  `subscriptionStates`, never a "stopped" phase — alert on missing keys. Prefer
  per-category subscriptions over all-streams as the service grows (each process
  manager already gets its own `pm:<name>` category — link `process-managers.md`).
- Related Patterns: `process-managers.md`, `shibuya-processing.md`,
  `transport-selection.md`, `gotchas.md`.

### Milestone 5 — gotcha catalogue, index, registry, validation

Scope: write the consolidated gotcha catalogue, finalize the README index, register all
eleven docs in `mori.dhall`, run the full validation pass, and perform the ADR
distillation step.

`messaging/gotchas.md` — tagline like "**Eighteen ways the messaging stack will bite
you, and the rule that prevents each.**". Format: a numbered list; each item is a bolded
one-line rule followed by one-to-three plain sentences of why and where. Cross-link the
owning doc per item. The items (consolidated from the shibuya/pgmq and keiro evidence;
each must survive its grep-check):

1. Kafka dead letters are silently dropped — the shibuya Kafka adapter has no DLQ
   producer; `AckDeadLetter` warns on stderr and commits the offset. Wire your own DLQ
   or do not rely on dead-lettering on Kafka.
2. The Kafka adapter must run `Serial`; nothing enforces it. Async/Ahead can commit
   offsets past a failed message (librdkafka gap-free offset store).
3. `Envelope.attempt` is always `Nothing` on Kafka — retry-by-count is impossible there.
4. pgmq crash redelivery is governed by the visibility timeout, not the retry delay;
   every VT expiry burns one `read_ct` toward `maxRetries`. Set VT ≥ worst-case handler
   time.
5. pgmq `maxRetries = 0` dead-letters every message before the handler runs;
   `mkRetryPolicy` rejects it, raw constructors do not.
6. The supervised pgmq adapter's direct/topic DLQ transfer is transactional, while
   Keiro's one-shot drain sends then deletes separately; know which boundary you run
   and keep one-shot handlers idempotent.
7. pgmq prefetch delays (never loses) messages on shutdown; keep
   bufferSize × batchSize × average processing time below the visibility timeout.
8. Finalizers must be idempotent — the framework re-runs a throwing finalizer with the
   same decision on a [10ms, 50ms, 250ms] schedule.
9. A throwing handler becomes `AckRetry 0`; on pgmq an always-throwing handler is an
   immediate redelivery storm. Catch and return explicit decisions for poison inputs.
10. A thrown handler becomes `AckRetry 0` in Shibuya 0.8.0.1; use
    `guardKirokuHandler` to make the Kiroku fallback a one-second retry instead of a
    zero-delay spin (group helpers guard automatically).
11. pgmq `Envelope.headers` is always `Nothing` on the worker path (JSONB headers are
    unordered); raw headers are only available on the one-shot drain via
    `JobContext`.
12. keiro-pgmq `QueueRef` sanitization is lossy — `"a.b"` and `"a_b"` collide, long
    names get hash suffixes, and renames can silently repoint to a fresh physical
    queue.
13. hasql statement/auth errors are classified permanent by `isTransient` — only
    connection/acquisition failures are retried; a SQL bug will not retry its way to
    green.
14. `CommandAmbiguous` is never benign — several matched edges is an
    aggregate-definition bug; process-manager workers halt on it, and the DSL rejects
    `on-ambiguous => Fired`.
15. Framework tables live in the dedicated `keiro` schema (`keiro.keiro_outbox`,
    `keiro.keiro_inbox`, `keiro.keiro_timers`, `keiro.keiro_dead_letters`) while the
    store connection's schema stays `kiroku` for LISTEN/NOTIFY — application SQL must
    schema-qualify; bare `keiro_*` names broke at keiro 0.2. (Definition of the
    two-schema arrangement: `../keiro/README.md`.)
16. Kafka is bring-your-own on both sides — keiro has no `hw-kafka-client` dependency;
    you own the producer/consumer and convert via `Keiro.Outbox.Kafka` /
    `Keiro.Inbox.Kafka`.
17. Transactional runners (outbox enqueue, inbox transactions, `runCommandWithSql`)
    require the `KirokuStoreResource` effect (acquire with `withKirokuStore`); plain
    `runCommand` does not.
18. Keep transactional continuations minimal — an appending transaction holds the
    global `$all` row lock until commit (kiroku's known single-writer throughput
    ceiling), so a slow outbox mapper or projection inside it stalls every writer;
    timer fire actions and inline projections should do the minimum transactional
    work.

`messaging/README.md` finalized — the complete index in reading order: glossary first;
then "orchestrating inside a service" (process-managers); then "talking to other
services" (integration-events, outbox, inbox); then "the processing substrate"
(shibuya-processing, transport-selection, pgmq-jobs, kiroku-subscriptions); then
gotchas. One line per doc; a closing pointer to `../keiki/README.md` (the state-machine
layer under aggregates and saga streams) and `../keiro/README.md` (the runtime core).

`mori.dhall` — append eleven `Schema.DocRef` entries at the end of the existing `docs`
list (after the last `keiki-*` entry, never reordering existing ones). All entries use
`audience = Schema.DocAudience.Module` and `location = Schema.DocLocation.LocalFile
"messaging/<file>"`. Keys and kinds:

- `messaging-overview` — `DocKind.Guide` — "Index of messaging standards for keiro services: process managers, integration events, transports; start here"
- `messaging-glossary` — `DocKind.Reference` — "Shared messaging vocabulary: domain vs integration events, outbox, inbox, ack decisions, at-least-once plus idempotency"
- `messaging-process-managers` — `DocKind.BestPractice` — "The process manager standard: saga streams, deterministic ids, worker policies, durable timers, and the orchestration decision ladder"
- `messaging-integration-events` — `DocKind.BestPractice` — "The integration event contract: envelope, identity and dedupe rules, topic versioning, trace continuation"
- `messaging-outbox` — `DocKind.BestPractice` — "Publishing through the transactional outbox: IntegrationProducer, publisher worker, maintenance pass, deterministic ids"
- `messaging-inbox` — `DocKind.BestPractice` — "Consuming integration events idempotently: runInboxTransaction variants and disposition completeness"
- `messaging-shibuya-processing` — `DocKind.Guide` — "Shibuya processing semantics every worker inherits: ack decisions, retries, batching, supervision, shutdown"
- `messaging-transport-selection` — `DocKind.Pattern` — "Choosing a transport: the pgmq vs Kafka vs kiroku-subscription matrix and rule of thumb"
- `messaging-pgmq-jobs` — `DocKind.BestPractice` — "Typed background jobs on keiro-pgmq: Job, JobOutcome, RetryPolicy, VT rules, queue-name pitfalls"
- `messaging-kiroku-subscriptions` — `DocKind.BestPractice` — "Consuming the event log through the shibuya-kiroku bridge: ack-coupled checkpoints, guardKirokuHandler, consumer groups"
- `messaging-gotchas` — `DocKind.Notes` — "Consolidated messaging gotcha catalogue across shibuya, pgmq, Kafka, kiroku, and keiro"

The shape of one entry, exactly matching the file's existing style:

```dhall
      , Schema.DocRef::{
        , key = "messaging-glossary"
        , kind = Schema.DocKind.Reference
        , audience = Schema.DocAudience.Module
        , description = Some
            "Shared messaging vocabulary: domain vs integration events, outbox, inbox, ack decisions, at-least-once plus idempotency"
        , location = Schema.DocLocation.LocalFile "messaging/glossary.md"
        }
```

Do not touch the `dependencies` list (EP-2's remit — see the Decision Log).

**ADR distillation.** Create `docs/adr/` and write
`docs/adr/0003-pgmq-vs-kafka-transport-selection.md` (the next free number when this plan
ran): context (two queue transports plus the event-log bridge;
twenty services must choose consistently), decision (the rule of thumb from
`transport-selection.md`), consequences (Kafka consumers accept Serial-only/no
attempt/no DLQ and bring their own producer; pgmq bounded by Postgres; case B is
roadmap), alternatives considered (Kafka-everywhere, pgmq-as-integration-transport
now). Then add the forward link from `transport-selection.md` to the ADR. Update this
plan's living sections and flip the EP-5 row in
`docs/masterplans/1-keiro-runtime-standards-docs-and-seihou-blueprints.md` to Complete.


## Concrete Steps

All commands run from the repository root,
`/Users/shinzui/Keikaku/bokuno/keiro-runtime-patterns`, unless stated otherwise.
Assumptions: `dhall` is on PATH (the repo is developed in a Nix environment); the source
repositories listed in Context and Orientation are present at the named absolute paths;
`rg` (ripgrep) or `grep -rn` is available.

1. Create the directory and the M1 docs, then commit:

```bash
mkdir -p messaging
# write messaging/glossary.md and messaging/README.md per Milestone 1
git add messaging/
git commit -m "docs(messaging): add messaging glossary and doc-area index stub"
```

2. Write `messaging/process-managers.md` per Milestone 2. Before committing, verify the
   load-bearing symbols against the keiro sources (every command must print at least one
   hit; a silent exit means the doc names a symbol that does not exist — fix the doc,
   not the grep):

```bash
grep -n "data ProcessManagerAction" /Users/shinzui/Keikaku/bokuno/keiro/keiro/src/Keiro/ProcessManager.hs
grep -n "deterministicCommandId ::" /Users/shinzui/Keikaku/bokuno/keiro/keiro/src/Keiro/ProcessManager.hs
grep -n "PMCommandAppended\|PMCommandDuplicate\|PMCommandFailed" /Users/shinzui/Keikaku/bokuno/keiro/keiro/src/Keiro/ProcessManager.hs
grep -n "PoisonHalt\|RejectedHalt\|transientRetryDelay" /Users/shinzui/Keikaku/bokuno/keiro/keiro/src/Keiro/ProcessManager.hs
grep -n "scheduleTimerTx\|claimDueTimer\|requeueStuckTimers\|deadLetterTimer" /Users/shinzui/Keikaku/bokuno/keiro/keiro/src/Keiro/Timer.hs
grep -n "pm:" /Users/shinzui/Keikaku/bokuno/keiro/docs/user/process-managers-and-timers.md | head -5
grep -n "MessageNotYetProjected" /Users/shinzui/Keikaku/bokuno/danwa/danwa-workers/src/Danwa/Integration/AddressedMessageWorker.hs
```

   Expected shape of output (line numbers may drift; the names must match):

```text
203:data ProcessManagerAction ci targetCi = ProcessManagerAction
415:deterministicCommandId :: Text -> Text -> EventId -> Int -> EventId
...
35:`pm:fulfillment-order-1` is in category `pm:fulfillment`, while
```

   Then commit:

```bash
git add messaging/process-managers.md
git commit -m "docs(messaging): add process manager and durable timer standard"
```

3. Write the three M3 docs, verify, commit:

```bash
grep -n "data IntegrationEvent" /Users/shinzui/Keikaku/bokuno/keiro/keiro-core/src/Keiro/Integration/Event.hs
grep -n "mintIntegrationEvent\|enqueueProducerEventTx\|enqueueIntegrationEventTx\|publishClaimedOutbox\|outboxMaintenancePass\|requeueStuckOutbox\|garbageCollectSent" /Users/shinzui/Keikaku/bokuno/keiro/keiro/src/Keiro/Outbox.hs
grep -n "runInboxTransaction" /Users/shinzui/Keikaku/bokuno/keiro/keiro/src/Keiro/Inbox.hs | head -8
grep -n "generateNamed" /Users/shinzui/Keikaku/bokuno/danwa/danwa-core/src/Danwa/Integration/AddressedMessage.hs
git add messaging/integration-events.md messaging/outbox.md messaging/inbox.md
git commit -m "docs(messaging): add integration event, outbox, and inbox standards"
```

4. Write the four M4 docs, verify, commit:

```bash
grep -n "AckOk\|AckRetry\|AckDeadLetter\|AckHalt" /Users/shinzui/Keikaku/bokuno/shibuya-project/shibuya/shibuya-core/src/Shibuya/Core/Ack.hs | head -6
grep -n "StrictInOrder\|PartitionedInOrder\|Unordered" /Users/shinzui/Keikaku/bokuno/shibuya-project/shibuya/shibuya-core/src/Shibuya/Policy.hs | head -4
grep -rn "Serial" /Users/shinzui/Keikaku/bokuno/shibuya-project/shibuya-kafka-adapter/src/Shibuya/Adapter/Kafka.hs | head -4
grep -n "data JobOutcome\|data RetryPolicy\|enqueueToGroup\|runJobWorkers\|runJobOnce" /Users/shinzui/Keikaku/bokuno/keiro/keiro-pgmq/src/Keiro/PGMQ/Job.hs
grep -n "guardKirokuHandler\|kirokuConsumerGroupProcessors" /Users/shinzui/Keikaku/bokuno/kiroku-project/kiroku/shibuya-kiroku-adapter/src/Shibuya/Adapter/Kiroku.hs | head -6
git add messaging/shibuya-processing.md messaging/transport-selection.md messaging/pgmq-jobs.md messaging/kiroku-subscriptions.md
git commit -m "docs(messaging): add transport standards (shibuya, selection matrix, pgmq jobs, kiroku bridge)"
```

5. Write `messaging/gotchas.md`, finalize `messaging/README.md`, append the eleven
   DocRefs to `mori.dhall`, run the full validation pass (next section), then commit:

```bash
git add messaging/gotchas.md messaging/README.md mori.dhall
git commit -m "docs(messaging): add gotcha catalogue, finalize index, register mori DocRefs"
```

6. ADR distillation and MasterPlan bookkeeping:

```bash
mkdir -p docs/adr
# write docs/adr/<N>-pgmq-vs-kafka-transport-selection.md per Milestone 5
# (<N> = next free ADR number at implementation time; sibling plans also seed docs/adr/)
# add the ADR link to messaging/transport-selection.md
# flip EP-5 to Complete in docs/masterplans/1-keiro-runtime-standards-docs-and-seihou-blueprints.md
# update this plan's Progress / Outcomes & Retrospective
git add docs/adr/ messaging/transport-selection.md docs/masterplans/ docs/plans/5-*.md
git commit -m "docs(adr): seed transport-selection ADR; close out EP-5 messaging standards"
```

If a step fails halfway (for example a grep-check exposes a wrong symbol name), fix the
document and re-run only that milestone's checks; nothing here is order-fragile beyond
"glossary before the docs that link to it".


## Validation and Acceptance

Acceptance is behavior a reviewer can observe, in four checks from the repository root.

1. The doc area is complete and indexed. `ls messaging/` lists exactly eleven files:
   `README.md`, `glossary.md`, `process-managers.md`, `integration-events.md`,
   `outbox.md`, `inbox.md`, `shibuya-processing.md`, `transport-selection.md`,
   `pgmq-jobs.md`, `kiroku-subscriptions.md`, `gotchas.md`. Every non-README file is
   linked from the README:

```bash
for f in messaging/*.md; do b=$(basename "$f"); [ "$b" = "README.md" ] && continue; \
  grep -q "$b" messaging/README.md || echo "MISSING FROM INDEX: $b"; done
```

   Expected output: nothing (silence is success).

2. The registry type-checks and points at real files:

```bash
dhall type --quiet --file mori.dhall && echo OK
grep -o 'LocalFile "messaging/[^"]*"' mori.dhall | cut -d'"' -f2 | \
  while read -r p; do [ -f "$p" ] || echo "DANGLING DOCREF: $p"; done
grep -c 'key = "messaging-' mori.dhall
```

   Expected output: `OK`, then nothing, then `11`. (The schema import is pinned with a
   sha256 and already cached locally by the existing `mori.dhall`, so the type-check
   works offline.)

3. Symbols match sources. Run every grep in Concrete Steps 2–4; each prints at least one
   hit. Additionally verify the two claims most likely to rot: the inbox export list
   still has exactly seven `runInboxTransaction*` exports (Concrete Steps 3's grep,
   lines 36–42 region), and the Kafka adapter module header still documents the
   Serial-only constraint (Concrete Steps 4's grep on `Kafka.hs`). If any source has
   moved on (keiro is an active 0.3.x train), update the affected doc and record the
   drift in Surprises & Discoveries.

4. Style and boundary conformance, by reading: each doc has H1 + bold tagline + scope
   paragraph + Related Patterns trailer and no YAML frontmatter; no messaging doc
   defines validated event stream, the two-schema arrangement, snapshot semantics, or
   `CommandAmbiguous` (they link `../keiro/README.md`); no messaging doc legislates
   module placement (EP-6's remit); the decision ladder, the adapter matrix, and the
   rule of thumb appear verbatim where this plan specifies them.

The change is documentation, so "working" means discoverable and true: after step 2
passes, `mori registry show shinzui/keiro-runtime-patterns --full` (run anywhere) lists
the eleven messaging docs alongside the keiki ones — that is the end-user-visible
effect this plan exists to produce.


## Idempotence and Recovery

Every step is safe to repeat. Writing a doc file again overwrites it with the same
content; the grep-checks are read-only; `dhall type` is read-only. The only edit to a
shared file is the `mori.dhall` append — it touches only the end of the `docs` list and
never reorders existing entries, so re-applying it is a no-op and a conflict with a
sibling plan's block (EP-1/EP-2/EP-4 own other keys) resolves by keeping both blocks in
any order (Dhall list order is not semantically load-bearing here, per MasterPlan
Integration Point 1). If `dhall type` fails after the append, the error names the line;
the recovery path is to diff against the entry template in Milestone 5 — the common
mistakes are a missing comma before `Schema.DocRef::{` or an unclosed string. If a
commit lands with a failing check, fix forward with a follow-up `docs(messaging): fix
...` commit; nothing here needs rollback machinery. The ADR step creates a new directory
and file; allocate the next free integer and update the transport-selection doc's single
relative link in the same commit.


## Interfaces and Dependencies

This plan produces Markdown and Dhall only — no Haskell is compiled. The interfaces that
matter are (a) the documented API surfaces, which must exist verbatim in the sources at
the versions named, and (b) the registry schema.

Documented API surfaces (the contract each doc is checked against): from `keiro` 0.3.0.0
— `Keiro.ProcessManager` (`ProcessManager(..)`, `ProcessManagerAction(..)`,
`PMCommand(..)`, `PMCommandResult(..)`, `PMStateResult(..)`, `WorkerOptions(..)`,
`PoisonPolicy(..)`, `RejectedCommandPolicy(..)`, `defaultWorkerOptions`,
`deterministicCommandId`, `eventAlreadyIn`, `confirmBenignDuplicate`,
`runProcessManagerOnce`, `runProcessManagerWorker`, `runProcessManagerWorkerWith`),
`Keiro.Timer` (`TimerRequest(..)`, `TimerWorkerOptions(..)`, `scheduleTimerTx`,
`claimDueTimer`, `markTimerFired`, `runTimerWorker`, `requeueStuckTimers`,
`cancelTimer`, `deadLetterTimer`), `Keiro.Integration.Event` (`IntegrationEvent(..)`,
`encodeJsonIntegrationEvent`, `decodeJsonIntegrationEvent`, `integrationHeaders`),
`Keiro.Outbox` (`IntegrationProducer(..)`, `mkIntegrationProducer`,
`mintIntegrationEvent`, `enqueueProducerEventTx`, `enqueueIntegrationEventTx`,
`freshOutboxId`, `publishClaimedOutbox`, `outboxMaintenancePass`, `claimOutboxBatch`,
`markOutboxSent`, `requeueStuckOutbox`, `garbageCollectSent`, `countOutboxBacklog`),
`Keiro.Outbox.Kafka` (`outboxRowToKafkaRecord`, `integrationEventToKafkaRecord`),
`Keiro.Inbox` (the seven `runInboxTransaction*` exports, `markFailedTx`, `lookupInbox`,
`countInboxBacklog`, `garbageCollectCompleted`). From `keiro-pgmq` 0.3.0.0 —
`Keiro.PGMQ.Job` (`Job(..)`, `JobOutcome(..)`, `RetryPolicy(..)`, `mkRetryPolicy`,
`enqueueToGroup`, `jobProcessor`, `runJobWorkers`, `runJobOnce`) and
`Keiro.PGMQ.Runtime` (`QueueRef`, `withJobRuntime`). From `shibuya-core` 0.8.0.1 —
`Shibuya.Core.Ack` (`AckDecision(..)`, `DeadLetterReason(..)`, `HaltReason(..)`),
`Shibuya.Handler` (`Handler`), `Shibuya.Policy` (`OrderingPolicy(..)`,
`Concurrency(..)`, `validatePolicy`), `Shibuya.App` (`runApp`, `AppConfig(..)`,
`SupervisionStrategy(..)`, `stopAppGracefully`), `Shibuya.Batch` (`BatchHandler`,
`BatchAck(..)`, `ackAllOk`, `ackExcept`). From `shibuya-pgmq-adapter` 0.12.0.0 —
`pgmqAdapter`, `PgmqAdapterConfig` (visibilityTimeout, maxRetries, deadLetterConfig,
fifoConfig, prefetchConfig). From `shibuya-kafka-adapter` 0.8.0.1 — `kafkaAdapter` and
the module-header constraints. From `shibuya-kiroku-adapter` 0.4.0.0 (in the kiroku
repo) — `kirokuAdapter`, `KirokuAdapterConfig`, `guardKirokuHandler`,
`kirokuConsumerGroupProcessors`. From `pgmq-hs` 0.4.x — the `Pgmq` effect,
`PgmqRuntimeError`, `isTransient`, `ensureQueuesEff`.

Registry schema: `mori.dhall` imports mori-schema at commit `026ae743...` (sha256
pinned in the file); the DocRef constructor fields used are `key`, `kind`, `audience`,
`description`, `location`, with `DocKind.{Guide,Reference,BestPractice,Pattern,Notes}`,
`DocAudience.Module`, `DocLocation.LocalFile`. No schema upgrade is needed or performed
by this plan.

Sibling-plan interfaces: forward links target `../keiro/README.md` (EP-4's index; see
Decision Log) and are consumed by EP-6 (which cites `messaging/` for worker/integration
behavior) and EP-9 (whose blueprints cite the DocRef keys). This plan reads, but never
edits, anything outside this repository.


## Revision Notes

- 2026-07-22 (implementation completion): added the eleven messaging standards and
  DocRefs, refreshed Mori, and recorded transport selection in ADR 0003. Corrected the
  original draft wherever released source showed narrower behavior: split
  process-manager transactions and caller-owned timer ids, caller-owned producer
  checkpoint/idempotency wiring, separate outbox retention, transactional supervised
  PGMQ DLQ transfer versus non-atomic one-shot drains, and Shibuya 0.8.0.1's
  always-finalize handler-exception path. Reason: the pattern corpus must describe the
  verified release cohort rather than stronger guarantees or stale module prose.
