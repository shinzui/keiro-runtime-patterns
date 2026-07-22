---
id: 2
slug: document-kiroku-event-store-and-pg-migrate-standards
title: "Document kiroku event store and pg-migrate standards"
kind: exec-plan
created_at: 2026-07-22T14:55:29Z
master_plan: "docs/masterplans/1-keiro-runtime-standards-docs-and-seihou-blueprints.md"
---

# Document kiroku event store and pg-migrate standards

This ExecPlan is a living document. The sections Progress, Surprises & Discoveries,
Decision Log, and Outcomes & Retrospective must be kept up to date as work proceeds.
If durable project context changes, update or create ADRs in docs/adr/ in the same change.


## Purpose / Big Picture

Every service on the keiro runtime persists its events to kiroku (a PostgreSQL event store) and manages its database schema with pg-migrate (a compile-time migration engine). About ten new microservices are about to be written on this stack and another ten refactored onto it, but this repository — the fleet's terse, agent-facing pattern corpus — currently documents only keiki (the transducer library). Nothing here tells a developer or a coding agent how to append events correctly, why one transaction combinator is the fleet standard and the others are traps, how to wire observability, or how a service should package its migrations.

After this plan is implemented, this repository contains two new documentation areas: `kiroku/` (eight documents covering append/read patterns, transactions, connection settings, subscriptions, operational invariants, observability, and lifecycle/deletion) and `migrations/` (seven documents covering the pg-migrate model, authoring rules, the service migrations-package pattern, operations, testing, and the codd-to-pg-migrate transition). All fifteen documents are registered in `mori.dhall` so tooling can discover them, and `shinzui/pg-migrate` and `shinzui/pgmq-hs` are added to the project's dependency list.

You can see it working like this: from the repository root, `mori validate` prints `Configuration is valid.`, `dhall --file mori.dhall` type-checks, every document is reachable by following links from `kiroku/README.md` and `migrations/README.md`, and every Haskell symbol the docs name can be found by grep in the source file the plan cites — proving the docs describe the real API, not a remembered one.


## Progress

Update this checklist at every stopping point. Split partially completed items into "done" and "remaining" parts rather than leaving them ambiguous.

- [ ] Milestone 1: `kiroku/append-and-read.md` written
- [ ] Milestone 1: `kiroku/transactions-and-projections.md` written
- [ ] Milestone 1: `kiroku/connection-settings.md` written
- [ ] Milestone 1: `kiroku/subscriptions.md` written
- [ ] Milestone 1: `kiroku/operational-invariants.md` written (all ten invariants)
- [ ] Milestone 1: `kiroku/observability.md` written
- [ ] Milestone 1: `kiroku/lifecycle-and-deletion.md` written
- [ ] Milestone 1: `kiroku/README.md` index written; every kiroku doc linked
- [ ] Milestone 2: `migrations/pg-migrate-model.md` written
- [ ] Milestone 2: `migrations/authoring.md` written
- [ ] Milestone 2: `migrations/service-package.md` written
- [ ] Milestone 2: `migrations/operations.md` written
- [ ] Milestone 2: `migrations/testing.md` written
- [ ] Milestone 2: `migrations/codd-transition.md` written
- [ ] Milestone 2: `migrations/README.md` index written; every migrations doc linked
- [ ] Milestone 3: fifteen DocRef entries appended to `mori.dhall`
- [ ] Milestone 3: `shinzui/pg-migrate` and `shinzui/pgmq-hs` appended to the `dependencies` list
- [ ] Milestone 3: symbol cross-check script runs with zero `MISS` lines
- [ ] Milestone 3: `dhall --file mori.dhall` type-checks and `mori validate` prints `Configuration is valid.`
- [ ] Milestone 3: link check over both README indexes reports no broken links
- [ ] Completion: ADR distillation pass performed (create `docs/adr/` and seed records only if durable decisions emerged)


## Surprises & Discoveries

Document unexpected behaviors, bugs, optimizations, or insights discovered during implementation. Provide concise evidence.

- During plan authoring (2026-07-22), every load-bearing symbol named in this plan was verified by grep against the kiroku and pg-migrate working trees: `runTransactionAppendingResource` and `enrichEventsIO` in `kiroku-store/src/Kiroku/Store/Transaction.hs`, `extraSearchPath`/`statementTimeout` in `Connection.hs`, `WrongExpectedVersion` constructed with `StreamVersion 0` in `Error.hs` (line 274 as of kiroku-store 0.3.0.1), `withSubscription` in `Subscription.hs`, `subscriptionTraceHandler :: Tracer -> IO (KirokuEvent -> IO ())` in kiroku-otel, `readinessMaxLag` default `10_000` in kiroku-metrics, `kirokuMigrationPlan :: Either PlanError MigrationPlan` in kiroku-store-migrations, `withMigratedDatabase` in pg-migrate-test-support, and the directive string `pg-migrate: no-transaction` in `pg-migrate/src/Database/PostgreSQL/Migrate/Sql/Scanner.hs` (line 103 as of pg-migrate 1.1.0.0).
- The pg-migrate basic example lives at the repository root, `/Users/shinzui/Keikaku/bokuno/pg-migrate/examples/basic/app/Main.hs`, not under the `pg-migrate/` package subdirectory as an earlier research note implied. The plan below cites the corrected path.
- (Implementation discoveries go here.)


## Decision Log

Record every decision made while working on the plan.

- Decision: The kiroku area is eight files (`README.md`, `append-and-read.md`, `transactions-and-projections.md`, `connection-settings.md`, `subscriptions.md`, `operational-invariants.md`, `observability.md`, `lifecycle-and-deletion.md`) and the migrations area is seven (`README.md`, `pg-migrate-model.md`, `authoring.md`, `service-package.md`, `operations.md`, `testing.md`, `codd-transition.md`).
  Rationale: one document per decision surface a service author actually faces, mirroring the granularity of the existing `keiki/` area; file slugs are chosen so DocRef keys (`<directory>-<file-slug>`) stay short and non-redundant (e.g. `migrations-authoring`, not `migrations-authoring-migrations`).
  Date: 2026-07-22

- Decision: DocRef kinds are limited to `BestPractice` (rule documents), `Guide` (indexes and explainers), and `Runbook` (`kiroku-operational-invariants`, `migrations-operations`); audience is `Module` for all fifteen.
  Rationale: matches the MasterPlan's instruction ("kinds BestPractice/Guide/Runbook as fitting, audience Module") and the existing `keiki-*` usage where module-facing pattern docs carry audience `Module`.
  Date: 2026-07-22

- Decision: `kiroku/subscriptions.md` includes the shibuya-kiroku-adapter facts that are inseparable from the consumer-group standard (Serial pinning, `guardKirokuHandler`), but the full shibuya/messaging story stays out of scope.
  Rationale: consumer groups cannot be documented honestly without naming the adapter that enforces their concurrency policy, but EP-5 (`docs/plans/5-document-process-managers-integration-events-and-messaging-standards.md`) owns the messaging transports; duplicating them here would create drift.
  Date: 2026-07-22

- Decision: forward references to documentation other plans will create (the `keiro/` and `messaging/` areas) are plain prose mentions, never relative Markdown links.
  Rationale: this plan's link check requires every relative link to resolve; dead links would fail acceptance and confuse readers until the other plans land.
  Date: 2026-07-22

- Decision: `migrations/codd-transition.md` is a short explainer with pointers, not a migration runbook.
  Rationale: the `cohort-migrate` agent skill already automates the persistent-database remediation with data-loss proofs on a restored clone; the doc's job is to explain why the transition happened and where the authoritative procedure lives, not to duplicate it.
  Date: 2026-07-22

- Decision: follow the documentation style contract from the MasterPlan (Integration Point 2) directly, using the existing `keiki/` files as the shape reference.
  Rationale: EP-1 (the keiki rewrite) may run in parallel with this plan; the contract is fully specified in the MasterPlan and restated in this plan's Context section, so there is nothing to wait for.
  Date: 2026-07-22


## Outcomes & Retrospective

Summarize outcomes, gaps, and lessons learned at major milestones or at completion. Compare the result against the original purpose. Before marking the plan complete, distill durable project context from the Decision Log, Surprises & Discoveries, and this section into `docs/adr/`. Keep task-local execution details here.

(To be filled during and after implementation.)


## Context and Orientation

This repository, `/Users/shinzui/Keikaku/bokuno/keiro-runtime-patterns`, is a documentation-only repository: the terse, prescriptive, agent-facing pattern corpus for the keiro runtime (a Haskell event-sourcing microservice stack). It currently contains one documentation area, `keiki/` (eight Markdown files about the keiki transducer library), a `mori.dhall` project descriptor registering seven of those files, and planning documents under `docs/masterplans/` and `docs/plans/`. There is no Haskell code here and nothing to compile; "implementing" this plan means writing Markdown files and editing one Dhall file.

`docs/adr/` does not exist in this repository yet. There are no Architecture Decision Records to consult — the parent MasterPlan (`docs/masterplans/1-keiro-runtime-standards-docs-and-seihou-blueprints.md`, checked in) records the same fact. If implementation surfaces durable project decisions, the completion-time distillation pass creates `docs/adr/` and seeds the first records; otherwise state in Outcomes & Retrospective that none were needed.

This plan is EP-2 of that MasterPlan. The MasterPlan's Integration Points assign this plan exclusive ownership of the `kiroku/` and `migrations/` directories and of its own `mori.dhall` additions. Two of its rules are restated here so this plan stands alone. First, the registration rule: new `Schema.DocRef` entries use keys of the form `<directory>-<file-slug>` (matching the existing `keiki-*` keys), are appended after the existing entries without reordering them, and this plan additionally appends `shinzui/pg-migrate` and `shinzui/pgmq-hs` to the `dependencies` list. Second, the style contract every new document must follow: no YAML frontmatter; a single `#` H1 title; immediately below it a bold one-line tagline; then a one-paragraph scope statement; prescriptive, rule-first prose (state the rule, then justify it); code samples in language-tagged fences, using `-- CORRECT` / `-- WRONG` (or `-- Before` / `-- After`) contrast pairs where a contrast clarifies; relative Markdown links between docs in the same repository; and a trailing `## Related Patterns` section. The existing `keiki/README.md` and `keiki/transducer-best-practices.md` show the realized shape — skim them before writing.

The two source-of-truth codebases this plan documents:

*Kiroku* lives at `/Users/shinzui/Keikaku/bokuno/kiroku-project/kiroku` (GHC 9.12.4, a Cabal multi-package workspace). "Event store" means an append-only database of immutable events organized into named streams; services derive all state by replaying events. The packages and versions as of 2026-07-22: `kiroku-store` 0.3.0.1 (the store client — types, append/read, subscriptions, transactions), `kiroku-store-migrations` 0.3.0.0 (the store's own schema migrations as a pg-migrate component), `kiroku-otel` 0.2.0.1 (OpenTelemetry integration), `kiroku-metrics` 0.1.0.1 (metrics collector plus HTTP/Prometheus/health server), and `shibuya-kiroku-adapter` 0.4.0.0 (bridges kiroku subscriptions into shibuya queue processors). Relevant module files, all under that root: `kiroku-store/src/Kiroku/Store/Types.hs`, `Effect.hs`, `Append.hs`, `Read.hs`, `Transaction.hs`, `Settings.hs`, `Connection.hs`, `Subscription.hs`, `Subscription/Types.hs`, `Subscription/Fsm.hs`, `Lifecycle.hs`, `Link.hs`, `Error.hs`, `Observability.hs`; `kiroku-store-migrations/src/Kiroku/Store/Migrations.hs` and `Migrations/History/Codd.hs`; `kiroku-otel/src/Kiroku/Otel/TraceContext.hs` and `Otel/Subscription.hs`; `kiroku-metrics/src/Kiroku/Metrics/{Collector,Config,Health,Prometheus,Server}.hs`; `shibuya-kiroku-adapter/src/Shibuya/Adapter/Kiroku.hs`. The kiroku repo also carries its own user docs under `docs/user/` and ADRs under `docs/adr/` (notably `0003-dedicated-kiroku-schema.md`) — useful corroboration, but this plan's documents must stand alone.

*pg-migrate* lives at `/Users/shinzui/Keikaku/bokuno/pg-migrate`, version 1.1.0.0. It is a Hasql-native PostgreSQL migration engine in which applications own an explicit, compile-time migration plan: libraries export ordered "components" of SQL migrations, applications compose components into a plan and mount a reusable CLI. It is forward-only (no down migrations), targets PostgreSQL 17 and 18 only, and records what it applied in a "ledger" (bookkeeping tables in a `pgmigrate` schema). Six packages: `pg-migrate` (facade `Database.PostgreSQL.Migrate`), `pg-migrate-embed`, `pg-migrate-cli` (a library, not a binary), `pg-migrate-import-codd`, `pg-migrate-import-hasql-migration`, `pg-migrate-test-support`. Key files: `pg-migrate/src/Database/PostgreSQL/Migrate.hs`, `pg-migrate/src/Database/PostgreSQL/Migrate/Sql/Scanner.hs`, `pg-migrate-cli/src/Database/PostgreSQL/Migrate/CLI.hs`, `pg-migrate-test-support/src/Database/PostgreSQL/Migrate/Test.hs`, `docs/user/quickstart.md`, `docs/reference/ledger-v1.md`, and the worked example `examples/basic/` (its `app/Main.hs` plus `migrations/accounts/` and `migrations/billing/`).

Terms used throughout this plan: a *stream* is a named, ordered sequence of events (e.g. `order-123`); *optimistic concurrency* means an append states what stream version it expects and fails if another writer got there first; a *subscription* is a background consumer that receives events in order and records a *checkpoint* (the last position it processed) so it can resume; a *consumer group* is N cooperating subscription members that partition streams among themselves; a *projection* (or *read model*) is a queryable table derived from events; a *migration component* is a named, ordered list of SQL migrations a library exports; the *ledger* is pg-migrate's durable record of which migrations ran; *mori* is the local project registry CLI whose per-repo descriptor is `mori.dhall`, and a *DocRef* is one document-registration entry in it.

The facts each new document must assert are embedded in the Plan of Work below, and each document's section names the exact source files to verify against. Line numbers cited are as of the versions above — treat them as hints and re-grep rather than trusting them. If a fact in this plan and the source disagree, the source wins; record the discrepancy in Surprises & Discoveries.


## Plan of Work

The work is three milestones: write the `kiroku/` area, write the `migrations/` area, then register everything in `mori.dhall` and validate. Milestones 1 and 2 are independent of each other; milestone 3 depends on both. Every document follows the style contract restated in Context and Orientation. As a concrete shape reference, each document opens like this:

```markdown
# Kiroku Append and Read Patterns

**Choose the strictest `ExpectedVersion` you can, supply your own event ids for
retries, and never trust the version inside `WrongExpectedVersion`.**

Use this guide when writing any code that appends to or reads from a kiroku
stream in a keiro service. It covers optimistic-concurrency semantics,
idempotent retries, and constant-memory reads.
```

and closes with a `## Related Patterns` section of relative links to sibling docs.


### Milestone 1: the kiroku/ documentation area

Scope: create the directory `kiroku/` at the repository root with eight Markdown files. At the end of this milestone a developer can read a complete, prescriptive standard for using the kiroku event store, and every claim in it can be located in the kiroku sources. Acceptance: all eight files exist, each follows the style contract, `kiroku/README.md` links to the other seven, and the kiroku rows of the symbol cross-check in Concrete Steps pass.

Create `kiroku/append-and-read.md` (kind BestPractice). It must state: appends declare an `ExpectedVersion` — `NoStream` (stream must not exist), `StreamExists` (must exist, any version), `ExactVersion` (must be exactly this version), `AnyVersion` (no check) — and the standard is to use the strictest form the caller can honestly assert, because that is what turns concurrent writes into detectable conflicts (`kiroku-store/src/Kiroku/Store/Types.hs`, around lines 108–135). Stream versions are per-stream and 1-based; `StreamVersion 0` means "empty/absent". For idempotent retries, `EventData.eventId :: Maybe EventId` is the key: `Nothing` lets the store mint a UUIDv7, `Just` makes the append retry-safe — if the first attempt actually committed, the retry surfaces as `DuplicateEvent`, which the caller treats as success. The store itself auto-retries serialization failures (SQLSTATE `40001`/`40P01`) exactly once, safe only because event ids are pre-generated. The `WrongExpectedVersion` gotcha gets its own `-- WRONG` / `-- CORRECT` pair: the error's third field is always `StreamVersion 0` because the store does not re-read on conflict (`kiroku-store/src/Kiroku/Store/Error.hs`, constructor near line 61, constructed with `StreamVersion 0` near line 274) — recover by re-reading the stream (`getStream`), never by "using" the version in the error. For reads: all cursors are exclusive; use `readStreamForward` for bounded reads and `readStreamForwardStream` — the constant-memory Streamly pager, recommended page size 256 (`Read.hs`, around line 66) — for unbounded ones; `GlobalPosition` (the `$all`-stream cursor, where `$all` is the store-wide stream containing every event) is opaque: strictly-increasing and totally-ordered is the only contract, never assume contiguity; `eventExistsInStream` is the cheap idempotency point-lookup; `lookupStreamNames` is the supported way to resolve a `RecordedEvent`'s `originalStreamId` to a name.

Create `kiroku/transactions-and-projections.md` (kind BestPractice). It documents the combinators in `kiroku-store/src/Kiroku/Store/Transaction.hs`: `runTransaction`/`runTransactionNoRetry`, `appendToStreamTx` (returns `Either AppendConflict AppendResult`), `runTransactionAppending`/`...NoRetry`, `runTransactionAppendingResource`/`...NoRetry` (near lines 293 and 310), and `enrichEventsIO` (near line 333). The headline rule: **`runTransactionAppendingResource` is the fleet standard** for atomically appending events and updating a projection in the same database transaction. Two reasons, both of which the doc must spell out. First, it is the hook-aware variant: it applies the store's `enrichEvent` hook (`kiroku-store/src/Kiroku/Store/Settings.hs`, field near line 68) to every event before encoding — the hook is where OpenTelemetry trace context is injected — whereas bare `appendToStreamTx` and the non-Resource `runTransactionAppending*` bypass the hook entirely; anyone who must use those calls `enrichEventsIO` manually first. Second, the append updates the global `$all` bookkeeping row and holds that row lock until commit, so the continuation runs while every other appender in the fleet is blocked — keep continuations minimal: project into read-model tables and return; no HTTP calls, no slow computation. Also state the retry rule: `runTransaction*` re-runs the whole body on serialization conflict, so use the `NoRetry` variants whenever the body has externally observable effects.

Create `kiroku/connection-settings.md` (kind BestPractice). It documents `ConnectionSettingsM` and `defaultConnectionSettings` (`kiroku-store/src/Kiroku/Store/Connection.hs`, record around lines 37–121, defaults around 127–139) and prescribes the fleet settings. The rules: `schema` defaults to `"kiroku"` and **stays `"kiroku"`** fleet-wide — the setting is authoritative for both table resolution and the LISTEN/NOTIFY channel (every pooled connection runs `SET search_path TO "<schema>", pg_catalog`, and the notifier listens on `<schema>.events`), so moving the schema silently moves the notification channel with it. `extraSearchPath` (default `[]`) is the deliberate seam that makes keiro's tables reachable on the store pool: keiro's framework tables live in a dedicated `keiro` schema, and a keiro service sets `extraSearchPath` to include it (entries are appended after `schema` and before `pg_catalog`). `poolSize` defaults to 10; `idleInTransactionTimeout` defaults to 30 seconds; `statementTimeout` defaults to `Nothing` and the fleet recommendation is `Just 30`. The synchronous-handler discipline: `eventHandler` and `observationHandler` run synchronously on the store's internal emit-site threads, so slow callbacks stall append/subscription loops — keep them fast or hand off to a queue. Finally: `withStore` runs no DDL; migrations must have been applied before the store is opened.

Create `kiroku/subscriptions.md` (kind BestPractice). Its rules, in order: subscriptions are **at-least-once** with **per-batch checkpoints**, therefore every handler must be **idempotent** — after a crash the whole last batch redelivers (Haddock at `kiroku-store/src/Kiroku/Store/Subscription.hs` lines 59–110). Always use `withSubscription` (near line 213) rather than bare `subscribe`, which leaks the worker thread if the caller forgets to cancel. A handler returns a `SubscriptionResult`: `Continue`, `Stop`, `Retry` (redeliver after a delay), or `DeadLetter`; the default retry policy allows 5 total deliveries before the event is recorded in the `dead_letters` table. Overflow policies (`Subscription/Types.hs`): `PauseAndResume` (default), `DropSubscription`, `DropOldest` — and the trap the doc must flag: `queueCapacity` and `overflowPolicy` only apply to non-group `AllStreams` subscriptions; `Category` and consumer-group subscriptions are database-driven and ignore them, and `PauseAndResume` is lossless only in the non-group `AllStreams` case. Consumer groups (`ConsumerGroup { member, size }`): members statically partition streams by hash (`hashtextextended(stream_id::text, 0) % size` in SQL), each member checkpoints under `(subscriptionName, member)`, and the standard way to run them is `kirokuConsumerGroupProcessors` from `shibuya-kiroku-adapter/src/Shibuya/Adapter/Kiroku.hs`, which pins every member to `(PartitionedInOrder, Serial)` — member concurrency is Serial by policy, one adapter per process with a distinct member — and wraps handlers in `guardKirokuHandler` so an escaping exception becomes `AckRetry` instead of an unfinalized ack that blocks the worker forever. The alerting rule from the subscription state machine (`Subscription/Fsm.hs`): a stopped or crashed subscription is represented by **absence** from `subscriptionStates` — `Stopped` is never written into the observable cell — so monitoring must treat a missing key as terminal and read the stop reason from the `KirokuEvent` log, never wait for a "stopped" status. Note in prose (no link) that transport selection and the wider messaging standards are covered by the forthcoming messaging documentation area.

Create `kiroku/operational-invariants.md` (kind Runbook). This is the one-page list of the ten invariants every kiroku-backed service must respect in production; a numbered list is appropriate here because the whole point is scannable completeness. The ten, each with a one-sentence consequence: (1) migrate before opening the store — `withStore` runs no DDL; (2) `schema` is authoritative for tables and the NOTIFY channel, default `kiroku`, and the runtime role needs privileges on it; (3) per-connection `search_path` is `<schema>` plus `extraSearchPath` plus `pg_catalog` — projection tables in other schemas are unreachable unless listed; (4) pool 10, idle-in-transaction timeout 30 s, statement timeout off by default — set `Just 30`; (5) optimistic concurrency is per-stream via `ExpectedVersion`; `WrongExpectedVersion`'s version field is always 0, re-read to recover; supply your own `eventId` for retries and treat `DuplicateEvent` as success; (6) retry topology — appends auto-retry serialization conflicts exactly once, `runTransaction*` retries the whole body (use `NoRetry` when intermediate state is observable), subscriptions allow 5 total deliveries then dead-letter, notifier/publisher reconnect with 1 s → 30 s capped backoff plus a 30 s safety poll; (7) subscriptions are at-least-once with per-batch checkpoints and idempotent handlers; overflow settings apply only to non-group `AllStreams`; prefer `withSubscription`; (8) handlers and hooks run synchronously on internal threads — keep them fast or fan out; (9) `$all` positions are opaque — never assume density; (10) the hard-delete GUC is advisory, not security — run the application role without DELETE and record an application event before hard-deleting. Cross-link each invariant to the sibling doc that explains it.

Create `kiroku/observability.md` (kind Guide). It is a wiring walkthrough with one non-negotiable ordering rule: **compose the metrics callbacks into the connection settings before opening the store**, because handlers are captured at `withStore` time. Concretely: create the collector with `newKirokuMetrics`, then set `eventHandler = Just (metricsEventHandler km passthrough)` and `observationHandler = Just (metricsObservationHandler km passthrough)` (`kiroku-metrics/src/Kiroku/Metrics/Collector.hs`, near lines 144 and 152; both compose with an optional passthrough callback). Tracing: kiroku-otel's `subscriptionTraceHandler :: Tracer -> IO (KirokuEvent -> IO ())` (`kiroku-otel/src/Kiroku/Otel/Subscription.hs`, near line 177) chains in as that passthrough and turns subscription lifecycle events into spans (`kiroku.subscription.catchup`, `.deliver`, `.dead_letter`, etc.); because it runs synchronously on worker threads, **a batch span processor is required** — a simple/synchronous processor would stall the store. Trace-context propagation into events goes through the enrich hook: `storeSettings.enrichEvent = Just (injectTraceContext <currentSpanContext>)` using `injectTraceContext :: SpanContext -> EventData -> EventData` (`kiroku-otel/src/Kiroku/Otel/TraceContext.hs`, near line 49), which writes W3C `traceparent`/`tracestate` into event metadata; the shibuya adapter lifts `metadata.traceparent` into the envelope's trace context automatically on the consume side. Serving: `Kiroku.Metrics.Server` (default port 9091) exposes `GET /metrics` (JSON), `/metrics/prometheus`, `/subscriptions`, `/health`, `/health/live`, `/health/ready`, and WebSocket endpoints; the Prometheus names are a stable contract — `kiroku_events_appended_total`, `kiroku_active_subscribers`, `kiroku_pool_connections{state=...}` (`kiroku-metrics/src/Kiroku/Metrics/Prometheus.hs`). Kubernetes wiring: point liveness at `/health/live` and readiness at `/health/ready`; readiness fails when a subscription stopped from overflow or lags beyond `readinessMaxLag` (default `10_000`, `kiroku-metrics/src/Kiroku/Metrics/Config.hs`); wire `postgresPing` into the health config; and note that the reported `lag` is an upper bound sampled at lifecycle callbacks, not a live gauge.

Create `kiroku/lifecycle-and-deletion.md` (kind Guide). Its content, from `kiroku-store/src/Kiroku/Store/Lifecycle.hs` and `Link.hs`: `softDeleteStream` hides a stream but its events survive in `$all`; `hardDeleteStream` physically removes them (hard-deleted events vanish from `$all` too) and works by setting `SET LOCAL kiroku.enable_hard_deletes='on'` before deleting — and that GUC (a Postgres per-session configuration variable guarding the delete triggers) is **advisory, not a security boundary**: any role with DELETE privilege can set it, so the real control is running the application role without DELETE. The fleet standard for erasure: **append an application-level event recording the erasure decision first** (who/why/when), then hard-delete, so the audit trail survives the data's removal. `setStreamTruncateBefore` is close-the-book compaction: stream reads start at the truncation point, but it does **not** affect `$all`, category reads, or subscriptions — it is not a purge and must not be sold as one; `clearStreamTruncateBefore` undoes it. Finally: `linkToStream` (`Link.hs`) is a provisional API with zero keiro usage that may be removed — **do not** build fleet patterns on it.

Create `kiroku/README.md` last (kind Guide): the index, shaped like `keiki/README.md` — a "start here" pointer to `operational-invariants.md` and `append-and-read.md`, then a linked one-to-two-line summary of every other document in the directory.


### Milestone 2: the migrations/ documentation area

Scope: create the directory `migrations/` at the repository root with seven Markdown files covering pg-migrate standards. Acceptance mirrors milestone 1: files exist, style contract followed, `migrations/README.md` links to the other six, and the pg-migrate rows of the symbol cross-check pass.

Create `migrations/pg-migrate-model.md` (kind Guide). It explains the model a novice needs before the rule docs make sense: pg-migrate (1.1.0.0) is a Hasql-native migration engine where applications own an explicit **compile-time** migration plan; libraries export `MigrationComponent`s (stable name, ordered non-empty migration list, a `Set` of component-name dependencies) and the application composes them with `migrationPlan` (validates the declared order) or `resolveMigrationPlan` (topologically sorts). Migrations are SQL files listed in a plain-text file literally named `manifest`, one filename per line in apply order; `0001-create-accounts.sql` in component `accounts` has the durable identity `accounts/0001-create-accounts`, stable even if the file is later renamed. `embedMigrationManifest` (from `pg-migrate-embed`) embeds the **exact SQL bytes** at compile time via Template Haskell, and on GHC 9.12 every embedding module must load the recompile plugin — show the pragma `{-# OPTIONS_GHC -fplugin=Database.PostgreSQL.Migrate.Embed.RecompilePlugin #-}` exactly as it appears at the top of `/Users/shinzui/Keikaku/bokuno/pg-migrate/examples/basic/app/Main.hs`. Applying (`up`) takes one session-level advisory lock for the whole plan, applies pending migrations in order, and commits transactional SQL atomically with its ledger row; re-running is idempotent (`AlreadyApplied`). The ledger (schema `pgmigrate`, spec in `/Users/shinzui/Keikaku/bokuno/pg-migrate/docs/reference/ledger-v1.md`) keys rows by `(component, migration)` with SHA-256 checksums and append-only repairs. Close with the codd contrast (codd keyed applied migrations by filename alone — renames re-ran, edits went unnoticed, nothing was checksummed) and the hard constraints: forward-only, PostgreSQL 17/18 only, one `DATABASE_URL`.

Create `migrations/authoring.md` (kind BestPractice). Three rule clusters. Append-only: **never edit an applied migration** — the SHA-256 changes and `verify` fails loudly; ship a new numbered migration instead. The no-transaction directive: a migration is transactional by default; the comment directive `-- pg-migrate: no-transaction` (scanner at `/Users/shinzui/Keikaku/bokuno/pg-migrate/pg-migrate/src/Database/PostgreSQL/Migrate/Sql/Scanner.hs`) marks it nontransactional, and then the file must contain **exactly one statement**; misplaced or duplicated directives are rejected, and legacy `-- codd: in-txn` comments are inert. Manifest v1 strictness: the manifest rejects comments, blank lines, BOMs, and any `.sql` sibling not listed (`UnlistedSqlFiles`); automatic numbering width is enforced; use the `new` CLI command to scaffold correctly named files (`NNNN-slug.sql`).

Create `migrations/service-package.md` (kind BestPractice). This is the fleet pattern: every service ships a `<service>-migrations` package exporting one `MigrationComponent` named `"<service>"` whose dependency set is `Set.singleton "keiro"`, plus a plan that composes kiroku + keiro (+ pgmq, when the service uses queues) + the service component in dependency order, and one `<service>-migrate` binary that mounts the reusable CLI over that plan. The resulting database carries schemas `kiroku`, `keiro`, `pgmq` (if used), and `<service>`, all governed by a single ledger. Cite both pieces of evidence with paths so the reader can imitate real code: kiroku's own component, `kirokuMigrations = migrationComponentFromEmbeddedSql "kiroku" mempty ...` and `kirokuMigrationPlan :: Either PlanError MigrationPlan` in `/Users/shinzui/Keikaku/bokuno/kiroku-project/kiroku/kiroku-store-migrations/src/Kiroku/Store/Migrations.hs` (component name `"kiroku"`, no dependencies — downstream consumers take `kirokuMigrations`, not the single-component plan); and the composition shape from `/Users/shinzui/Keikaku/bokuno/pg-migrate/examples/basic/app/Main.hs`, where `accounts` has `Set.empty` dependencies, `billing` declares `Set.singleton "accounts"`, and the plan is `migrationPlan (accounts :| [billing])`. Show the CLI wiring from that same file: `migrationCommandParser plan` for parsing, `cliEnvironment (Settings.connectionString databaseUrl) plan defaultRunOptions` for the environment, `runMigrationCommand` to execute, with `DATABASE_URL` owned by the application. Note that the keiro-runtime-jitsurei services already follow this pattern (`migrations/application/*.sql` + `manifest` + a `-migrate` executable).

Create `migrations/operations.md` (kind Runbook). The CLI surface (all commands from `pg-migrate-cli`): `plan`, `list`, `check`, `status`, `verify`, `up`, `repair`, `new`, each with text and JSON output. The two facts operators most often get wrong, stated as rules: **`verify` compares the declared plan against the ledger** — applied prefix, positions, checksums, kinds, transaction modes — it is *not* a live schema snapshot comparison, and strict verify fails while migrations are still pending; and **a `Running` status after a crash is operationally ambiguous** — especially for nontransactional migrations, which follow a separate durable state machine — so recovery requires a human-audited `repair` (repairs are append-only ledger rows), never a blind re-run. List the deliberate non-goals so nobody files them as bugs: no down migrations, no automatic retries or repair, no arbitrary-IO migrations, no runtime filesystem discovery, no whole-database schema-snapshot comparison. A binary built against an older ledger version refuses to touch a newer database.

Create `migrations/testing.md` (kind Guide). The standard test harness is `withMigratedDatabase :: MigrationPlan -> (Connection -> IO value) -> IO (Either MigratedDatabaseError value)` from `/Users/shinzui/Keikaku/bokuno/pg-migrate/pg-migrate-test-support/src/Database/PostgreSQL/Migrate/Test.hs` (with `...Options` and `...Config` variants): it brackets an ephemeral PostgreSQL instance, applies the full plan, and hands the callback a fresh `Connection`. The gotcha that earns a `-- WRONG` / `-- CORRECT` pair: the return type nests — if the callback itself returns an `Either`, the result is `Either MigratedDatabaseError (Either e value)`, and tests that pattern-match only the outer `Right` silently discard inner failures. The fleet standard: each service wraps the harness in a `with<Service>MigratedDatabase` helper that bakes in the service's composed plan, unwraps the outer `Either`, and fails the test loudly on `Left`.

Create `migrations/codd-transition.md` (kind Guide). A short explainer, not a runbook. The story: the fleet previously used codd, which keyed applied migrations by filename only; kiroku and keiro cut over to pg-migrate first, renaming their SQL files and — in keiro's case — relocating framework tables from the `kiroku` schema into a dedicated `keiro` schema. Databases holding real data cannot be dropped, so the transition is a **one-time, forward-only, ledger-only history import**: read the codd ledger, write equivalent rows into the pg-migrate ledger, never replay DDL. Evidence honesty has two levels: `SamePayload` (checksum-backed — the bytes on disk are provably the bytes codd applied) versus `EquivalentState` (validator-backed — for bodies legitimately rewritten in place under codd's checksum-blind model). Kiroku's worked example is `Kiroku.Store.Migrations.History.Codd` (`/Users/shinzui/Keikaku/bokuno/kiroku-project/kiroku/kiroku-store-migrations/src/Kiroku/Store/Migrations/History/Codd.hs`), mapping its 7 historical codd filenames to native `0001`…`0007` with `SamePayload` evidence. Current state: one pg-migrate ledger owns the kiroku + keiro + pgmq components; codd survives only behind keiro's off-by-default `legacy-codd-tools` flag. For upgrading a production database on the old cohort, point the reader at the `cohort-migrate` agent skill, which composes and proves the remediation on a restored clone before production is touched.

Create `migrations/README.md` last (kind Guide): the index, same shape as `kiroku/README.md`, sending first-time readers to `pg-migrate-model.md` and service authors to `service-package.md`.


### Milestone 3: mori.dhall registration and validation

Scope: register all fifteen documents and the two new dependencies in `mori.dhall`, then run the full validation battery. Acceptance: `dhall --file mori.dhall` exits 0, `mori validate` prints `Configuration is valid.`, `grep -Ec 'key = "(kiroku|migrations)-' mori.dhall` prints `15` (the count is scoped to this plan's own key prefixes because sibling plans under the same MasterPlan append their own DocRef blocks in unspecified order), and the link and symbol checks in Concrete Steps pass.

Edit `mori.dhall` (repository root). Two changes, both append-only. First, extend the `dependencies` list — currently `[ "shinzui/keiki", "shinzui/keiro", "shinzui/kiroku", "shinzui/shibuya" ]` — by appending `"shinzui/pg-migrate"` and `"shinzui/pgmq-hs"` after the existing entries (both names verified against `mori registry list`). Second, append fifteen `Schema.DocRef` entries after the existing `keiki-json-event-codecs` entry, without touching the existing ones. The exact entries (kinds per the Decision Log; audience always `Module`; `location` always `Schema.DocLocation.LocalFile`):

```dhall
      , Schema.DocRef::{
        , key = "kiroku-overview"
        , kind = Schema.DocKind.Guide
        , audience = Schema.DocAudience.Module
        , description = Some
            "Index of kiroku event-store standards for keiro services; start here"
        , location = Schema.DocLocation.LocalFile "kiroku/README.md"
        }
      , Schema.DocRef::{
        , key = "kiroku-append-and-read"
        , kind = Schema.DocKind.BestPractice
        , audience = Schema.DocAudience.Module
        , description = Some
            "ExpectedVersion semantics, idempotent retries via supplied event ids, and streaming reads"
        , location = Schema.DocLocation.LocalFile "kiroku/append-and-read.md"
        }
      , Schema.DocRef::{
        , key = "kiroku-transactions-and-projections"
        , kind = Schema.DocKind.BestPractice
        , audience = Schema.DocAudience.Module
        , description = Some
            "Atomic append plus projection with runTransactionAppendingResource, and why the other combinators are traps"
        , location =
            Schema.DocLocation.LocalFile "kiroku/transactions-and-projections.md"
        }
      , Schema.DocRef::{
        , key = "kiroku-connection-settings"
        , kind = Schema.DocKind.BestPractice
        , audience = Schema.DocAudience.Module
        , description = Some
            "Store schema and NOTIFY channel, extraSearchPath seam, timeouts, and synchronous handler discipline"
        , location = Schema.DocLocation.LocalFile "kiroku/connection-settings.md"
        }
      , Schema.DocRef::{
        , key = "kiroku-subscriptions"
        , kind = Schema.DocKind.BestPractice
        , audience = Schema.DocAudience.Module
        , description = Some
            "At-least-once subscriptions, per-batch checkpoints, overflow policies, and Serial consumer groups"
        , location = Schema.DocLocation.LocalFile "kiroku/subscriptions.md"
        }
      , Schema.DocRef::{
        , key = "kiroku-operational-invariants"
        , kind = Schema.DocKind.Runbook
        , audience = Schema.DocAudience.Module
        , description = Some
            "The ten invariants every kiroku-backed service must respect in production"
        , location =
            Schema.DocLocation.LocalFile "kiroku/operational-invariants.md"
        }
      , Schema.DocRef::{
        , key = "kiroku-observability"
        , kind = Schema.DocKind.Guide
        , audience = Schema.DocAudience.Module
        , description = Some
            "Wiring kiroku-metrics and kiroku-otel: collector composition, spans, Prometheus names, health probes"
        , location = Schema.DocLocation.LocalFile "kiroku/observability.md"
        }
      , Schema.DocRef::{
        , key = "kiroku-lifecycle-and-deletion"
        , kind = Schema.DocKind.Guide
        , audience = Schema.DocAudience.Module
        , description = Some
            "Soft and hard deletion, the advisory hard-delete GUC, truncateBefore compaction, and provisional linkToStream"
        , location =
            Schema.DocLocation.LocalFile "kiroku/lifecycle-and-deletion.md"
        }
      , Schema.DocRef::{
        , key = "migrations-overview"
        , kind = Schema.DocKind.Guide
        , audience = Schema.DocAudience.Module
        , description = Some
            "Index of pg-migrate migration standards for keiro services; start here"
        , location = Schema.DocLocation.LocalFile "migrations/README.md"
        }
      , Schema.DocRef::{
        , key = "migrations-pg-migrate-model"
        , kind = Schema.DocKind.Guide
        , audience = Schema.DocAudience.Module
        , description = Some
            "The pg-migrate model: components, manifests, exact-byte embedding, the ledger, and the RecompilePlugin"
        , location = Schema.DocLocation.LocalFile "migrations/pg-migrate-model.md"
        }
      , Schema.DocRef::{
        , key = "migrations-authoring"
        , kind = Schema.DocKind.BestPractice
        , audience = Schema.DocAudience.Module
        , description = Some
            "Authoring rules: append-only migrations, the no-transaction directive, and manifest v1 strictness"
        , location = Schema.DocLocation.LocalFile "migrations/authoring.md"
        }
      , Schema.DocRef::{
        , key = "migrations-service-package"
        , kind = Schema.DocKind.BestPractice
        , audience = Schema.DocAudience.Module
        , description = Some
            "The <service>-migrations package pattern composing kiroku, keiro, pgmq, and service components into one plan"
        , location = Schema.DocLocation.LocalFile "migrations/service-package.md"
        }
      , Schema.DocRef::{
        , key = "migrations-operations"
        , kind = Schema.DocKind.Runbook
        , audience = Schema.DocAudience.Module
        , description = Some
            "Operating verify, status, and repair; verify is ledger-versus-plan; Running after a crash needs audited repair"
        , location = Schema.DocLocation.LocalFile "migrations/operations.md"
        }
      , Schema.DocRef::{
        , key = "migrations-testing"
        , kind = Schema.DocKind.Guide
        , audience = Schema.DocAudience.Module
        , description = Some
            "Ephemeral-database tests with withMigratedDatabase, the nested-Either gotcha, and per-service wrappers"
        , location = Schema.DocLocation.LocalFile "migrations/testing.md"
        }
      , Schema.DocRef::{
        , key = "migrations-codd-transition"
        , kind = Schema.DocKind.Guide
        , audience = Schema.DocAudience.Module
        , description = Some
            "Why the fleet moved from codd to pg-migrate and how persistent databases were imported ledger-only"
        , location = Schema.DocLocation.LocalFile "migrations/codd-transition.md"
        }
```

Then run the validation battery in Concrete Steps and tick the remaining Progress items.


## Concrete Steps

All commands run from the repository root, `/Users/shinzui/Keikaku/bokuno/keiro-runtime-patterns`, unless stated otherwise. Do not run anything against `/nix/store` or the filesystem root.

Step 1 — create the directories:

```bash
cd /Users/shinzui/Keikaku/bokuno/keiro-runtime-patterns
mkdir -p kiroku migrations
```

Step 2 — write the milestone 1 documents in the order listed in the Plan of Work (rule docs first, `kiroku/README.md` last so the index can link to finished files). While writing, verify any fact you are unsure of directly against the sources under `/Users/shinzui/Keikaku/bokuno/kiroku-project/kiroku` — for example:

```bash
grep -n "runTransactionAppendingResource" /Users/shinzui/Keikaku/bokuno/kiroku-project/kiroku/kiroku-store/src/Kiroku/Store/Transaction.hs
grep -n "extraSearchPath" /Users/shinzui/Keikaku/bokuno/kiroku-project/kiroku/kiroku-store/src/Kiroku/Store/Connection.hs
```

Step 3 — write the milestone 2 documents the same way, verifying against `/Users/shinzui/Keikaku/bokuno/pg-migrate`.

Step 4 — edit `mori.dhall` as specified in Milestone 3 (append two dependencies, append the fifteen DocRef entries verbatim).

Step 5 — run the symbol cross-check. Every symbol a document names must exist in the source file this plan cites; the script prints `OK` per row and must print no `MISS` lines:

```bash
cd /Users/shinzui/Keikaku/bokuno/keiro-runtime-patterns
K=/Users/shinzui/Keikaku/bokuno/kiroku-project/kiroku
P=/Users/shinzui/Keikaku/bokuno/pg-migrate
while IFS='|' read -r sym file; do
  if grep -q -e "$sym" "$file"; then echo "OK   $sym"; else echo "MISS $sym in $file"; fi
done <<EOF
ExpectedVersion|$K/kiroku-store/src/Kiroku/Store/Types.hs
WrongExpectedVersion|$K/kiroku-store/src/Kiroku/Store/Error.hs
DuplicateEvent|$K/kiroku-store/src/Kiroku/Store/Error.hs
readStreamForwardStream|$K/kiroku-store/src/Kiroku/Store/Read.hs
eventExistsInStream|$K/kiroku-store/src/Kiroku/Store/Read.hs
runTransactionAppendingResource|$K/kiroku-store/src/Kiroku/Store/Transaction.hs
enrichEventsIO|$K/kiroku-store/src/Kiroku/Store/Transaction.hs
enrichEvent|$K/kiroku-store/src/Kiroku/Store/Settings.hs
extraSearchPath|$K/kiroku-store/src/Kiroku/Store/Connection.hs
statementTimeout|$K/kiroku-store/src/Kiroku/Store/Connection.hs
withSubscription|$K/kiroku-store/src/Kiroku/Store/Subscription.hs
OverflowPolicy|$K/kiroku-store/src/Kiroku/Store/Subscription/Types.hs
ConsumerGroup|$K/kiroku-store/src/Kiroku/Store/Subscription/Types.hs
kirokuConsumerGroupProcessors|$K/shibuya-kiroku-adapter/src/Shibuya/Adapter/Kiroku.hs
guardKirokuHandler|$K/shibuya-kiroku-adapter/src/Shibuya/Adapter/Kiroku.hs
setStreamTruncateBefore|$K/kiroku-store/src/Kiroku/Store/Lifecycle.hs
hardDeleteStream|$K/kiroku-store/src/Kiroku/Store/Lifecycle.hs
linkToStream|$K/kiroku-store/src/Kiroku/Store/Link.hs
metricsEventHandler|$K/kiroku-metrics/src/Kiroku/Metrics/Collector.hs
readinessMaxLag|$K/kiroku-metrics/src/Kiroku/Metrics/Config.hs
kiroku_events_appended_total|$K/kiroku-metrics/src/Kiroku/Metrics/Prometheus.hs
subscriptionTraceHandler|$K/kiroku-otel/src/Kiroku/Otel/Subscription.hs
injectTraceContext|$K/kiroku-otel/src/Kiroku/Otel/TraceContext.hs
kirokuMigrationPlan|$K/kiroku-store-migrations/src/Kiroku/Store/Migrations.hs
SamePayload|$K/kiroku-store-migrations/src/Kiroku/Store/Migrations/History/Codd.hs
migrationComponentFromEmbeddedSql|$P/examples/basic/app/Main.hs
RecompilePlugin|$P/examples/basic/app/Main.hs
runMigrationCommand|$P/examples/basic/app/Main.hs
pg-migrate: no-transaction|$P/pg-migrate/src/Database/PostgreSQL/Migrate/Sql/Scanner.hs
withMigratedDatabase|$P/pg-migrate-test-support/src/Database/PostgreSQL/Migrate/Test.hs
EOF
```

Step 6 — run the link check over both indexes. It prints nothing when every relative link in the two READMEs resolves to an existing file:

```bash
cd /Users/shinzui/Keikaku/bokuno/keiro-runtime-patterns
for d in kiroku migrations; do
  grep -oE '\]\(\./[^)#]+' "$d/README.md" | sed 's/^](\.\///' | while read -r rel; do
    [ -f "$d/$rel" ] || echo "BROKEN: $d/README.md -> $rel"
  done
done
```

Step 7 — validate the Dhall and the mori configuration:

```bash
cd /Users/shinzui/Keikaku/bokuno/keiro-runtime-patterns
dhall --file mori.dhall > /dev/null && echo "type-check OK"
mori validate
grep -Ec 'key = "(kiroku|migrations)-' mori.dhall
```

Expected output:

```text
type-check OK
Configuration is valid.
15
```

(The remote mori-schema import in `mori.dhall` is content-addressed and already in the local Dhall cache from the existing file, so the type-check works offline.)

Step 8 — update the Progress checklist in this file, add Decision Log entries for any judgment calls made while writing, and record anything unexpected in Surprises & Discoveries. Do not commit unless the user asks; if asked, use conventional-commit messages (e.g. `docs(kiroku): add event-store best-practice docs`).


## Validation and Acceptance

Acceptance is behavioral, verified from the repository root:

1. `ls kiroku migrations` shows exactly the fifteen Markdown files named in this plan (eight and seven respectively).
2. Every document follows the style contract: open any file and see a single `#` H1, a bold one-line tagline directly beneath it, a one-paragraph scope statement, no YAML frontmatter, language tags on every code fence, and a trailing `## Related Patterns` section.
3. Every non-README document is reachable from its directory's `README.md`, and the link-check loop in Concrete Steps step 6 prints nothing.
4. The symbol cross-check in step 5 prints thirty `OK` lines and zero `MISS` lines, demonstrating that every API name the docs assert exists in the cited source file today.
5. `dhall --file mori.dhall` exits 0; `mori validate` prints `Configuration is valid.`; `grep -Ec 'key = "(kiroku|migrations)-' mori.dhall` prints `15` (prefix-scoped — sibling plans append their own DocRef blocks in unspecified order); and `grep -n "shinzui/pg-migrate\|shinzui/pgmq-hs" mori.dhall` shows both new dependencies present.
6. Spot-check the highest-value content: `kiroku/operational-invariants.md` states all ten invariants; `kiroku/transactions-and-projections.md` names `runTransactionAppendingResource` as the fleet standard and explains both the enrich-hook and the `$all`-lock reasons; `kiroku/subscriptions.md` states the stopped-means-absent alerting rule; `migrations/operations.md` states that `verify` is ledger-versus-plan and that `Running` after a crash requires audited repair; `migrations/codd-transition.md` distinguishes `SamePayload` from `EquivalentState` and points at the `cohort-migrate` skill.
7. Optionally, after the registry re-reads the descriptor (`mori register` if needed), `mori registry docs shinzui/keiro-runtime-patterns` lists the fifteen new documents alongside the seven keiki ones.

There is no compiler to satisfy here, so step 4 is the plan's substitute for a failing-then-passing test: run it before writing (many rows already pass because the plan verified them) and after, and treat any `MISS` as a documentation bug to fix before completion.


## Idempotence and Recovery

Every step is safe to repeat. `mkdir -p` is idempotent; rewriting a Markdown file converges on the same content; the check scripts are read-only against this repository and the two source repositories. The single risky edit is `mori.dhall`: it is shared with other plans (EP-1 also appends entries), so make the change append-only exactly as specified, never reorder or reformat existing entries, and re-run `dhall --file mori.dhall` immediately after editing. If the file is left syntactically broken mid-edit, restore it with `git diff mori.dhall` to inspect and `git checkout -- mori.dhall` to reset to the last committed state, then re-apply the addition in one pass. If another plan has landed its own entries in the meantime, simply append this plan's entries after theirs — Dhall list order is not semantically significant for DocRefs, and `mori validate` will catch duplicate keys.

If the kiroku or pg-migrate sources have moved on since 2026-07-22 (new versions, renamed symbols), do not paper over it: update the affected document and this plan's cited fact together, and log the drift in Surprises & Discoveries. The symbol cross-check is the tripwire for exactly this.


## Interfaces and Dependencies

No Haskell interfaces are created or changed; the deliverables are fifteen Markdown files and one Dhall edit. The interfaces that matter are:

The mori-schema contract already pinned at the top of `mori.dhall` (`https://raw.githubusercontent.com/shinzui/mori-schema/026ae74331e5c516542af1dd96f041c658ed4621/package.dhall` with its sha256) — do not change the pin. Each new entry is a `Schema.DocRef::{ key, kind, audience, description, location }` where `kind` is one of `Schema.DocKind.BestPractice | Guide | Runbook` (per the Decision Log), `audience` is `Schema.DocAudience.Module`, and `location` is `Schema.DocLocation.LocalFile "<repo-relative path>"`.

Tooling required on the machine: `dhall` (1.42.3 verified present) and the `mori` CLI (verified present; `mori validate` and `mori registry list` are the subcommands used). Both are read/validate only — no network access is needed beyond Dhall's local content-addressed cache.

Documented-source dependencies, with the versions the facts in this plan were verified against: kiroku at `/Users/shinzui/Keikaku/bokuno/kiroku-project/kiroku` (kiroku-store 0.3.0.1, kiroku-store-migrations 0.3.0.0, kiroku-otel 0.2.0.1, kiroku-metrics 0.1.0.1, shibuya-kiroku-adapter 0.4.0.0) and pg-migrate at `/Users/shinzui/Keikaku/bokuno/pg-migrate` (1.1.0.0). Registry names added to `dependencies`: `shinzui/pg-migrate` and `shinzui/pgmq-hs` (both verified registered via `mori registry list`; pgmq-hs is listed because the service migrations-package standard names the pgmq component even though this plan writes no pgmq docs). The parent MasterPlan is `docs/masterplans/1-keiro-runtime-standards-docs-and-seihou-blueprints.md`; sibling plans EP-4 and EP-5 will later add the `keiro/` and `messaging/` areas that this plan's documents mention in prose only.
