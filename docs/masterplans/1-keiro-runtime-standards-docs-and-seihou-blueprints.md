---
id: 1
slug: keiro-runtime-standards-docs-and-seihou-blueprints
title: "Keiro runtime standards, docs, and seihou blueprints"
kind: master-plan
created_at: 2026-07-22T14:40:51Z
intention: intention_01ky5agv9gehqa8dbw03cdcpwv
---

# Keiro runtime standards, docs, and seihou blueprints

This MasterPlan is a living document. The sections Progress, Surprises & Discoveries,
Decision Log, and Outcomes & Retrospective must be kept up to date as work proceeds.
If durable project context changes, update or create ADRs in docs/adr/ in the same change.


## Vision & Scope

The keiro runtime — an event-sourced microservice stack for Haskell built from keiki (typed state-machine transducers), kiroku (PostgreSQL event store), keiro + keiro-dsl (the framework and its typed specification toolchain), shibuya and its adapters (supervised queue processing over pgmq, Kafka, and kiroku subscriptions), pgmq-hs (Postgres queue client), pg-migrate (compile-time migration plans), relay-pagination (cursor pagination), and settei (provenance-aware configuration) — reached API stability with the keiro 0.2/0.3 release train of July 2026. About ten new microservices will be written on this stack, another ten existing services will be refactored onto it, and several open-source projects that use keiro are being released. All of that work needs a single, accurate, prescriptive body of standards to build on.

When this initiative is complete: the `keiro-runtime-patterns` repository holds current, prescriptive best-practice docs for every runtime package (the existing keiki docs rewritten for keiki 0.2, plus new doc areas for kiroku, migrations, the keiro runtime, the keiro-dsl decision, messaging/process managers/integration events, the DDD vertical module structure, and settei/Kubernetes operations), each registered in `mori.dhall` so developers and agents can discover them; the servant API standards in `/Users/shinzui/Keikaku/bokuno/haskell-jitsurei/api` are completed with the missing OpenTelemetry integration, request logging, Relay pagination, and Kubernetes health-probe guidance; the stale statements the research pass catalogued in the keiro, kiroku, settei, danwa, and haskell-jitsurei repos are corrected at their source; and the two seihou blueprints (`haskell-keiro-service` for bootstrapping and `migrate-keiro-stack` for refactoring) encode the standards so new and refactored services start from the same solid foundation.

Process managers and integration events are first-class concerns throughout — they are the connective tissue between the twenty services — and every standard treats them as core, not as an appendix.

Explicitly excluded: the `kioku` agent-memory library (the original request said "kioku" but meant kiroku, the event store — confirmed 2026-07-22); rewriting the `keiro-runtime-docs` Fumadocs website (a separate, product-organized documentation site — this initiative's terse pattern corpus complements it and may be cross-linked from it, but modernizing its 514 MDX pages is separate work); and the actual writing or refactoring of the twenty services (the blueprints and docs produced here enable that downstream work but do not perform it).


## Decomposition Strategy

The initiative decomposes by functional concern into nine child plans grouped into four phases (waves). The guiding principles were: each plan must produce an independently verifiable artifact (a set of docs that can be checked against the package source it describes, a blueprint that can be applied to a scratch repo); cross-plan coupling is minimized by giving each plan its own documentation directory and its own `mori.dhall` DocRef entries; and natural knowledge ordering is respected — the docs for the foundation packages (keiki, kiroku, pg-migrate) inform the runtime and messaging docs, which inform the structure standard, which the blueprints scaffold.

Phases group the plans into implementation waves because nine plans exceed the recommended two-to-seven span: Phase 1 (Foundations) covers the bedrock packages and the quick stale-doc remediation, all independent of each other; Phase 2 (Runtime & communication) covers the keiro runtime/DSL and the messaging/process-manager/integration-event standards; Phase 3 (Service shape) covers the vertical module structure, the servant API layer, and configuration/Kubernetes operations; Phase 4 (Blueprints) encodes everything into seihou blueprints.

Alternatives considered: one plan per package (twelve or more plans) was rejected as too granular — the shibuya adapters, pgmq-hs, and keiro-pgmq are only comprehensible as one messaging story, and kiroku's migration component only makes sense next to pg-migrate. A three-plan decomposition (docs, structure, blueprints) was rejected because a single "docs" plan would touch eight packages across five repositories with more than five milestones — exactly the unwieldy shape the ExecPlan specification warns against. Folding the stale-doc fixes into each package's doc plan was rejected because the fixes live in *other* repositories (keiro, kiroku, settei, danwa, haskell-jitsurei) and are all small, mechanical, and precisely catalogued — one plan can land them quickly without blocking the doc rewrites.

`docs/adr/` did not exist in this repository when this MasterPlan was created — there are no relevant ADRs. This initiative will seed the first ones (see Integration Points for the candidates).

Research grounding: nine parallel research reports were produced during planning (keiro, keiki + stale-doc audit, kiroku, pg-migrate + cohort transition story, shibuya + adapters + pgmq-hs, danwa + keiro-runtime-jitsurei structure, docs corpus + seihou anatomy, relay-pagination, settei + Kubernetes). Their findings are embedded in the child plans; each child plan is self-contained per the ExecPlan specification.


## Exec-Plan Registry

| # | Title | Path | Hard Deps | Soft Deps | Status |
|---|-------|------|-----------|-----------|--------|
| 1 | Rewrite the keiki transducer docs for keiki 0.2 | docs/plans/1-rewrite-the-keiki-transducer-docs-for-keiki-0-2.md | None | None | Complete |
| 2 | Document kiroku event store and pg-migrate standards | docs/plans/2-document-kiroku-event-store-and-pg-migrate-standards.md | None | None | Complete |
| 3 | Remediate stale docs across the keiro ecosystem repos | docs/plans/3-remediate-stale-docs-across-the-keiro-ecosystem-repos.md | None | None | Complete |
| 4 | Document the keiro runtime core and keiro-dsl adoption guidance | docs/plans/4-document-the-keiro-runtime-core-and-keiro-dsl-adoption-guidance.md | None | EP-1, EP-2 | Complete |
| 5 | Document process managers, integration events, and messaging standards | docs/plans/5-document-process-managers-integration-events-and-messaging-standards.md | None | EP-4 | Complete |
| 6 | Codify the DDD vertical module structure standard | docs/plans/6-codify-the-ddd-vertical-module-structure-standard.md | None | EP-4, EP-5 | Complete |
| 7 | Complete the servant API standards in haskell-jitsurei | docs/plans/7-complete-the-servant-api-standards-in-haskell-jitsurei.md | None | None | Not Started |
| 8 | Document settei configuration and Kubernetes operational standards | docs/plans/8-document-settei-configuration-and-kubernetes-operational-standards.md | None | EP-7 | Not Started |
| 9 | Refresh the seihou blueprints to encode the standards | docs/plans/9-refresh-the-seihou-blueprints-to-encode-the-standards.md | EP-6 | EP-1, EP-2, EP-4, EP-5, EP-7, EP-8 | Not Started |

Status values: Not Started, In Progress, Complete, Cancelled.
Hard Deps and Soft Deps reference other rows by their # prefix (e.g., EP-1, EP-3).

Phases: Phase 1 (Foundations) = EP-1, EP-2, EP-3. Phase 2 (Runtime & communication) = EP-4, EP-5. Phase 3 (Service shape) = EP-6, EP-7, EP-8. Phase 4 (Blueprints) = EP-9.


## Dependency Graph

There is exactly one hard dependency: EP-9 (blueprints) cannot begin until EP-6 (vertical module structure standard) is complete, because the `haskell-keiro-service` blueprint's entire output is a scaffold of that structure — writing the blueprint against an unfinished structure standard would bake in a contract that might still change.

Everything else is soft ordering that improves quality but blocks nothing. EP-4 benefits from EP-1 and EP-2 because the runtime docs cross-reference the keiki validation surface (keiro's `mkEventStream` rejects on any keiki replay warning) and the kiroku store semantics; if EP-4 runs first, it leaves relative links to doc paths the earlier plans will create. EP-5 benefits from EP-4 for shared terminology (validated event stream, the two-schema arrangement) and doc-directory conventions. EP-6 benefits from EP-4 and EP-5 because the structure standard names the module kinds those plans document (Generated ring, Holes, worker modules, integration slices). EP-8 benefits from EP-7 because the Kubernetes probe guidance in the API docs and the settei `--check-config` rollout gate reference each other.

Parallelism: EP-1, EP-2, and EP-3 can run fully in parallel (different files, different repos). EP-4 and EP-5 can run in parallel with each other if the shared-terminology integration point below is respected. EP-6, EP-7, and EP-8 can run in parallel (different repos/directories). EP-9 runs alone in Phase 4.


## Integration Points

**1. `mori.dhall` DocRef registrations in this repository.** Plans EP-1, EP-2, EP-4, EP-5, EP-6, and EP-8 all add `Schema.DocRef` entries to `/Users/shinzui/Keikaku/bokuno/keiro-runtime-patterns/mori.dhall`. The MasterPlan owns the directory layout so the plans do not collide: EP-1 owns `keiki/`, EP-2 owns `kiroku/` and `migrations/`, EP-4 owns `keiro/`, EP-5 owns `messaging/`, EP-6 owns `architecture/`, EP-8 owns `config/`. DocRef `key` values follow `<directory>-<file-slug>` (matching the existing `keiki-*` keys). Each plan appends only its own entries and never reorders existing ones; because Dhall lists are order-insensitive here, concurrent edits merge trivially as long as each plan touches only its own block. EP-2 also updates the `dependencies` list to add `shinzui/pgmq-hs`, `shinzui/pg-migrate`, and the adapter projects as they become documented.

**2. Documentation style contract.** All doc plans follow the established haskell-jitsurei corpus style: no YAML frontmatter; a single `#` H1 title followed by a bold one-line tagline and a one-paragraph scope statement; prescriptive rule-first prose; code samples with language tags, using `-- CORRECT / -- WRONG` or `-- Before / -- After` contrast pairs; relative cross-links between docs; a trailing "Related Patterns" section. EP-1 applies it first in this repository; later plans copy EP-1's realized shape rather than re-deriving it.

**3. The vertical-slice module convention.** EP-6 owns the standard: the authoritative convention is the one danwa's *code* ships (keiro-dsl `Generated.*` modules plus a single hand-owned `Holes.hs` per concept, colocated by domain concept across packages), not the contradictory prose in danwa's cabal description and old masterplan. EP-4 (DSL layout flags), EP-5 (where worker/integration modules sit in the slice), and EP-9 (the blueprint scaffold) consume it and must cite EP-6's doc rather than restating the rules. Candidate ADR.

**4. Shared terminology.** EP-4 defines the core glossary (validated event stream, the two-schema arrangement — kiroku store schema for LISTEN/NOTIFY versus the dedicated `keiro` schema for framework tables, snapshot advisory-ness, `CommandAmbiguous` is never benign). EP-5 defines the messaging glossary (domain event versus integration event, outbox/inbox, ack decisions, at-least-once + idempotency). Later plans link, never redefine.

**5. haskell-jitsurei repository edits.** EP-7 adds new docs and DocRefs to `/Users/shinzui/Keikaku/bokuno/haskell-jitsurei`; EP-3 fixes only the mori-schema pin drift in `mori/tech-radar.dhall` there; EP-8 adds a supersession note to `cli/hierarchical-config.md` pointing at the settei standard. The three plans touch disjoint files.

**6. Seihou blueprint registries.** EP-9 owns all edits to `/Users/shinzui/Keikaku/bokuno/seihou-modules` and `/Users/shinzui/Keikaku/bokuno/agent-seihou`, including version bumps synced via `seihou registry sync-versions`. Blueprint reference files under `files/` must be regenerated from (or cite) the docs the earlier plans produce, so the blueprint and the docs cannot drift silently.

**7. ADR numbering.** Several child plans seed `docs/adr/` (EP-5 the transport-selection ADR, EP-6 the vertical-slice-convention ADR, EP-8 the settei-as-fleet-standard ADR). ADR numbers are allocated at implementation time — take the next free number in `docs/adr/` when the ADR is actually written; no plan may hard-code a number.

Cross-plan decisions that should become ADRs during implementation: the role boundary between the three documentation repos (keiro-runtime-patterns = terse agent-facing patterns; keiro-runtime-docs = product website; haskell-jitsurei = general Haskell standards); the authoritative `Generated.*` + `Holes` module convention and the rejection of the earlier flat layout; the pgmq-versus-Kafka transport selection rationale; settei as the fleet configuration standard (superseding raw Dhall `FromDhall` wiring as used in danwa); and the deliberate exclusion of kioku from the runtime standards.


## Progress

- [x] EP-1: Stale keiki docs corrected per the audit (per-file fixes for README, transducer-best-practices, build-time-validation, json-event-codecs)
- [x] EP-1: New keiki 0.2 capability docs written (structured replay, new validation checks, noEmit intent, event-schema evolution, checked composition)
- [x] EP-1: Process-manager framing removed from keiki docs and redirected; mori.dhall registrations complete (including the missing diagram-docs entry)
- [x] EP-2: Kiroku event-store best-practice docs written (append/read/subscription/consumer-group/operational invariants)
- [x] EP-2: pg-migrate standards written (component authoring, service migrations package, cohort upgrade paths) and registered
- [x] EP-3: Stale statements fixed in keiro repo (why-keiro §7.4, package README status, Keiro.version)
- [x] EP-3: Stale statements fixed in kiroku, settei, danwa, and haskell-jitsurei repos
- [x] EP-4: Keiro runtime core docs written (assembly, command cycle, read models, workflows, telemetry)
- [x] EP-4: keiro-dsl adoption guidance written (when to use, when to skip, firewall and holes, evolution gate)
- [x] EP-5: Process manager and timer standards written
- [x] EP-5: Integration event standards written (contract, outbox, inbox, versioning)
- [x] EP-5: Messaging transport standards written (shibuya semantics, adapter selection matrix, keiro-pgmq jobs)
- [x] EP-6: Vertical module structure standard written and reconciled against danwa and keiro-runtime-jitsurei
- [ ] EP-7: OpenTelemetry and request-logging API docs written in haskell-jitsurei
- [ ] EP-7: relay-pagination standard and Kubernetes probe guidance written in haskell-jitsurei
- [ ] EP-8: Settei configuration standard written (layering, secrets, bindings)
- [ ] EP-8: Kubernetes operational standard written (overlays, downward API, check-config gate, no-reload rollouts)
- [ ] EP-9: haskell-keiro-service blueprint refreshed to scaffold the standards
- [ ] EP-9: migrate-keiro-stack blueprint refreshed for the current cohort; registries version-synced


## Surprises & Discoveries

Findings from the planning research pass that shaped the decomposition (evidence lives in the child plans):

- kioku and kiroku are two different packages (agent memory versus event store); the initiative covers kiroku only, per user confirmation on 2026-07-22.
- keiki has no process-manager abstraction at all — the stale keiki docs present keiro's `ProcessManager` as if it were keiki API. The real abstraction lives in `keiro/src/Keiro/ProcessManager.hs`; keiki models orchestrators as plain transducers wired with `compose`/`feedback1`.
- danwa (the DDD reference) contradicts its own prose: the shipped code uses `Generated.*` + `Holes.hs`, while its cabal description and masterplan describe an abandoned flat layout. keiro-runtime-jitsurei demonstrates the richer DSL node vocabulary, pg-migrate, and real OpenTelemetry that danwa lacks (danwa is still on codd with a noop tracer).
- settei has no ecosystem consumers yet — danwa uses raw Dhall — so the configuration standard documents an intended adoption surface, with `settei-example-service` as the canonical pattern.
- Both target blueprints already exist (`haskell-keiro-service` 0.1.0, `migrate-keiro-stack` 0.1.1); EP-9 is a refresh, not greenfield.
- A well-typed `mori.dhall` edit does not refresh Mori's indexed registry projection. EP-1
  initially left `mori registry docs shinzui/keiro-runtime-patterns` showing seven entries;
  the idempotent `mori register --local --path
  /Users/shinzui/Keikaku/bokuno/keiro-runtime-patterns --no-seihou-discovery` refresh made all
  twelve visible. EP-2, EP-4, EP-5, EP-6, and EP-8 must repeat that acceptance step after
  adding their DocRefs.
- EP-2 found that `Kiroku.Metrics.Prometheus` calls the global-position-backed
  `kiroku_events_appended_total` “gap-free,” while the public `GlobalPosition` contract
  explicitly says positions need not be dense. The pattern corpus follows the public type
  contract; EP-3 corrected the stale upstream HELP text so later observability docs do not
  inherit the contradiction.
- EP-3 verified that Settei 0.2.0.0 is already represented by an annotated upstream tag
  and eight public Hackage packages, even though its README claimed otherwise. EP-3 fixed
  the source documents and updated EP-8's planning observation so the configuration
  standard starts from the published 0.2.0.0 baseline.
- EP-4 found three runtime contracts narrower than the planning draft implied. Hand-authored
  service wiring should handle `mkEventStream` warnings explicitly; snapshots are disposable
  only while retained history can still hydrate the stream; and workflow GC is optional
  retention work while resume, timers, and external signals are capability-specific progress
  mechanisms. EP-5 and later plans must use these qualified glossary definitions.
- EP-4 also found that `kirokuEventBridge` counts only terminal
  `KirokuEventSubscriptionDeadLettered` events before calling its delegate synchronously; it
  is not a generic store-retry observer. Messaging telemetry in EP-5 must preserve that scope.
- EP-5 found that three planning guarantees were wider than the released APIs. Process-manager
  state plus timers commit before separately transacted target dispatches, and timer ids are
  caller-owned. `IntegrationProducer` is a mapper/enqueue primitive rather than a
  checkpoint-owning runner, and it mints a new message id per call. Shibuya 0.8.0.1 always
  finalizes a thrown handler as `AckRetry 0`, while the current PGMQ adapter transactionally
  transfers configured DLQ messages; older adapter and keiro-pgmq prose still describe the
  superseded behavior. EP-6 and EP-9 must consume the corrected messaging docs.
- EP-6 confirmed that keiro-dsl reports modules a changed spec no longer emits but never deletes
  them. The structure standard therefore makes stale-path review and deliberate removal part of
  every re-scaffold. EP-9 must encode that cleanup instruction alongside the generated/Holes
  firewall rather than implying regeneration prunes the tree.


## Decision Log

- Decision: Cover kiroku (the event store), not kioku (agent memory); treat "kioku" in the original request as a typo.
  Rationale: kiroku is foundational to every service; the user confirmed via the scope question. kioku remains out of scope.
  Date: 2026-07-22

- Decision: Give process managers and integration events their own child plan (EP-5) combined with the messaging transports, rather than folding them into the runtime plan.
  Rationale: the user identified them as the core of the microservice fleet; they span keiro (PM/outbox/inbox), shibuya, both queue adapters, and pgmq-hs, which is one coherent communication story and would bloat EP-4 beyond balance.
  Date: 2026-07-22

- Decision: Add a dedicated stale-docs remediation plan (EP-3) covering the upstream repos.
  Rationale: explicit user request ("create plans to fix any stale docs that you encounter"); the fixes are small, precisely catalogued, and live outside this repo, so batching them keeps the doc-rewrite plans focused.
  Date: 2026-07-22

- Decision: Add settei and Kubernetes operational standards as EP-8.
  Rationale: user added settei and the Kubernetes deployment context mid-planning; settei ships a complete K8s story (mounted sources, check-config gate, no-reload) that the fleet standard must encode.
  Date: 2026-07-22

- Decision: Nine plans organized into four phases; the only hard dependency is EP-9 on EP-6.
  Rationale: nine exceeds the recommended seven, so phases group them into waves; all other orderings are soft because docs can cross-link forward without compiling against each other, but the blueprint physically scaffolds the structure standard and must not precede it.
  Date: 2026-07-22

- Decision: All child plans live in this repository's `docs/plans/`, including the ones whose work happens in haskell-jitsurei or the seihou registries.
  Rationale: this repo is the coordination home for the keiro-runtime standards initiative; plans name absolute paths for cross-repo work. Commits in other repos still carry the MasterPlan/ExecPlan trailers pointing at this repo's plan files.
  Date: 2026-07-22

- Decision: The settei standard (EP-8) is written as the fleet-wide adoption target for both microservices and CLIs, explicitly superseding the raw Dhall `FromDhall` wiring used in danwa and the layered-Dhall CLI pattern documented in haskell-jitsurei's `cli/hierarchical-config.md` (which gets a supersession note).
  Rationale: user confirmed settei was built precisely to solve the complex microservice config requirement and to remove config duplication across libraries and CLIs; nothing consumes it yet, and everything will eventually be refactored onto it.
  Date: 2026-07-22

- Decision: relay-pagination is documented in the servant API stream (EP-7) in haskell-jitsurei rather than in this repo.
  Rationale: pagination is an API-layer concern that applies to any servant service, keiro-based or not; haskell-jitsurei/api is where the servant standards live and where the user began that work.
  Date: 2026-07-22

- Decision: Every child plan that changes `mori.dhall` must refresh this project's local Mori
  registration and verify `mori registry docs shinzui/keiro-runtime-patterns`, in addition to
  Dhall type-checking.
  Rationale: EP-1 proved that the config file and Mori's indexed projection are separate; the
  initiative's discoverability goal is not met until both agree.
  Date: 2026-07-22

- Decision: Keep Kiroku's store schema, Keiro's framework schema, and the application's data
  schema as separate ownership domains, with cross-schema SQL explicitly qualified.
  Rationale: Kiroku's schema also selects the LISTEN/NOTIFY channel, while Keiro and application
  tables have independent migration owners; conflating them breaks notification or hides
  lifecycle boundaries. Recorded in ADR 0001.
  Date: 2026-07-22

- Decision: Adopt keiro-dsl when a service spans node families, an integration surface, or
  expected schema/workflow evolution; permit direct API wiring only for a trivial single
  aggregate and revisit that exception when the service grows.
  Rationale: the DSL's value is its checked cross-node and evolution contracts, while the
  generated-code firewall deliberately leaves domain decisions hand-owned on either path.
  Recorded in ADR 0002.
  Date: 2026-07-22

- Decision: Use PGMQ for in-context jobs and work needing leases, retry caps, DLQs, or
  ordered groups; use Kafka for cross-context event streaming only with serial consumers
  and application-owned DLQ/retry bookkeeping; use Kiroku subscriptions only for local
  event-log reactions.
  Rationale: the three adapters expose materially different failure and ordering contracts.
  PGMQ integration-event transport remains unscheduled and must eventually build on
  `Keiro.PGMQ.Runtime`, not the `Job` abstraction. Recorded in ADR 0003.
  Date: 2026-07-22

- Decision: Standardize deployed services on six cabal packages and collocated per-concept
  `Generated.*` plus one hand-owned `Holes` module; reserve single-package services for
  explicitly labeled teaching repositories and reject duplicate legacy hand modules.
  Rationale: this preserves independent dependency budgets and a regeneration-safe ownership
  firewall while matching danwa's shipped structure and the released keiro-dsl placement model.
  Recorded in ADR 0004.
  Date: 2026-07-22


## Outcomes & Retrospective

Summarize outcomes, gaps, and lessons learned at major milestones or at completion.
Compare the result against the original vision. Before marking the MasterPlan complete,
distill durable project context from this MasterPlan and its child ExecPlans into
docs/adr/. Keep task-local execution and coordination details here.

EP-1 is complete. The repository now has twelve keiki documents: the eight original files
rewritten or conformed to the shared style plus four new 0.2 guides for structured replay,
event-schema evolution, checked composition, and upgrading. All twelve are linked from the
README, registered as `keiki-*` DocRefs, and visible through Mori's refreshed registry.
Source and style audits passed against the released `v0.2.0.0` tag. The remaining eight child
plans are unaffected except for the newly recorded requirement to refresh Mori after DocRef
changes.

EP-2 is complete. The repository now has eight Kiroku documents and seven pg-migrate
documents, all linked, registered, and visible in Mori alongside the twelve Keiki docs.
Validation passed against the released dependency tags: 30 symbol checks, complete style
and relative-link audits, Dhall type-checking, Mori validation, and registry refresh. The
ADR pass produced no new record; the one upstream stale-description finding was assigned
to EP-3.

EP-3 is complete. Six Conventional Commits across Keiro, Kiroku, Settei, Danwa, and
haskell-jitsurei corrected the full stale-doc catalogue and carry parseable MasterPlan,
ExecPlan, and Intention trailers. Cross-repository phrase checks passed, Keiro built in
its pinned Nix shell, Danwa's Cabal dry run passed, and the corrected Dhall import
type-checked after its semantic hash was verified from the pinned mori-schema commit.
Pre-existing unrelated changes were preserved. No ADR was created because EP-6 owns the
durable `Generated.*` + `Holes` architecture decision.

EP-4 is complete. The new `keiro/` area contains nine indexed standards covering runtime
assembly, schema ownership, command errors, read models and projections, durable workflows,
telemetry, DSL adoption, and cross-cutting gotchas. All nine `keiro-*` DocRefs type-check and
are visible in Mori after registry refresh. Acceptance passed 48 source-symbol checks against
the verified 0.3.0.0 release, full index/link/style audits, Dhall type-checking, and Mori
configuration validation. The implementation seeded ADR 0001 for schema separation and ADR
0002 for the DSL adoption boundary; EP-5 is now dependency-ready with the core glossary in
place.

EP-5 is complete. The new `messaging/` area contains eleven indexed standards covering
process managers and timers, integration contracts, transactional outbox/inbox boundaries,
Shibuya processing, transport selection, PGMQ jobs, Kiroku subscriptions, shared vocabulary,
and production gotchas. Acceptance passed the full source-symbol, link, style, Dhall, and
registry audits against the verified release cohort; all eleven `messaging-*` DocRefs are
visible in Mori after refresh. ADR 0003 records the transport boundary. EP-6 can now cite
stable worker/integration behavior, and EP-9 can consume the messaging DocRef keys.

EP-6 is complete. The new `architecture/` area contains eight indexed standards for the
six-package fleet boundary, vertical aggregate and extended-node placement, the generated-code
firewall, cross-cutting allowlist, scaffolding, test ownership, and a complete Conversation
example. Acceptance passed the danwa and jitsurei path checks, style and relative-link audits,
Dhall type-checking, Mori refresh, and the novice `ticket` reconstruction; all eight
`architecture-*` DocRefs are visible. ADR 0004 records the durable module and package convention,
and EP-9's only hard dependency is satisfied.


## Revision Notes

- 2026-07-22 (authoring session, pre-commit): after parallel drafting of the nine child plans, a cross-plan consistency review made three corrections. (1) Added Integration Point 7 (ADR numbers allocated at implementation time) and rephrased the hard-coded `0001` ADR filenames in EP-5 and EP-6 to "next free number" — both plans seed `docs/adr/` and would otherwise collide. (2) Rescoped EP-1's and EP-2's `mori.dhall` acceptance counts from absolute `Schema.DocRef::` totals to counts of their own key prefixes (`keiki-*`, `kiroku-*`/`migrations-*`), because absolute totals depend on sibling-plan execution order. (3) Added the settei-as-adoption-target decision and EP-8's supersession edit of haskell-jitsurei's `cli/hierarchical-config.md` after the user clarified settei's purpose mid-planning. Reason: keep child plans order-independent and the registry conflict-free, per Integration Points 1 and 7.
- 2026-07-22 (EP-1 completion): marked the keiki 0.2 corpus complete and recorded the
  cross-plan Mori refresh requirement discovered during acceptance. Reason: later doc plans
  must update both `mori.dhall` and Mori's indexed projection to satisfy discoverability.
- 2026-07-22 (EP-2 completion): added and registered the Kiroku and pg-migrate standards,
  marked EP-2 complete, and cascaded the global-position Prometheus HELP contradiction to
  EP-3. Reason: the pattern corpus must follow the public opaque-cursor contract while the
  stale upstream description is corrected at its source.
- 2026-07-22 (EP-3 completion): corrected stale runtime, migration, release, module-layout,
  migration-status, and Dhall-pin statements across five upstream repositories; marked
  EP-3 complete and cascaded Settei's verified published-release state into EP-8. Reason:
  downstream standards must begin from authoritative current source and release facts.
- 2026-07-22 (EP-4 completion): added and registered nine Keiro runtime and DSL standards,
  marked EP-4 complete, corrected three planning assumptions from released source, and
  distilled schema ownership and DSL adoption into the repository's first two ADRs. Reason:
  EP-5 and the later architecture/blueprint plans need stable, source-verified runtime terms
  and decision boundaries rather than duplicated prose.
- 2026-07-22 (EP-5 completion): added and registered eleven messaging standards, corrected
  transaction, idempotency, DLQ, and handler-exception assumptions against released source,
  refreshed Mori, and distilled transport selection into ADR 0003. Reason: EP-6 and EP-9
  need one precise connective-tissue contract for the service fleet.
- 2026-07-22 (EP-6 completion): added and registered eight service-architecture standards,
  reconciled danwa's shipped six-package verticals with jitsurei's extended node vocabulary,
  documented advisory stale-path cleanup, refreshed Mori, and distilled the package/module
  convention into ADR 0004. Reason: EP-9 needs one source-verified scaffold contract and can
  now proceed without repeating or re-deciding service structure.
