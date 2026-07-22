---
id: 6
slug: codify-the-ddd-vertical-module-structure-standard
title: "Codify the DDD vertical module structure standard"
kind: exec-plan
created_at: 2026-07-22T14:55:29Z
master_plan: "docs/masterplans/1-keiro-runtime-standards-docs-and-seihou-blueprints.md"
---

# Codify the DDD vertical module structure standard

This ExecPlan is a living document. The sections Progress, Surprises & Discoveries,
Decision Log, and Outcomes & Retrospective must be kept up to date as work proceeds.
If durable project context changes, update or create ADRs in docs/adr/ in the same change.


## Purpose / Big Picture

About twenty services are about to be written or refactored onto the keiro runtime, and today there is no single document that tells a developer (or an agent) how to lay out a keiro service: how many cabal packages to create, which package owns what, where the code for one domain concept lives, which modules the code generator owns versus which ones a human owns, where tests go, and where the `.keiro` specification file sits. The two existing reference codebases even disagree with themselves: danwa (the first-pass reference service) ships one convention in its code but describes an older, abandoned convention in its prose, and keiro-runtime-jitsurei (the richer teaching corpus) is mid-refactor and carries legacy modules that new services must not copy.

After this plan is implemented, this repository contains a new `architecture/` documentation area that states THE standard — one authoritative, prescriptive answer for every one of those questions — reconciled against both reference repos with explicit rulings wherever they diverge. The user-visible outcome: a developer who has never seen a keiro service can open `architecture/README.md` and, from the docs alone, write down the complete directory tree of a new service — package by package, module by module, test suite by test suite — and that tree will match what `keiro-dsl scaffold` produces and what the fleet's code review expects. Every doc is registered in `mori.dhall` so `mori registry docs shinzui/keiro-runtime-patterns` surfaces it to agents. Downstream, ExecPlan 9 (the `haskell-keiro-service` seihou blueprint) scaffolds exactly this structure and cites these docs instead of restating them; that plan hard-depends on this one.

To see it working when done: run the file-existence verification loop in "Validation and Acceptance" (every module the standard names for the worked-example Conversation slice exists in the danwa checkout), type-check `mori.dhall`, and perform the novice exercise (lay out a hypothetical service's tree from the docs and compare with the expected tree embedded in this plan).


## Progress

Plan authored 2026-07-22. Implementation not started. Every stopping point must be recorded here, splitting partially finished items into done/remaining.

- [ ] Milestone 1: `architecture/` directory created in this repo.
- [ ] Milestone 1: `architecture/README.md` (index + one-paragraph statement of the standard) written.
- [ ] Milestone 1: `architecture/service-packages.md` (six-package split, dependency diagram, monolith ruling) written.
- [ ] Milestone 1: `architecture/vertical-slice-modules.md` (the per-concept module table, naming rules, firewall, authoritative-convention ruling) written.
- [ ] Milestone 1: `architecture/cross-cutting-modules.md` (the closed allowlist + division heuristic) written.
- [ ] Milestone 1: Milestone 1 verification loop run against the danwa checkout; zero missing paths.
- [ ] Milestone 2: `architecture/extended-node-verticals.md` (read models, process managers, workflows, routers, publishers, inboxes, queues, contracts; integration-as-a-vertical rule) written.
- [ ] Milestone 2: `architecture/spec-and-scaffolding.md` (`.keiro` placement, `context`/`layout` clauses, scaffold invocation, idempotent re-scaffold workflow) written.
- [ ] Milestone 2: `architecture/test-layout.md` (danwa four-suite core split, per-package suites, vertical `*Spec` layout, `test-support` sublibrary, jitsurei six-suite superset) written.
- [ ] Milestone 2: Milestone 2 verification loop run against the keiro-runtime-jitsurei checkout; zero missing paths.
- [ ] Milestone 3: `architecture/worked-example-conversation.md` (full Conversation slice file listing) written.
- [ ] Milestone 3: eight `Schema.DocRef` entries appended to `mori.dhall`; file type-checks with `dhall`.
- [ ] Milestone 3: cross-links between the eight docs and to `keiki/` verified; forward links to `keiro/` and `messaging/` noted if those areas do not exist yet.
- [ ] Milestone 3: novice acceptance exercise performed and recorded in this plan.
- [ ] Milestone 3: ADR distillation pass — `docs/adr/` seeded with the authoritative-convention ADR.
- [ ] MasterPlan registry row for EP-6 flipped to Complete; MasterPlan Progress checkbox ticked.


## Surprises & Discoveries

Findings from the plan-authoring research pass (2026-07-22), verified directly against the checkouts; keep adding entries during implementation.

- The `-- @generated` banner is not literally line 1 of generated modules. In `/Users/shinzui/Keikaku/bokuno/danwa/danwa-core/src/Danwa/Conversation/Generated/Domain.hs` it appears at line 8, after the `LANGUAGE` pragmas and immediately before the `module` declaration:

  ```haskell
  -- @generated by keiro-dsl; do not edit. Regenerated from the .keiro spec.
  module Danwa.Conversation.Generated.Domain where
  ```

  The standard must therefore say "the banner comment appears in the module header, immediately before the `module` line", not "on line 1".
- danwa's worker test coverage is not exhaustive: `danwa-workers/src/Danwa/Embellishment/Worker.hs` exists but there is no `danwa-workers/test/Danwa/Embellishment/WorkerSpec.hs`. The standard should require one `*Spec` per worker module and note danwa's gap rather than silently inheriting it.
- The two repos disagree on spec placement: danwa keeps the spec at `domain/danwa.keiro`; keiro-runtime-jitsurei keeps it at `services/hospital-capacity/spec/hospital-capacity.keiro`. A ruling is required (made below: `domain/` wins for the six-package shape).
- `danwa-core` ships two cross-cutting modules the task's allowlist did not mention: `Danwa.Diagrams` (library support for the `danwa-diagrams` executable at `danwa-core/app/Diagrams.hs` and the drift-check test suite) and `Danwa.Core` (a dead placeholder). Rulings recorded in the Decision Log: `Diagrams` is admitted to the allowlist; `Core`-style placeholders are excluded from the standard.
- jitsurei's first-class read-model node directories keep the DSL node's snake_case spelling as a module path segment, e.g. `HospitalCapacity/Hospital_readiness/Generated/ReadModel.hs` — a naming wrinkle the extended-nodes doc must state explicitly, because it looks like a typo to a Haskell reader.


## Decision Log

- Decision: The `Generated.*` + single hand-owned `Holes.hs` convention is ruled authoritative; the flat `<Service>.<Concept>.{Domain,Codec,EventStream,Harness}` layout described in danwa's prose is ruled stale and rejected.
  Rationale: danwa's shipped code uses `Generated.*` + `Holes` everywhere; the reversal is explicitly recorded in danwa's own masterplan Decision Log ("Adopt keiro-dsl's configurable module placement", `/Users/shinzui/Keikaku/bokuno/danwa/docs/masterplans/1-bootstrap-danwa-event-sourced-conversation-substrate.md` lines 638–660); the `Generated` path segment plus the `@generated` banner is the load-bearing mechanism that makes re-scaffolding idempotent (overwrite generated, never touch holes). The stale prose lives in the danwa-core cabal description (lines 4–12 and 47–52) and the old masterplan narrative; EP-3 fixes those at their source, this plan only rules against them.
  Date: 2026-07-22

- Decision: The six-package split (`<service>-core/-api/-server/-workers/-migrations/-client`) is THE fleet standard for deployed services; keiro-runtime-jitsurei's one-cabal-package-per-service monolith is acceptable only for teaching and example repositories.
  Rationale: the split gives each deployable role its own dependency budget (workers never link servant; the client never links the server; migrations are independent of domain code so operators can run them without building the world) and each package its own test suites. jitsurei bundles library + CLIs + six test suites in one package per service, which is fine for a walkthrough corpus but erases those boundaries.
  Date: 2026-07-22

- Decision: jitsurei's legacy parallel hand modules per aggregate (`Transducer.hs`, `Projection.hs`, `EventStream.hs`, `CommandProcessor.hs` alongside the generated ring) are NOT part of the standard.
  Rationale: they are a deliberate teaching surface kept by jitsurei's plan 9 during its mid-refactor state (its masterplan 2 is "modernize with keiro-dsl and pg-migrate"); deployed services must have exactly one hand-owned module per aggregate (`Holes.hs`) plus `ReadModel.hs`, or the firewall guarantee dissolves.
  Date: 2026-07-22

- Decision: The `.keiro` spec lives at `domain/<service>.keiro` at the repository root (danwa's placement), not in a per-service `spec/` directory (jitsurei's placement).
  Rationale: in the six-package shape there is one service per repository, so a top-level `domain/` directory reads naturally and matches the danwa reference the blueprint will scaffold; jitsurei's `spec/` placement follows from its multi-service monorepo, which is the non-standard shape.
  Date: 2026-07-22

- Decision: `Diagrams` (the Mermaid lifecycle-diagram support module + executable) is admitted to the cross-cutting allowlist; `Core`-style placeholder modules are excluded from the standard.
  Rationale: `Danwa.Diagrams` backs the `danwa-diagrams` executable and the `danwa-core-diagrams` drift-check suite — real, fleet-worthy infrastructure named after a technology, hence allowlist material. `Danwa.Core` is documented dead weight (danwa's own research notes call it a placeholder) and codifying it would make every new service ship an empty module.
  Date: 2026-07-22

- Decision: The `architecture/` area is split into eight focused documents (an index plus seven rule docs) mirroring the granularity of the existing `keiki/` area, rather than one long standard document.
  Rationale: this repo is a terse, agent-facing pattern corpus (MasterPlan Vision); mori DocRefs point at focused files so an agent can load exactly the rule it needs; the `keiki/` area (eight files) established the granularity.
  Date: 2026-07-22

- Decision: DocRef kinds are `Guide` for the index, `BestPractice` for the five prescriptive rule docs, and `Pattern` for the extended-node-verticals and worked-example docs; all eight use audience `Module` and keys `architecture-<file-slug>`.
  Rationale: matches the parenthetical in the MasterPlan mission (BestPractice/Pattern, audience Module) while following the `keiki-overview` precedent that an index README registers as a `Guide`.
  Date: 2026-07-22


## Outcomes & Retrospective

To be filled during and after implementation. Before marking the plan complete, perform the ADR distillation pass: the authoritative `Generated.*` + `Holes` convention ruling (with the rejected flat layout and rejected legacy parallel modules) is the prime ADR candidate — promote it into `docs/adr/` (which does not exist yet; this plan creates it), together with the six-package-split ruling. Task-local details (verification transcripts, link-check notes) stay here.


## Context and Orientation

This repository, `/Users/shinzui/Keikaku/bokuno/keiro-runtime-patterns`, is a documentation-only corpus of terse, prescriptive patterns for the keiro runtime. It currently contains one doc area, `keiki/` (eight Markdown files about the keiki transducer library), a `mori.dhall` registry file at the repo root that registers each doc so the `mori` CLI can surface it to agents, and the plan documents under `docs/`. There is no application code here. `docs/adr/` does not exist yet — there are no ADRs to consult; this plan will seed the directory at completion (see Outcomes & Retrospective). This plan is EP-6 of the MasterPlan at `docs/masterplans/1-keiro-runtime-standards-docs-and-seihou-blueprints.md`; per that plan's Integration Point 3, EP-6 owns the vertical-slice convention, and EP-9 (the service-scaffolding blueprint) hard-depends on it.

The subject of the standard is the keiro runtime, an event-sourced microservice stack for Haskell. Plain-language glossary for every term the new docs will use (define these again inside the docs themselves — the docs must be self-contained too):

- Event sourcing: instead of storing current state, the service appends immutable events ("ConversationStarted") to a log and derives state by replaying them.
- kiroku: the PostgreSQL event store library (the append-only log).
- keiki: the pure typed state-machine library. A transducer is a keiki state machine: it takes a command, checks guards, and emits events. It contains the domain decision logic.
- keiro / keiro-dsl: the framework runtime (command runners, read models, process managers, outbox/inbox, workflows) and its build-time toolchain. keiro-dsl reads a typed specification file (`<service>.keiro`) and scaffolds Haskell modules; it is code generation, not a runtime interpreter.
- shibuya: the worker-supervision library (subscription and queue processors run under it).
- Aggregate: one consistency boundary in the domain (e.g. Conversation) with its own event stream and transducer.
- Read model: a PostgreSQL table (plus the Haskell rows/statements to query it) derived from events, used to answer queries.
- Projection: the fold that applies events to a read model.
- Process manager: an event-sourced reactor that listens to events and dispatches commands/timers (saga).
- Vertical slice: the organizing principle this standard codifies — all code for one domain concept (its generated ring, its hand-written decision logic, its read model, its HTTP surface, its worker) is colocated under the concept's module namespace across packages, instead of being grouped into technical layers ("all transducers here, all handlers there").
- The firewall: keiro-dsl emits two kinds of module. `Generated.*` modules carry the banner comment `-- @generated by keiro-dsl; do not edit. Regenerated from the .keiro spec.` in their header and are overwritten on every scaffold run; `Holes.hs` modules are created once and never overwritten — they hold everything a human owns (the keiki transducer, the projection apply function). No generated module ever contains keiki decision logic.

Ground truth lives in two external checkouts (read-only for this plan; this plan edits nothing outside this repository):

1. `/Users/shinzui/Keikaku/bokuno/danwa` — the first service built on the stack and the structural reference. Six cabal packages (`danwa-core`, `danwa-api`, `danwa-server`, `danwa-workers`, `danwa-migrations`, `danwa-client`, listed in `cabal.project`), spec at `domain/danwa.keiro` (opens with `context danwa` / `layout collocated`), three aggregates (Conversation, Message, Embellishment). Its CODE is authoritative; its PROSE is stale — the danwa-core cabal description and the old masterplan narrative describe an abandoned flat module layout. Do not trust danwa prose; trust `find` output. danwa is also on the older cohort (codd migrations, no pg-migrate, noop tracer) — package RESPONSIBILITIES generalize, specific migration tooling does not.
2. `/Users/shinzui/Keikaku/bokuno/keiro-runtime-jitsurei` — a two-service teaching monorepo (`services/incident-command`, `services/hospital-capacity`) on the newer cohort (keiki 0.2 / keiro 0.3 / pg-migrate 1.1, real OpenTelemetry). It demonstrates the richer keiro-dsl node vocabulary (first-class read models, process managers, workflows, routers, publishers, inboxes, work queues, contracts) that danwa lacks, but it is mid-refactor: it keeps legacy hand-written per-aggregate modules alongside the generated ring as a deliberate teaching surface. The standard takes its NODE VOCABULARY placements from jitsurei and rejects its package shape and legacy modules.

The reconciliation this plan performs, in one sentence: take danwa's package split, module convention, and test layout as the skeleton of the standard; take jitsurei's richer node-kind placements and extended test suites as the standard's extension for services that use those node kinds; and rule explicitly against danwa's stale prose, against jitsurei's monolith package shape, and against jitsurei's legacy parallel hand modules.

Registration works through `mori.dhall` at the repo root: a Dhall record with a `docs` list of `Schema.DocRef` entries (fields `key`, `kind`, `audience`, `description`, `location`), where `Schema` is the pinned remote import already at the top of the file. Per MasterPlan Integration Point 1, EP-6 owns the `architecture/` directory and appends only its own DocRef block, never reordering existing entries. (Known pre-existing drift — `keiki/diagram-docs.md` has no DocRef — belongs to EP-1; do not fix it here.)

Style, per MasterPlan Integration Point 2: no YAML frontmatter; a single `#` H1 title; a bold one-line tagline directly under the H1; a one-paragraph scope statement; prescriptive, rule-first prose ("The rule is one sentence: …"); code samples always in fenced blocks with language tags, using `-- CORRECT / -- WRONG` or `-- Before / -- After` contrast pairs; relative Markdown cross-links between docs in this repo; a trailing "Related Patterns" section. The existing `keiki/` docs realize most of this (they predate the bold-tagline detail; new docs include it). Related plans with soft ordering: EP-4 (`keiro/` area) and EP-5 (`messaging/` area) may or may not have landed when this runs; the MasterPlan sanctions forward relative links to doc paths those plans will create — write the links, verify them at completion, and record any dangling ones in Progress. Cross-repo references (e.g. servant route standards in haskell-jitsurei) must be plain text naming the repo and file plus its mori key, never a relative link.


## Plan of Work

All new files are created under `/Users/shinzui/Keikaku/bokuno/keiro-runtime-patterns/architecture/`; the only pre-existing file edited is `mori.dhall` (append-only), and at completion `docs/adr/<N>-vertical-slice-generated-holes-convention.md` is created, where `<N>` is the next free ADR number at implementation time — sibling plans (for example `docs/plans/5-document-process-managers-integration-events-and-messaging-standards.md`) also seed `docs/adr/`, so do not assume `0001` is free. Work proceeds in three milestones. Throughout, every path claim written into a doc must be verified against the checkouts with the loops in Concrete Steps — the standard's credibility rests on every named module existing in the reference code.


### Milestone 1 — The core standard: packages, slices, and the allowlist

Scope: create the `architecture/` directory and write the four documents that carry the heart of the standard and all of its rulings. At the end of this milestone a reader can lay out a danwa-shaped service; extended node kinds and tests follow in Milestone 2. Acceptance: the four files exist, follow the style contract, contain the rulings verbatim in spirit, and the Milestone 1 verification loop reports zero missing paths.

**`architecture/README.md`** — the index. H1 "Keiro Service Architecture", bold tagline ("**One vertical slice per domain concept, six packages per service, generated ring plus one hand-owned Holes module.**" or similar), a scope paragraph stating that this area is THE structure standard for deployed keiro services, reconciled from danwa (structure reference; code authoritative, prose stale) and keiro-runtime-jitsurei (node vocabulary reference; mid-refactor), then a linked table of contents over the other seven docs with one sentence each, and a short "How to use this area" paragraph: to lay out a new service read service-packages, vertical-slice-modules, and spec-and-scaffolding in that order; to place a new module kind read extended-node-verticals; to decide where a module goes read cross-cutting-modules.

**`architecture/service-packages.md`** — the package split standard. State the rule first: a deployed keiro service is exactly six cabal packages, named `<service>-core`, `<service>-api`, `<service>-server`, `<service>-workers`, `<service>-migrations`, `<service>-client`. Then one short subsection per package giving its responsibility and allowed dependencies, written generically with danwa paths as evidence:

- `<service>-core`: the domain. Custom prelude, `App.Config`, per-concept generated ring + `Holes` + `ReadModel`, `Postgres.{Pool,Runner}` (pool acquisition and the store runner), `Integration.*` contract modules, `Diagrams` support, plus the `<service>-diagrams` executable. Depends on keiki, kiroku, keiro, hasql; depends on NO other `<service>-*` package. Everything else depends on it.
- `<service>-api`: servant route records (NamedRoutes) and wire DTOs only. Depends on `<service>-core`. No servant-server, no warp.
- `<service>-server`: the HTTP application — `Server.{App,Boot,Config,Seam}`, per-concept `Handler` modules, the `<service>-server` executable. Depends on `<service>-core` and `<service>-api` plus servant-server/warp.
- `<service>-workers`: shibuya-supervised background processing — `Workers.{Config,Registry,Subscription}`, per-concept `Worker` modules, `Integration.*` workers, the `<service>-worker` executable. Depends on `<service>-core` plus keiro/shibuya/queue adapters. Never depends on `-api` or `-server`.
- `<service>-migrations`: schema migrations and the `<service>-migrate` executable (including the `new <desc>` scaffold subcommand). Depends on the migration toolchain (pg-migrate on the current cohort; danwa still shows codd) and on NO other `<service>-*` package — deliberately independent of `-core` so migrations build and run without the domain. Publishes a PUBLIC sublibrary `test-support` (in danwa: `danwa-migrations/test-support/Danwa/Migrations/TestSupport.hs`, `visibility: public` in the cabal file) that provisions ephemeral migrated databases; the test suites of `-core`, `-server`, and `-workers` depend on `<service>-migrations:test-support`.
- `<service>-client`: the typed client derived from the API. Depends on `<service>-api` plus servant-client. Lets other Haskell services consume the API without linking the server.

Reproduce the dependency diagram (generalized from danwa, verified in the cabal files):

```text
<service>-core        ← everything below depends on it; it depends on no sibling
   ├── <service>-api            → core
   │        ├── <service>-server → core, api   (+ servant-server, warp, keiro, kiroku)
   │        └── <service>-client → api         (+ servant-client)
   ├── <service>-workers        → core         (+ keiro, shibuya-core, shibuya adapters,
   │                                             pgmq; kafka client behind a cabal flag)
   └── <service>-migrations     → migration toolchain only; NO dependency on core.
                                  Public sublibrary test-support ← used by the TEST
                                  suites of core, server, and workers.
```

Close with the explicit ruling: the six-package split is the fleet standard for every deployed service. The one-cabal-package-per-service shape used by keiro-runtime-jitsurei (library + CLI executables + six test suites in a single package, e.g. `services/hospital-capacity/hospital-capacity.cabal`) is acceptable only for teaching and example repositories, and a repo choosing it must say so in its README. Also record danwa's own precedent that the split is a floor and a ceiling: a seventh `danwa-postgres` package was folded back into `danwa-core` (danwa masterplan Decision Log, "Eliminate danwa-postgres") — do not mint extra technical packages.

**`architecture/vertical-slice-modules.md`** — the heart. Open with the one-sentence rule: for every domain concept `<Concept>`, ALL of its code lives in modules named `<Service>.<Concept>.*`, colocated across the six packages; nothing about a concept lives in a technical-layer module. Then reproduce the per-concept module table (this exact content, verified against danwa):

| Module | Package | Owner | Purpose |
|---|---|---|---|
| `<Concept>.Generated.Domain` | core | generated | id/enum newtypes, Command/Event sums + field records, register file, initial registers, constructor predicates, wire helpers, renderers |
| `<Concept>.Generated.Codec` | core | generated | event codec: encode/parse events, enum parsers |
| `<Concept>.Generated.EventStream` | core | generated | the stream definition + validated stream via `mkEventStreamOrThrow` |
| `<Concept>.Generated.Projection` | core | generated | status mapping, inline projection wiring (points at the apply function in Holes) |
| `<Concept>.Generated.Harness` | core | generated | harness assertions: `validateTransducer`, golden round-trips, accepted transitions |
| `<Concept>.Holes` | core | hand | the keiki transducer (decision logic) + `apply<Concept>s :: Event -> RecordedEvent -> Tx.Transaction ()` (the read-model fold) |
| `<Concept>.ReadModel` | core | hand | row records, hasql encoders/decoders, SQL statements |
| `<Concept>.Api` | api | hand | servant NamedRoutes record + DTOs for this concept |
| `<Concept>.Handler` | server | hand | per-route handlers (run commands, run read queries) |
| `<Concept>.Worker` | workers | hand | shibuya processor: decode event, apply projection |

Then the naming rules as prose: (1) every generated module lives under a `Generated.` path segment and carries the exact banner `-- @generated by keiro-dsl; do not edit. Regenerated from the .keiro spec.` in its header immediately before the `module` line — the banner is the firewall marker the scaffolder checks before overwriting, so never remove it and never add it to a hand module; (2) there is exactly ONE hand-owned hole module per aggregate, named `Holes` (create-if-absent: the scaffolder writes it once and never again); (3) hand modules sit flat under `<Service>.<Concept>` with no extra nesting; (4) a concept may have several workers when it has several processes (danwa evidence: `Danwa.Conversation.Worker` and `Danwa.Conversation.AgentSummaryWorker` both live in the Conversation vertical — the AgentSummaryWorker docstring explicitly justifies its placement as "a Conversation-side process"). Include a `-- CORRECT / -- WRONG` contrast block showing `Danwa.Conversation.Holes` vs. a hand-edited `Danwa.Conversation.Generated.Domain`, and a second one showing the slice layout vs. a technical-layer layout (`Danwa.Transducers.Conversation` — WRONG).

Close with the ruling section (this is the prime ADR candidate): the `Generated.*` + `Holes` convention is authoritative. Two things that LOOK like alternatives are explicitly rejected: (a) the flat `<Service>.<Concept>.{Domain,Codec,EventStream,Harness}` layout with split hand-owned `Transducer`/`Projection` modules that danwa's cabal description and old masterplan prose describe — that layout was abandoned; the reversal is recorded in danwa's masterplan Decision Log ("Adopt keiro-dsl's configurable module placement") and the shipped code contains no trace of it; and (b) keiro-runtime-jitsurei's legacy parallel hand modules (`Transducer.hs`, `Projection.hs`, `EventStream.hs`, `CommandProcessor.hs` next to each aggregate's generated ring, e.g. under `services/hospital-capacity/src/HospitalCapacity/Capacity/`) — those are a deliberate teaching surface kept by jitsurei's plan 9 while the corpus is mid-refactor; a deployed service must never carry hand modules that duplicate the generated ring, because the firewall (regenerate freely, hand code untouched) only holds when the split is exact.

**`architecture/cross-cutting-modules.md`** — the allowlist. The rule: a module may use a technical-layer name only if it is on this closed list; everything else must live in a concept vertical. The list, with one line of responsibility each and the danwa evidence path: `Prelude` (custom prelude re-export module), `App.Config` (application configuration record), `Postgres.Pool` and `Postgres.Runner` (pool acquisition; store/AppConfig wiring), `Server.App`, `Server.Boot`, `Server.Config`, `Server.Seam` (WAI application, startup, server config, the error-mapping seam between keiro results and HTTP), `Workers.Config`, `Workers.Registry`, `Workers.Subscription` (worker config, the processor registry, shared subscription plumbing), `Api` (the umbrella route record that composes the per-concept `Api` modules), `Migrations` and `Migrations.New` (migration composition; the `new` scaffold), and `Diagrams` (Mermaid lifecycle-diagram generation backing the diagrams executable and drift-check suite). State the two exclusions: placeholder modules like danwa's `Danwa.Core` are dead weight, not standard; and `Integration` is NOT on this list because integration is a vertical concept (see extended-node-verticals). Then the division heuristic, verbatim in spirit: if a module's name names a domain concept, it goes in that concept's vertical; if it names a technology, it must justify itself against this allowlist — and if it is not on the list, the code belongs inside a concept vertical instead. Give one worked WRONG example (`Danwa.Kafka.Publishers` collecting all publishers) and its CORRECT resolution (per-concept/integration workers plus the allowlisted `Workers.Registry`).


### Milestone 2 — Extended node kinds, spec placement, and the test standard

Scope: the three documents that extend the core standard — where the richer keiro-dsl node kinds sit, where the `.keiro` spec lives and how scaffolding is invoked, and the test-suite standard. Verified against the jitsurei checkout as well as danwa. Acceptance: three files exist, style-conformant, and the Milestone 2 verification loop reports zero missing paths.

**`architecture/extended-node-verticals.md`** — where richer node kinds sit. Scope paragraph: danwa uses only aggregate/projection/operation nodes; services using keiro-dsl's fuller vocabulary follow the placements below, taken from keiro-runtime-jitsurei's `hospital-capacity` service (module root `HospitalCapacity`, source under `services/hospital-capacity/src/`). Every node kind gets its own vertical directory named after the node, holding its generated ring and (where the node has hand-owned logic) its holes module:

- First-class read models (`readmodel` nodes): `<Node>/Generated/{ReadModel,ReadModelHarness,ReadModelTable}.hs` + hand-owned `<Node>/ReadModelHoles.hs`. Node directories keep the DSL node's snake_case name verbatim — `Hospital_readiness`, `Accepted_transfer_needs`, `Transfer_candidates`, `Transfer_decisions` — it is not a typo; do not camel-case it.
- Process managers (`process` nodes): `<Name>/Generated/{Process,ProcessHarness}.hs` + `<Name>/ProcessHoles.hs` (evidence: `HospitalSurge/`).
- Durable workflows (`workflow` nodes): `<Name>/Generated/{WorkflowFacts,WorkflowRuntime}.hs` (evidence: `HospitalTransferReservation/`; no holes module — workflow bodies are wired elsewhere by hand).
- Routers (`router` nodes): `<Name>/Generated/{Router,RouterHarness}.hs` + `<Name>/RouterHoles.hs` (evidence: `TransferNeedRouter/`).
- Publishers: `<Name>/Generated/Publisher.hs` (evidence: `HospitalPublisher/`). Inboxes: `<Name>/Generated/Inbox.hs` (evidence: `IncidentInbox/`). Work queues: `<Node>/Generated/{Queue,QueuePolicy}.hs` (evidence: `Reservation_work/`). Integration contracts: `<Name>/Generated/Contract.hs` (evidence: `Emergency/`).

Then the integration rule with danwa evidence: integration is its own vertical concept under the first-class `<Service>.Integration.*` namespace, never a technical layer — the public contract module lives in core (`danwa-core/src/Danwa/Integration/AddressedMessage.hs`), the producing reactor and the outbox publisher live in workers (`danwa-workers/src/Danwa/Integration/{AddressedMessageWorker,OutboxPublisherWorker}.hs`), and hand-written Kafka/inbox/outbox glue in a richer service also sits there (jitsurei: `HospitalCapacity/Integration/{Contracts,Inbox,Outbox,KafkaConsumer,KafkaPublisher,ReservationWorkDispatch}.hs`). Repeat the warning from vertical-slice-modules: jitsurei's per-aggregate legacy hand modules seen in the same tree are the teaching surface, not the standard. Cross-link the deep semantics to the EP-5 `messaging/` docs (forward links) — this doc places files, EP-5 explains outbox/inbox/process-manager behavior.

**`architecture/spec-and-scaffolding.md`** — the spec file and the generator. The rules: (1) the single source of truth for the domain is `domain/<service>.keiro` at the repository root; (2) its first two clauses are `context <service>` (which fixes the Haskell module root, e.g. `context danwa` → modules under `Danwa.`) and `layout collocated` (which selects the vertical-slice placement this standard mandates — layout belongs in the spec, not on the command line, so every scaffold run agrees); (3) scaffolding always targets the core package's source root: `keiro-dsl scaffold domain/<service>.keiro --out <service>-core/src`; the `--module-root` and `--collocate` CLI flags exist as overrides for specs that omit the clauses, and the standard is to not need them; (4) always `check` before `scaffold`, format after, and re-run the domain harness suite after regenerating. Embed danwa's realized workflow (from `/Users/shinzui/Keikaku/bokuno/danwa/justfile`, recipes `keiro-check` and `keiro-scaffold` — keiro-dsl is run via `cabal run` from a keiro checkout because it is not on PATH):

```bash
# from the keiro checkout; paths absolute to the service repo
cabal run -v0 keiro-dsl -- check    /path/to/<service>/domain/<service>.keiro
cabal run -v0 keiro-dsl -- scaffold /path/to/<service>/domain/<service>.keiro \
    --out /path/to/<service>/<service>-core/src
nix fmt   # generated output is made formatter-clean deterministically,
          # so re-scaffold + format is a no-op when nothing changed
```

Explain WHY this is safe to run repeatedly (the firewall: `Generated.*` overwritten, `Holes` create-if-absent; the informational scaffold manifest is gitignored), name the one escape hatch to avoid (`--force-generated-overwrite` bypasses the banner check — a foot-gun), and note the jitsurei deviation (spec under `services/<name>/spec/` — a monorepo accommodation, not the standard). Cross-link keiro-dsl adoption guidance (when to use the DSL at all) to the EP-4 `keiro/` area as a forward link.

**`architecture/test-layout.md`** — the test standard. Rule first: tests are laid out vertically too, and every package owns suites proportional to what it owns. The danwa baseline (suite names verified in the cabal files):

- `<service>-core` has FOUR suites: `<service>-core-test` (`test/`, smoke); `<service>-core-domain` (`test-domain/`, a bespoke driver — not tasty — that runs every aggregate's generated `harnessAssertions` and calls `exitFailure` if any returns False; its only dependencies are base and the core library, so domain validation never waits on a database); `<service>-core-diagrams` (`test-diagrams/`, tasty; asserts the generated Mermaid lifecycle diagrams are not stale — `staleDiagrams == []` — and validates diagram syntax, keeping `docs/diagrams/domain-lifecycles.md` in sync with the code); `<service>-core-postgres` (`test-postgres/`, tasty; provisions an ephemeral PostgreSQL via the migrations `test-support` sublibrary, round-trips a real event through kiroku, and upserts/reads the read models).
- `<service>-migrations` has `<service>-migrations-test` plus the PUBLIC `test-support` sublibrary other packages' suites import (in danwa it exposes `withDanwaMigratedDatabase`); the suite asserts migration filename/slug/template rules and that an ephemeral database ends up with the expected schemas, ledger rows, and an idempotent re-run.
- `<service>-server` has `<service>-server-test` (tasty; drives a real handler against an ephemeral migrated database and asserts on the resulting events).
- `<service>-workers` has `<service>-workers-test`: a `test/Main.hs` aggregator over per-concept `*Spec` modules laid out vertically MIRRORING `src` — `Danwa/Conversation/WorkerSpec.hs`, `Danwa/Conversation/AgentSummaryWorkerSpec.hs`, `Danwa/Message/WorkerSpec.hs`, `Danwa/Integration/AddressedMessageWorkerSpec.hs`, `Danwa/Workers/RegistrySpec.hs` — each exporting `tests :: TestTree`. State the rule danwa itself falls short of: every worker module gets a `*Spec` (danwa is missing `Embellishment/WorkerSpec.hs`; the standard requires it).
- Shared patterns: tasty + tasty-hunit; ephemeral databases only (never a developer database); ephemeral provisioning always flows through `<service>-migrations:test-support`.

Then the extended standard from jitsurei for services using the richer node kinds — the six-suite superset per service (suite names verified in `services/hospital-capacity/hospital-capacity.cabal`): `test` (unit), `dsl-test` (scaffold/spec conformance), `contract-test` (integration-contract conformance), `migration-test` (pg-migrate plan checks), `kafka-integration` (real-broker integration), and the optional additive `symbolic-test` (SBV/z3-backed symbolic verification of transducers; requires z3). The mapping rule: in the six-package shape these extra suites attach to the package owning the surface — `dsl-test` and `symbolic-test` to `-core`, `contract-test` and `kafka-integration` to `-workers`, `migration-test` to `-migrations`.


### Milestone 3 — Worked example, registration, validation, ADR seed

Scope: the worked-example doc, the `mori.dhall` registration, the full verification pass, the novice acceptance exercise, and the ADR distillation. Acceptance: all Concrete Steps commands pass with the expected outputs; the MasterPlan registry row flips to Complete.

**`architecture/worked-example-conversation.md`** — one concept end to end. Present danwa's Conversation slice as the complete, real file listing a new service replicates per concept (all paths relative to the danwa repo root, every one verified to exist):

```text
domain/danwa.keiro                                             -- the aggregate + projection + operations are declared here
danwa-core/src/Danwa/Conversation/Generated/Domain.hs          -- @generated: ids, Command/Event sums, registers
danwa-core/src/Danwa/Conversation/Generated/Codec.hs           -- @generated: event codec
danwa-core/src/Danwa/Conversation/Generated/EventStream.hs     -- @generated: validated stream definition
danwa-core/src/Danwa/Conversation/Generated/Projection.hs      -- @generated: inline projection wiring
danwa-core/src/Danwa/Conversation/Generated/Harness.hs         -- @generated: harness assertions
danwa-core/src/Danwa/Conversation/Holes.hs                     -- hand: keiki transducer + applyConversations fold
danwa-core/src/Danwa/Conversation/ReadModel.hs                 -- hand: rows, hasql codecs, statements
danwa-api/src/Danwa/Conversation/Api.hs                        -- hand: NamedRoutes + DTOs
danwa-server/src/Danwa/Conversation/Handler.hs                 -- hand: route handlers
danwa-workers/src/Danwa/Conversation/Worker.hs                 -- hand: projection worker
danwa-workers/src/Danwa/Conversation/AgentSummaryWorker.hs     -- hand: a Conversation-side process (pgmq-backed)
danwa-workers/test/Danwa/Conversation/WorkerSpec.hs            -- hand: worker spec (tests :: TestTree)
danwa-workers/test/Danwa/Conversation/AgentSummaryWorkerSpec.hs -- hand: process spec
```

Walk the listing in prose: which modules the scaffolder regenerates on every run, which two core modules a developer actually edits day-to-day (`Holes`, `ReadModel`), how a command flows (Api → Handler → validated stream from `Generated.EventStream` → transducer in `Holes`) and how an event flows (kiroku subscription → `Worker` → `applyConversations` in `Holes` → table declared by `ReadModel`). End with the replication recipe: "to add concept `<New>`, declare it in `domain/<service>.keiro`, re-scaffold, then create by hand exactly: `Holes` additions, `ReadModel`, `Api`, `Handler`, `Worker`, `WorkerSpec`."

**`mori.dhall` registration.** Append the following eight entries to the END of the existing `docs` list (after the last `keiki-*` entry, before the closing bracket), preserving the file's four-space/comma-leading style and reordering nothing:

```dhall
, Schema.DocRef::{
  , key = "architecture-overview"
  , kind = Schema.DocKind.Guide
  , audience = Schema.DocAudience.Module
  , description = Some
      "Index of the keiro service architecture standard: packages, vertical slices, tests, scaffolding; start here"
  , location = Schema.DocLocation.LocalFile "architecture/README.md"
  }
, Schema.DocRef::{
  , key = "architecture-service-packages"
  , kind = Schema.DocKind.BestPractice
  , audience = Schema.DocAudience.Module
  , description = Some
      "The six-package split standard for deployed keiro services and its dependency rules"
  , location = Schema.DocLocation.LocalFile "architecture/service-packages.md"
  }
, Schema.DocRef::{
  , key = "architecture-vertical-slice-modules"
  , kind = Schema.DocKind.BestPractice
  , audience = Schema.DocAudience.Module
  , description = Some
      "The authoritative Generated.* + Holes vertical-slice module convention per domain concept"
  , location = Schema.DocLocation.LocalFile "architecture/vertical-slice-modules.md"
  }
, Schema.DocRef::{
  , key = "architecture-cross-cutting-modules"
  , kind = Schema.DocKind.BestPractice
  , audience = Schema.DocAudience.Module
  , description = Some
      "The closed allowlist of technical-layer modules and the domain-vs-technology division heuristic"
  , location = Schema.DocLocation.LocalFile "architecture/cross-cutting-modules.md"
  }
, Schema.DocRef::{
  , key = "architecture-extended-node-verticals"
  , kind = Schema.DocKind.Pattern
  , audience = Schema.DocAudience.Module
  , description = Some
      "Where read models, process managers, workflows, routers, publishers, inboxes, queues, and contracts sit in the slice"
  , location = Schema.DocLocation.LocalFile "architecture/extended-node-verticals.md"
  }
, Schema.DocRef::{
  , key = "architecture-spec-and-scaffolding"
  , kind = Schema.DocKind.BestPractice
  , audience = Schema.DocAudience.Module
  , description = Some
      "Placing the .keiro spec at domain/<service>.keiro and running keiro-dsl scaffold idempotently"
  , location = Schema.DocLocation.LocalFile "architecture/spec-and-scaffolding.md"
  }
, Schema.DocRef::{
  , key = "architecture-test-layout"
  , kind = Schema.DocKind.BestPractice
  , audience = Schema.DocAudience.Module
  , description = Some
      "The per-package test-suite standard: four core suites, vertical Spec modules, migrations test-support"
  , location = Schema.DocLocation.LocalFile "architecture/test-layout.md"
  }
, Schema.DocRef::{
  , key = "architecture-worked-example-conversation"
  , kind = Schema.DocKind.Pattern
  , audience = Schema.DocAudience.Module
  , description = Some
      "Complete file listing of danwa's Conversation slice across all six packages"
  , location = Schema.DocLocation.LocalFile "architecture/worked-example-conversation.md"
  }
```

**ADR seed.** Create `docs/adr/<N>-vertical-slice-generated-holes-convention.md` (`<N>` = next free number in `docs/adr/` at implementation time) recording the two durable rulings (authoritative `Generated.*` + `Holes` convention with the rejected flat layout and rejected legacy parallel modules; six-package split as the fleet standard with the teaching-monolith exception), each with its rationale and the evidence paths, and pointing at `architecture/vertical-slice-modules.md` as the normative text. Keep it short — the ADR records the decision and why; the doc area carries the rules.

Finally, run the whole Validation and Acceptance section, tick Progress, update the MasterPlan registry row (EP-6 → Complete) and its Progress checkbox, and write the Outcomes & Retrospective entry.


## Concrete Steps

All commands run from `/Users/shinzui/Keikaku/bokuno/keiro-runtime-patterns` unless stated otherwise. Commit after each milestone with conventional-commit messages on the current branch (no feature branch), e.g. `docs(architecture): add package split and vertical slice standard` — but never commit the external checkouts, which this plan only reads.

1. Create the doc area:

   ```bash
   mkdir -p architecture
   ```

2. Write the Milestone 1 docs (`README.md`, `service-packages.md`, `vertical-slice-modules.md`, `cross-cutting-modules.md`) per Plan of Work, then verify every danwa path claimed by the core standard:

   ```bash
   DANWA=/Users/shinzui/Keikaku/bokuno/danwa
   for f in \
     cabal.project domain/danwa.keiro \
     danwa-core/src/Danwa/Prelude.hs danwa-core/src/Danwa/App/Config.hs \
     danwa-core/src/Danwa/Postgres/Pool.hs danwa-core/src/Danwa/Postgres/Runner.hs \
     danwa-core/src/Danwa/Diagrams.hs danwa-core/app/Diagrams.hs \
     danwa-core/src/Danwa/Integration/AddressedMessage.hs \
     danwa-api/src/Danwa/Api.hs danwa-server/src/Danwa/Server/App.hs \
     danwa-server/src/Danwa/Server/Boot.hs danwa-server/src/Danwa/Server/Config.hs \
     danwa-server/src/Danwa/Server/Seam.hs \
     danwa-workers/src/Danwa/Workers/Config.hs danwa-workers/src/Danwa/Workers/Registry.hs \
     danwa-workers/src/Danwa/Workers/Subscription.hs \
     danwa-workers/src/Danwa/Integration/AddressedMessageWorker.hs \
     danwa-workers/src/Danwa/Integration/OutboxPublisherWorker.hs \
     danwa-migrations/src/Danwa/Migrations.hs danwa-migrations/src/Danwa/Migrations/New.hs \
     danwa-migrations/test-support/Danwa/Migrations/TestSupport.hs \
     danwa-client/src/Danwa/Client.hs
   do test -f "$DANWA/$f" || echo "MISSING $f"; done; echo CHECKED
   ```

   Expected output: exactly `CHECKED` and no `MISSING` lines. Also confirm the banner text and the stale-prose claim before citing them:

   ```bash
   grep -c '@generated by keiro-dsl; do not edit' \
     "$DANWA/danwa-core/src/Danwa/Conversation/Generated/Domain.hs"   # expect >= 1
   grep -rL '@generated' "$DANWA/danwa-core/src/Danwa/Conversation/" # expect only Holes.hs and ReadModel.hs
   ```

3. Write the Milestone 2 docs (`extended-node-verticals.md`, `spec-and-scaffolding.md`, `test-layout.md`), then verify the jitsurei evidence paths:

   ```bash
   JIT=/Users/shinzui/Keikaku/bokuno/keiro-runtime-jitsurei/services/hospital-capacity
   for f in \
     spec/hospital-capacity.keiro \
     src/HospitalCapacity/Hospital_readiness/Generated/ReadModel.hs \
     src/HospitalCapacity/Hospital_readiness/Generated/ReadModelHarness.hs \
     src/HospitalCapacity/Hospital_readiness/Generated/ReadModelTable.hs \
     src/HospitalCapacity/Hospital_readiness/ReadModelHoles.hs \
     src/HospitalCapacity/HospitalSurge/Generated/Process.hs \
     src/HospitalCapacity/HospitalSurge/Generated/ProcessHarness.hs \
     src/HospitalCapacity/HospitalSurge/ProcessHoles.hs \
     src/HospitalCapacity/HospitalTransferReservation/Generated/WorkflowFacts.hs \
     src/HospitalCapacity/HospitalTransferReservation/Generated/WorkflowRuntime.hs \
     src/HospitalCapacity/TransferNeedRouter/Generated/Router.hs \
     src/HospitalCapacity/TransferNeedRouter/RouterHoles.hs \
     src/HospitalCapacity/HospitalPublisher/Generated/Publisher.hs \
     src/HospitalCapacity/IncidentInbox/Generated/Inbox.hs \
     src/HospitalCapacity/Reservation_work/Generated/Queue.hs \
     src/HospitalCapacity/Reservation_work/Generated/QueuePolicy.hs \
     src/HospitalCapacity/Emergency/Generated/Contract.hs \
     src/HospitalCapacity/Integration/Contracts.hs
   do test -f "$JIT/$f" || echo "MISSING $f"; done; echo CHECKED
   ```

   Expected: `CHECKED`, no `MISSING`. Confirm the six suite names: `grep -c '^test-suite' "$JIT"/*.cabal` should report 6.

4. Write `architecture/worked-example-conversation.md`, then run the Conversation-slice loop from Validation and Acceptance (step V1 below) — it must pass before the doc is committed.

5. Append the DocRef block to `mori.dhall` exactly as given in Plan of Work, then type-check and list:

   ```bash
   dhall type --quiet --file mori.dhall && echo DHALL-OK
   mori registry docs shinzui/keiro-runtime-patterns
   ```

   Expected: `DHALL-OK` (the first command prints nothing on success with `--quiet`; a syntax or type error prints a Dhall error instead), and the mori listing now includes the eight `architecture-*` keys alongside the seven `keiki-*` keys.

6. Create `docs/adr/` and the ADR file per Milestone 3, cross-check every relative link in the eight docs:

   ```bash
   cd architecture
   grep -oh ']([^)#]*\.md' *.md | sed 's/^](//' | sort -u \
     | while read -r p; do test -f "$p" || echo "DANGLING $p"; done; echo LINKS-CHECKED
   ```

   Expected: `LINKS-CHECKED` with `DANGLING` lines only for sanctioned forward links into `../keiro/` or `../messaging/` (record any such lines in Progress; everything else must resolve).

7. Update this plan's Progress, Surprises & Discoveries, Decision Log, and Outcomes & Retrospective; flip the EP-6 row to Complete in `docs/masterplans/1-keiro-runtime-standards-docs-and-seihou-blueprints.md` and tick its EP-6 Progress line; commit.


## Validation and Acceptance

V1 — The standard is grounded (run after Milestone 3, from anywhere): every module the worked example names for the Conversation slice exists in danwa.

```bash
DANWA=/Users/shinzui/Keikaku/bokuno/danwa
for f in \
  domain/danwa.keiro \
  danwa-core/src/Danwa/Conversation/Generated/Domain.hs \
  danwa-core/src/Danwa/Conversation/Generated/Codec.hs \
  danwa-core/src/Danwa/Conversation/Generated/EventStream.hs \
  danwa-core/src/Danwa/Conversation/Generated/Projection.hs \
  danwa-core/src/Danwa/Conversation/Generated/Harness.hs \
  danwa-core/src/Danwa/Conversation/Holes.hs \
  danwa-core/src/Danwa/Conversation/ReadModel.hs \
  danwa-api/src/Danwa/Conversation/Api.hs \
  danwa-server/src/Danwa/Conversation/Handler.hs \
  danwa-workers/src/Danwa/Conversation/Worker.hs \
  danwa-workers/src/Danwa/Conversation/AgentSummaryWorker.hs \
  danwa-workers/test/Danwa/Conversation/WorkerSpec.hs \
  danwa-workers/test/Danwa/Conversation/AgentSummaryWorkerSpec.hs
do test -f "$DANWA/$f" || echo "MISSING $f"; done; echo SLICE-OK
```

Expected output is the single line `SLICE-OK`. Any `MISSING` line means the doc names a module the reference code does not ship — fix the doc, not the reference.

V2 — The registry is valid and complete: `dhall type --quiet --file mori.dhall` exits 0 with no output; `grep -c 'architecture-' mori.dhall` reports 8; `mori registry docs shinzui/keiro-runtime-patterns` lists all eight new entries.

V3 — Novice acceptance (the plan's headline behavior): give a reader who has never seen a keiro service ONLY the `architecture/` docs and this instruction: "Lay out the repository tree for a new service `ticket` with one aggregate `Ticket` (with a projection), one first-class read model `open_tickets`, and one outbound integration event." Their answer must match this expected shape (packages and per-concept modules; ancillary files like cabal metadata omitted):

```text
ticket/
├── domain/ticket.keiro                       (context ticket, layout collocated)
├── ticket-core/src/Ticket/
│   ├── Prelude.hs  App/Config.hs  Postgres/{Pool,Runner}.hs  Diagrams.hs
│   ├── Ticket/Generated/{Domain,Codec,EventStream,Projection,Harness}.hs
│   ├── Ticket/Holes.hs  Ticket/ReadModel.hs
│   ├── Open_tickets/Generated/{ReadModel,ReadModelHarness,ReadModelTable}.hs
│   ├── Open_tickets/ReadModelHoles.hs
│   └── Integration/<Contract>.hs
├── ticket-core/{test,test-domain,test-diagrams,test-postgres}/
├── ticket-api/src/Ticket/{Api.hs, Ticket/Api.hs}
├── ticket-server/src/Ticket/{Server/{App,Boot,Config,Seam}.hs, Ticket/Handler.hs}
├── ticket-workers/src/Ticket/{Workers/{Config,Registry,Subscription}.hs,
│                              Ticket/Worker.hs, Integration/{<Contract>Worker,OutboxPublisherWorker}.hs}
├── ticket-workers/test/Ticket/Ticket/WorkerSpec.hs  (+ Main.hs aggregator)
├── ticket-migrations/{src/Ticket/Migrations.hs, src/Ticket/Migrations/New.hs,
│                      test-support/, test/}
└── ticket-client/src/Ticket/Client.hs
```

Acceptance is met when the reader's tree matches on every load-bearing point: six packages with the standard names, the generated ring + `Holes` + `ReadModel` for the aggregate, snake_case read-model vertical with `ReadModelHoles`, integration as a vertical, the four core test suites, the `test-support` sublibrary, and no technical-layer module outside the allowlist. Record the exercise (who/when/result) in this plan's Progress. If no second person is available, a fresh agent session given only the `architecture/` directory is an acceptable stand-in reader.

V4 — Rulings are present and unambiguous: `grep -l 'teaching' architecture/*.md` matches at least the vertical-slice and extended-node docs (the jitsurei legacy-modules warning), and `architecture/vertical-slice-modules.md` contains an explicit statement that the flat layout described by danwa's prose is rejected. A reader must be able to quote each ruling as a single sentence.


## Idempotence and Recovery

Every step is safe to repeat. Rewriting a doc file overwrites it wholesale; the verification loops and `dhall type` are read-only; `mkdir -p` is a no-op when the directory exists. The one append-style edit is `mori.dhall`: before appending, check `grep -c 'architecture-' mori.dhall` — if it already reports 8, the block is in and must not be appended again; if it reports something between 1 and 7, a partial append happened — delete the partial `architecture-*` entries (they are contiguous at the tail of the `docs` list) and re-append the full block from Plan of Work, then re-run `dhall type`. If `dhall type` fails after an edit, the error message names the offending line; the fastest recovery is `git diff mori.dhall` to inspect the appended block and fix the syntax (commas lead each field; every entry is `Schema.DocRef::{ ... }`). Nothing in this plan mutates the danwa or keiro-runtime-jitsurei checkouts, so there is no external state to roll back; if a doc was committed with a wrong path claim, fix the doc and re-run V1 — the reference repos are the invariant.


## Interfaces and Dependencies

This plan produces documentation and registry entries, not code, so its "interfaces" are the file contract and the registry shape.

Files that must exist at the end (all repository-relative to `/Users/shinzui/Keikaku/bokuno/keiro-runtime-patterns`): `architecture/README.md`, `architecture/service-packages.md`, `architecture/vertical-slice-modules.md`, `architecture/cross-cutting-modules.md`, `architecture/extended-node-verticals.md`, `architecture/spec-and-scaffolding.md`, `architecture/test-layout.md`, `architecture/worked-example-conversation.md`, `docs/adr/<N>-vertical-slice-generated-holes-convention.md` (next free ADR number), plus the eight-entry DocRef block in `mori.dhall`.

Registry interface: `mori.dhall` uses the pinned schema import already present at the top of the file (`mori-schema` commit `026ae74331e5c516542af1dd96f041c658ed4621` with its sha256 — do not change the pin in this plan). Each entry is a `Schema.DocRef::{ key, kind, audience, description, location }` with `kind` one of `Schema.DocKind.{Guide,BestPractice,Pattern}`, `audience = Schema.DocAudience.Module`, and `location = Schema.DocLocation.LocalFile "<repo-relative path>"`. Keys are exactly the eight `architecture-*` strings listed in Plan of Work and must be unique file-wide.

Ground-truth inputs (read-only): `/Users/shinzui/Keikaku/bokuno/danwa` (package split, slice convention, allowlist, test baseline, worked example, scaffold workflow in `justfile`, the stale-prose evidence in `danwa-core/danwa-core.cabal` and `docs/masterplans/1-bootstrap-danwa-event-sourced-conversation-substrate.md`) and `/Users/shinzui/Keikaku/bokuno/keiro-runtime-jitsurei` (extended node placements and six-suite superset under `services/hospital-capacity/`, monolith counterexample). If either checkout has moved on when this plan is implemented, re-verify with the loops before writing — the docs must describe what the code ships, and any newly discovered divergence goes in Surprises & Discoveries with a fresh ruling in the Decision Log.

Tools required: `dhall` (type-checking; the schema import resolves from cache or network), `mori` (listing registered docs), standard shell utilities, `git`. No Haskell build is required — nothing here compiles.

Related plans (coordination only, no file overlap): EP-4 (`keiro/` doc area) and EP-5 (`messaging/` doc area) are soft dependencies — this plan's docs cross-link forward to them for runtime and messaging semantics and never restate them; EP-3 fixes danwa's stale prose at its source (this plan only rules against it); EP-9 consumes this standard verbatim for the `haskell-keiro-service` blueprint and is blocked until this plan is Complete, so flipping the MasterPlan registry row is part of Milestone 3, not an afterthought.
