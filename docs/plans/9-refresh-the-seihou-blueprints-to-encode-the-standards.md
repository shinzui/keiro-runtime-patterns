---
id: 9
slug: refresh-the-seihou-blueprints-to-encode-the-standards
title: "Refresh the seihou blueprints to encode the standards"
kind: exec-plan
created_at: 2026-07-22T14:55:29Z
intention: intention_01ky5agv9gehqa8dbw03cdcpwv
master_plan: "docs/masterplans/1-keiro-runtime-standards-docs-and-seihou-blueprints.md"
---

# Refresh the seihou blueprints to encode the standards

This ExecPlan is a living document. The sections Progress, Surprises & Discoveries,
Decision Log, and Outcomes & Retrospective must be kept up to date as work proceeds.
If durable project context changes, update or create ADRs in docs/adr/ in the same change.


## Purpose / Big Picture

About ten new microservices will be bootstrapped and another ten refactored onto the keiro
runtime. The tool that does the bootstrapping is seihou — a project scaffolder whose
"blueprints" launch a coding agent with a curated prompt and reference files. Two blueprints
already exist: `haskell-keiro-service` (version 0.1.0, in the `seihou-modules` registry)
scaffolds a brand-new event-sourced service, and `migrate-keiro-stack` (version 0.1.1, in the
`agent-seihou` registry) walks an existing service through a stack migration. Both encode the
world as it was before the keiro 0.2/0.3 release train: codd migrations instead of pg-migrate,
GitHub source pins instead of Hackage releases, raw Dhall config instead of settei, no
OpenTelemetry, no health endpoints, and no citation of the standards documentation this
initiative produced (ExecPlans 1 through 8 of the parent MasterPlan).

After this plan is complete, running `seihou agent run haskell-keiro-service` in an empty git
repository produces a service whose tree matches the DDD vertical module structure standard
codified by EP-6 (six `<name>-<role>` packages, `Generated.*` + `Holes` modules per concept), a
pg-migrate migrations package, keiro 0.3 cohort pins resolved from Hackage, validated event
streams, settei-based configuration, OpenTelemetry wiring, Kubernetes health endpoints, and the
standard test-suite layout — and the blueprint's reference files tell the scaffolding agent
exactly which keiro-runtime-patterns docs to pull (via `mori`) for current guidance. Likewise,
`migrate-keiro-stack` gains two explicit refactoring phases (vertical structure and settei
adoption), an up-to-date cohort story (Hackage resolution, kiroku's prebuilt codd history
import, the `cohort-migrate` skill), and refreshed provenance. You can see it working by
applying the refreshed bootstrap blueprint to a scratch directory and checking the output tree
against the concrete acceptance script in Validation and Acceptance.


## Progress

Use a checklist to summarize granular steps. Every stopping point must be documented here,
even if it requires splitting a partially completed task into two ("done" vs. "remaining").
This section must always reflect the actual current state of the work.

- [x] ExecPlan authored from the planning research reports; both blueprints, both registries, and the seihou CLI docs read and drift catalogued (2026-07-22).
- [x] M1: Cohort versions re-verified against Hackage and upstream release tags; EP-6/EP-8 and available soft-dependency docs read; doc-citation and release tables recorded (2026-07-22).
- [x] M2: `haskell-keiro-service` blueprint.dhall refreshed through corrective version 0.2.2 (description, files list, allowedTools, and scratch-proof fixes).
- [x] M2: `haskell-keiro-service` prompt.md refreshed (pg-migrate, Hackage cohort, validated streams, settei, OTel, health, test layout, doc citations).
- [x] M2: `haskell-keiro-service` files/ refreshed; Hackage-only project and 13 reference files include migrations, telemetry, Settei Settings, and standards map.
- [x] M2: `seihou validate-blueprint` passes for haskell-keiro-service; legacy-engine grep is clean (2026-07-22).
- [x] M3: `migrate-keiro-stack` blueprint.dhall refreshed (version 0.2.0, description, six-file reference list, tags).
- [x] M3: `migrate-keiro-stack` prompt.md refreshed with eight consistently numbered phases, current cohort, Mori discovery, and the original fail-closed policy guard intact.
- [x] M3: Existing migration/database references refreshed with current provenance, Kiroku's release-owned history mapping, and `cohort-migrate` restored-clone guidance.
- [x] M3: `vertical-structure-refactor.md` and `settei-migration.md` written with normative DocRef citations.
- [x] M3: `seihou validate-blueprint` passes for migrate-keiro-stack (2026-07-22).
- [x] M4: Registry sync/check and validation clean in both registries; seihou-modules okf-docs regenerated and `okf validate` passes.
- [x] M4: Registry commits landed as seihou-modules `fb3ac19` and agent-seihou `52dd09e`, each with MasterPlan, ExecPlan, and Intention trailers.
- [x] M4: Bootstrap correction commits landed as seihou-modules `75fc87f` (0.2.1 reference-domain repair) and `20e59f6` (0.2.2 released-cohort proof), with the same initiative trailers.
- [x] M5: Clean 0.2.2 scratch apply completed in `/tmp/keiro-ep9-clean.FBkBPJ`; corrected tree acceptance, six-package build, four-component migration plan, and all six test suites pass (2026-07-22).
- [x] M5: Both debug renders reviewed end-to-end; the danwa-clone rehearsal is explicitly deferred because it needs an operator-supervised disposable database and destructive-policy confirmation (2026-07-22).
- [x] MasterPlan registry row for EP-9 updated; ADR distillation pass completed. EP-9 introduced no new durable runtime decision beyond ADRs 0004/0005; the MasterPlan's two remaining cross-plan decisions were recorded as ADRs 0006/0007 (2026-07-22).


## Surprises & Discoveries

Document unexpected behaviors, bugs, optimizations, or insights discovered during
implementation. Provide concise evidence.

Findings from plan authoring (2026-07-22), recorded here because they shaped the plan:

- The `migrate-keiro-stack` cohort table is already at the 2026-07-14 Hackage baseline (keiro
  0.3.0.0, pg-migrate 1.1.0.0, kiroku-store 0.3.0.1, keiki 0.2.0.0, shibuya-core 0.8.0.1). Its
  drift is not the version table but the surrounding guidance: reference files pin pre-release
  source revisions (`pg-migrate f39d64e…`, `keiro 29bd795…`), never mention kiroku's shipped
  `Kiroku.Store.Migrations.History.Codd` import mapping, never mention the `cohort-migrate`
  skill, and have no vertical-structure or settei phases.
- `agent-seihou` has a directly relevant ADR:
  `/Users/shinzui/Keikaku/bokuno/agent-seihou/docs/adr/1-keep-safety-critical-blueprints-self-contained.md`.
  It requires safety-critical prompts to remain operable when `files/` is not mounted, and it
  documents that a *successful debug render writes provenance into `.seihou/manifest.json`* —
  so all debug renders in this plan run in disposable scratch copies, never in the registry
  checkouts themselves.
- `seihou-modules` has an `okf-docs/` derived-documentation bundle (with
  `okf-docs/blueprints/haskell-keiro-service.md` embedding the blueprint version, prompt, and
  file descriptions); `agent-seihou` has no `okf-docs/` directory at all. So okf-docs
  regeneration is part of the seihou-modules flow only.
- `seihou registry sync-versions` rewrites `seihou-registry.dhall` whole-file, losing hand
  comments. Both current registry files are comment-free, so this is safe today.
- The planning baseline moved while this plan was being implemented. Hackage now carries
  `kiroku-store-0.3.1.0` (a compatible resource-runner addition, uploaded 2026-07-22) and
  `shikumi-0.3.0.1` / `shikumi-cache-0.1.2.1` / `shikumi-trace-0.2.0.1` (uploaded
  2026-07-21). The scaffold index-state therefore moves to `2026-07-22T18:04:31Z`, one
  second after the newest selected upload. Keiro's published `>= 0.3 && < 0.4` bound admits
  the new Kiroku patch/minor release.
- `hasql-notifications-0.2.5.0` is current on Hackage but the upstream repository's newest
  release tag is `0.2.4.0`. Hackage is authoritative for the Hackage-only cohort; the missing
  matching upstream tag is recorded rather than replaced with an invented revision pin.
- The bootstrap blueprint directory existed as a wholly untracked working baseline in
  seihou-modules, while the migration blueprint already carried uncommitted shared-`haskell-nix`
  integration work. The implementation preserved both baselines, incorporated the `haskell-nix`
  behavior into the 0.2.0 workflow, and left unrelated seihou-modules edits unstaged.
- The first real bootstrap apply proved that `settei-formats-0.2.0.0` is unsatisfiable in the
  GHC 9.12.4 cohort: its mandatory Dhall adapter reaches `dhall-json-1.7.12`
  (`bytestring <0.12`), while GHC and the released YAML/Kubernetes adapters require
  `bytestring >=0.12`. Version 0.2.2 therefore uses the direct `settei-yaml-0.2.0.0` adapter;
  the fleet configuration docs record the same boundary instead of relaxing dependency bounds.
- The WAI OpenTelemetry instrumentation package requires semantic conventions `>=1.40 && <2`.
  The complete cohort now pins `hs-opentelemetry-semantic-conventions-1.40.0.0` explicitly,
  verified against Hackage, Mori-located source, and upstream release tags.
- Nix flakes in an untracked scratch repository reject bare `nix develop` because `flake.nix`
  is not yet visible through the Git flake source. `nix develop path:. --command ...` (or
  `path:$PWD`) validates the generated tree without staging it, preserving the blueprint's
  never-commit rule.
- The exploratory apply spent too long pre-researching leaf APIs and downloaded temporary
  dependency copies. The 0.2.2 prompt now requires Mori-located source plus an early complete
  package skeleton and compiler-driven iteration; scratch dependency copies are explicitly
  forbidden.
- Released `keiro-dsl-0.3.0.0` emits the first-class `readmodel widgets` node as
  `Acme.Widgets.Generated.{ReadModel,ReadModelHarness,ReadModelTable}` plus the create-once
  `Acme.Widgets.ReadModelHoles`; the plan's predicted singular `Acme.Widget.ReadModel` path
  was stale. The clean scaffold follows the generator's contract, and the acceptance script
  now checks all four actual files.
- Generated modules can put LANGUAGE pragmas before the `-- @generated` banner, and the
  generated projection currently has an explanatory comment containing “codd” while importing
  no Codd API. Structural acceptance now finds the banner anywhere in the generated module and
  rejects Codd package/import surfaces rather than prose, which preserves the intended engine
  check without producing false failures on released generator output.
- The clean service proves the strong-read coupling rather than hiding it: inline projection
  writes are immediately listable, but a keyed `Strong` read returns the structured retryable
  503 until the worker advances the declared subscription cursor. The server suite exercises
  that real behavior against an ephemeral fully migrated PostgreSQL database.


## Decision Log

Record every decision made while working on the plan.

- Decision: Bump both blueprints to version 0.2.0 (`haskell-keiro-service` 0.1.0 → 0.2.0,
  `migrate-keiro-stack` 0.1.1 → 0.2.0).
  Rationale: both changes alter the blueprint's contract (what gets scaffolded / which workflow
  phases run), which under pre-1.0 semver is a minor bump, not a patch. Keeping the two at the
  same minor also signals they encode the same standards generation.
  Date: 2026-07-22

- Decision: Name the bootstrap configuration reference `Settings.hs` and keep it separate from
  `AppConfig.hs`.
  Rationale: EP-8 defines an inspectable `Config ServiceConfig` that resolves startup values before
  runtime resources are acquired; `AppConfig` remains the strict Effectful dependency record for
  pools, store handles, validated streams, and telemetry. Separating them makes that lifecycle
  visible and avoids treating source-loading details as runtime dependencies.
  Date: 2026-07-22

- Decision: The blueprint–docs coupling mechanism is citation, not duplication. Reference
  files under each blueprint's `files/` cite the keiro-runtime-patterns documentation by
  repository doc path *and* mori DocRef key, and instruct the launched agent to pull the
  current text with `mori registry docs shinzui/keiro-runtime-patterns` (and
  `shinzui/haskell-jitsurei` for the servant/OTel/health docs). Prompts keep the load-bearing
  rules inline so they work even when `files/` is not mounted, per agent-seihou ADR 1.
  Rationale: MasterPlan Integration Point 6 demands the blueprints not drift silently from the
  docs; citing a stable doc path + registry key means doc updates flow to every future scaffold
  without re-releasing the blueprint, while the inline rules keep the blueprint self-contained.
  Date: 2026-07-22

- Decision: `migrate-keiro-stack` keeps its Kioku (agent-memory) coverage.
  Rationale: the MasterPlan excluded kioku from the *documentation* initiative, but the
  migration blueprint targets arbitrary consumer services, some of which use kioku; removing
  the kioku component from the migration plan order (`pgmq -> kiroku -> keiro -> kioku ->
  application`) would break those migrations.
  Date: 2026-07-22

- Decision: okf-docs are regenerated only in seihou-modules.
  Rationale: verified on disk that `agent-seihou` has no `okf-docs/` bundle; introducing one
  there is out of scope and would be a new derived artifact nobody consumes yet.
  Date: 2026-07-22

- Decision: Commits in seihou-modules and agent-seihou carry MasterPlan/ExecPlan trailers whose
  paths are relative to the keiro-runtime-patterns repository (the coordination home), exactly
  as the MasterPlan's Decision Log prescribes for cross-repo work.
  Date: 2026-07-22

- Decision: The scratch verification instructs the scaffolding agent to use the reference
  `domain.keiro` Widget domain verbatim (via the optional PROMPT argument of
  `seihou agent run`), so the output tree is predictable enough for a concrete path-list
  acceptance check despite the agent being nondeterministic.
  Date: 2026-07-22

- Decision: Use direct released Settei adapters in the GHC 9.12 service cohort, normally
  `settei-yaml`, rather than the 0.2.0.0 `settei-formats` umbrella.
  Rationale: the umbrella's unconditional Dhall branch creates a real, authoritative-bound
  conflict; selecting only the format a service consumes is narrower and solvable. Reconsider
  the umbrella only after a complete later release cohort is verified.
  Date: 2026-07-22

- Decision: Defer the full `migrate-keiro-stack` danwa rehearsal beyond this plan.
  Rationale: the debug render, fail-closed guard, phase order, references, and registry validation
  are database-free and complete, while the real rehearsal deliberately requires an operator to
  attest that a database is disposable before destructive migration work. This implementation
  has no authority to manufacture that attestation.
  Date: 2026-07-22

- Decision: Treat the released DSL's plural `Widgets` read-model vertical as authoritative and
  update the living acceptance contract instead of hand-editing generated output into the
  singular path predicted during planning.
  Rationale: `keiro-dsl scaffold` is the ownership boundary established by ADR 0004. Its
  generated files compile, re-scaffold cleanly, and preserve both create-once Holes modules;
  renaming them after generation would make the blueprint immediately stale.
  Date: 2026-07-22


## Outcomes & Retrospective

Summarize outcomes, gaps, and lessons learned at major milestones or at completion.
Compare the result against the original purpose. Before marking the plan complete,
distill durable project context from the Decision Log, Surprises & Discoveries, and
this section into docs/adr/. Keep task-local execution details here.

Both blueprints now encode the completed standards corpus. `haskell-keiro-service` 0.2.2 in
seihou-modules scaffolds a Hackage-only GHC 9.12 service with six packages, the released
keiro-dsl generated/Holes firewall, pg-migrate composition, direct Settei adapters, real
OpenTelemetry, health probes, graceful runtime assembly, and standards citations. The
corrective 0.2.1 and 0.2.2 releases turned the initial prompt/reference refresh into a proven
cohort. `migrate-keiro-stack` 0.2.0 in agent-seihou retains its fail-closed database policy and
adds vertical-structure and Settei phases, current migration provenance, Kiroku's prebuilt Codd
history mapping, and restored-clone `cohort-migrate` guidance.

The clean 0.2.2 apply produced the complete Acme Widget service in
`/tmp/keiro-ep9-clean.FBkBPJ`. The corrected tree audit exited 0 with no output;
`nix develop path:. --command cabal build all` built every package and executable;
`acme-migrate plan` printed `kiroku(8) -> keiro(18) -> pgmq(2) -> acme(2)` without a database;
and `cabal test all` passed the domain (7 cases), diagrams (2), PostgreSQL (1), migrations (4),
workers (3), and server (6) suites. Configuration diagnostics also proved usage/source/
resolution exit codes and structural secret redaction during the apply. Re-scaffolding
overwrote all eight generated modules while leaving both Holes modules byte-identical.

Registry version sync/check, blueprint validation, generated OKF validation, and both debug
render reviews are complete. The only deferred proof is a live danwa migration rehearsal,
which intentionally remains operator-supervised because its destructive database policy needs
an explicit disposability attestation. No EP-9-specific ADR was needed: the actual read-model
namespace is generated-contract detail under ADR 0004, and the direct Settei adapter is a
release-cohort compatibility choice under ADR 0005.


## Context and Orientation

Read this section fully before touching anything; it contains all the background you need.

### The repositories involved

Four repositories matter, all on this workstation:

- `/Users/shinzui/Keikaku/bokuno/keiro-runtime-patterns` — this repository, the coordination
  home. It holds this plan, the parent MasterPlan
  (`docs/masterplans/1-keiro-runtime-standards-docs-and-seihou-blueprints.md`), the standards
  docs written by sibling plans, and `mori.dhall`, which registers every doc with a stable key
  so agents can discover it via the `mori` CLI. Earlier plans created `docs/adr/`; ADR 0004 owns
  the generated/Holes vertical and ADR 0005 owns Settei fleet adoption. EP-9 edits its living
  plan here, while the final MasterPlan audit also updates the parent and distills ADRs 0006/0007.
- `/Users/shinzui/Keikaku/bokuno/seihou-modules` — a seihou registry repository ("registry"
  means: a repo whose `seihou-registry.dhall` lists installable scaffolding artifacts). It owns
  the `haskell-keiro-service` blueprint at `blueprints/haskell-keiro-service/`. It also carries
  a derived documentation bundle under `okf-docs/` that must be regenerated after blueprint
  changes.
- `/Users/shinzui/Keikaku/bokuno/agent-seihou` — the second registry repository. It owns the
  `migrate-keiro-stack` blueprint at `blueprints/migrate-keiro-stack/`. It has
  `docs/adr/1-keep-safety-critical-blueprints-self-contained.md` (summarized below) and no
  okf-docs bundle.
- `/Users/shinzui/Keikaku/bokuno/seihou-project/seihou` — the seihou tool's own source and
  docs. Its CLI documentation lives at `docs/cli/*.md`; the pages relevant here are `agent.md`
  (the `seihou agent run` contract), `validate-blueprint.md`, `registry.md`
  (`sync-versions` / `validate`), `install.md`, and `okf-docs.md`.

### What a seihou blueprint is

A **blueprint** is an agent-driven scaffolding unit: a directory containing `blueprint.dhall`
(name, semver `version`, description, typed variables, optional deterministic `baseModules`
applied first, a `files` list, optional `allowedTools`, tags), `prompt.md` (the base prompt fed
to the launched agent, with `{{var}}` interpolation), and `files/` (reference material mounted
read-only into the agent's filesystem). `seihou agent run BLUEPRINT` resolves the blueprint
from the installed cache (`~/.config/seihou/installed/`), prompts for variables (or takes
`--var KEY=VALUE`), applies the base modules, renders the prompt, and starts the configured
provider (default `claude-cli`). `seihou agent --debug run …` prints the rendered prompt
without contacting a provider — but note it records applied-blueprint provenance in the current
directory's `.seihou/manifest.json`, so only debug-render inside disposable scratch
directories. Blueprints are installed by `seihou install <git-url-or-local-path> --module
<name>`, which *clones* the registry — only committed content is picked up.

Registry hygiene commands (run from the registry repo root): `seihou validate-blueprint
blueprints/<name>` checks well-formedness (Dhall evaluates, files resolve, vars unique, tags
non-empty; exit 0 clean); `seihou registry sync-versions` copies each item's declared version
into `seihou-registry.dhall` (whole-file rewrite, idempotent second run); `seihou registry
validate` additionally checks structure. The okf-docs bundle in seihou-modules is regenerated
with `seihou extension run okf -- docs --force` (per
`/Users/shinzui/Keikaku/bokuno/seihou-project/seihou/docs/cli/okf-docs.md`); it is derived
documentation — never hand-edit it.

### The relevant ADR (in agent-seihou)

`/Users/shinzui/Keikaku/bokuno/agent-seihou/docs/adr/1-keep-safety-critical-blueprints-self-contained.md`
(Accepted, 2026-07-15) decides: safety-critical prompts carry every rule needed for their safe
workflow inline, because older seihou versions did not mount `files/`; reference files add
depth but must not be load-bearing; variable validation patterns other than the literal
`[a-z][a-z0-9-]*` are not enforced by seihou v0.4, so prompts keep their own exact-value guards
(migrate-keiro-stack's `database.policy` guard is exactly this); and debug renders are not
worktree-neutral. Every edit this plan makes to `migrate-keiro-stack` must preserve these
properties. Local ADRs 0004 and 0005 govern the scaffold's structure and configuration choices.

### The standards the blueprints must encode

These are the facts the refreshed blueprints encode; each is documented in depth by a sibling
plan's output docs, which the blueprints will cite.

**The vertical module structure (EP-6, hard dependency — must be Complete before starting).**
A service is six flat-root cabal packages, `<name>-core`, `<name>-api`, `<name>-migrations`,
`<name>-workers`, `<name>-server`, `<name>-client`. Modules are organized vertical-slice by
domain concept: everything for one concept lives under `<Namespace>.<Concept>.*` regardless of
package. Per concept, `keiro-dsl scaffold` (with `layout collocated` declared in the `.keiro`
spec) emits a `.Generated` leaf — `<Ns>.<Concept>.Generated.{Domain,Codec,EventStream,
Projection,Harness}`, each carrying a `-- @generated` banner (after any LANGUAGE pragmas) and
overwritten on every re-scaffold — plus a create-once, never-overwritten
`<Ns>.<Concept>.Holes` module holding the hand-written keiki transducer and inline-projection
apply fold. First-class `readmodel <name>` nodes additionally emit
`<Ns>.<ReadModel>.Generated.{ReadModel,ReadModelHarness,ReadModelTable}` plus a create-once
`<Ns>.<ReadModel>.ReadModelHoles`; the released generator's node name determines that vertical.
Other hand modules sit flat beside their concept: `.Api` (api), `.Handler` (server), and
`.Worker` (workers).
Only cross-cutting infrastructure keeps technical-layer names (Prelude, App.Config,
Postgres.{Pool,Runner}, Migrations, Workers.{Subscription,Registry}, Server.{Config,App,Seam,
Boot}, the Api umbrella). EP-6's doc (owned directory `architecture/` in this repo) is the
authoritative statement; the blueprint scaffolds it and cites it rather than becoming a second
authority.

**Migrations are pg-migrate, not codd (EP-2 docs; `migrations/` directory in this repo).**
pg-migrate (release family 1.1.0.0) is a Hasql-native, forward-only, compile-time migration
engine: a migration-owning library exports a `MigrationComponent` (stable name, ordered
migrations, dependency set); the application composes components into a `MigrationPlan` and
mounts the reusable CLI from `pg-migrate-cli` (commands `plan list check status verify up
repair new`; a bare invocation must be a usage error, never `up`). Migration SQL lives beside a
strict plain-text `manifest` file (one lowercase `NNNN-slug.sql` filename per line, in order);
`embedMigrationManifest` (from `pg-migrate-embed`) embeds exact bytes at compile time, and on
GHC 9.12 the embedding module needs
`{-# OPTIONS_GHC -fplugin=Database.PostgreSQL.Migrate.Embed.RecompilePlugin #-}`. The service's
migrations package exports component `"<name>"` depending on `"keiro"`, and composes
`kiroku → keiro → (pgmq when queues are used) → <name>` into one plan behind a
`<name>-migrate` executable. Every applied body is SHA-256-checksummed; never edit an applied
migration; the ledger lives in the `pgmigrate` schema.

**The keiro 0.3 cohort resolves from Hackage.** As of the 0.3.0.0 release train (2026-07-14),
every default-build dependency of the stack is on Hackage — the known-good baseline, with
`index-state` no earlier than `2026-07-14T19:01:33Z`, is: keiro / keiro-core /
keiro-migrations / keiro-pgmq 0.3.0.0; keiki / keiki-codec-json 0.2.0.0; kiroku-store 0.3.0.1;
kiroku-store-migrations 0.3.0.0; shibuya-core / shibuya-metrics 0.8.0.1; shibuya-pgmq-adapter
0.12.0.0; shibuya-kiroku-adapter 0.4.0.0; pgmq-* 0.4.0.1; pg-migrate family 1.1.0.0;
hasql-notifications 0.2.5.0. codd survives only behind keiro's off-by-default
`legacy-codd-tools` flag. Milestone 1 re-verifies these against Hackage before they are written
into any file, because newer releases may exist by implementation time.

**Validated event streams (EP-4 docs; `keiro/` directory).** Since keiro 0.2, command runners,
projections, routers, and process managers take a `ValidatedEventStream`, produced by
`mkEventStream` / `mkEventStreamOrThrow`; **any** keiki replay-validation warning makes
construction reject at startup. The DSL's `Generated.EventStream` already emits the validated
construction. `mkEventStreamUnchecked` must never appear in a scaffold. Two-schema arrangement:
the kiroku store connection's `schema` stays `kiroku` (it drives LISTEN/NOTIFY) while keiro's
framework tables live in the dedicated `keiro` schema — application SQL must schema-qualify.
`CommandAmbiguous` is never benign.

**Configuration is settei (EP-8 docs; `config/` directory).** settei is the provenance-aware
configuration library adopted as the fleet standard, superseding the raw Dhall `FromDhall`
wiring danwa uses. Note carefully: **settei adoption is the target, not the current state of
any reference service** — no ecosystem service consumes settei yet, so the blueprint is the
first scaffolder of the pattern and must be written from EP-8's doc and the
`settei-example-service` canonical example, not from danwa. The standard includes the
`--check-config` rollout gate and the Kubernetes mounted-sources story.

**Observability and API standards (EP-7 docs, in
`/Users/shinzui/Keikaku/bokuno/haskell-jitsurei/api/`).** Real OpenTelemetry wiring
(hs-opentelemetry-sdk in server and worker mains; keiro's `Keiro.Telemetry` metrics threaded
via `newKeiroMetrics meter` and `& #metrics .~ metrics` on run options; W3C trace-context
propagation across the outbox/inbox boundary), the request-logging standard (danwa's
`logStdoutDev` is the anti-pattern), Kubernetes liveness/readiness health endpoints, servant
NamedRoutes, and RFC 7807 problem details. keiro-runtime-jitsurei
(`/Users/shinzui/Keikaku/bokuno/keiro-runtime-jitsurei`) demonstrates live OTel wiring;
danwa (`/Users/shinzui/Keikaku/bokuno/danwa`) demonstrates the six-package layout and the
test-suite layout but is still on codd, raw Dhall, and a noop tracer — treat danwa as the
structural reference and jitsurei as the telemetry/pg-migrate reference.

**Test-suite layout (EP-6/EP-2 docs).** Per danwa: core carries `test-domain` (a driver running
every generated `harnessAssertions`, failing on any False), `test-diagrams` (asserts the
committed Mermaid lifecycle diagrams are fresh), and `test-postgres` (ephemeral PostgreSQL via
the migrations package's public `test-support` sublibrary); the migrations package tests assert
schema presence, ledger rows, and idempotent re-apply; server tests exercise a handler against
an ephemeral migrated database; workers tests are per-concept `*Spec` modules laid out
vertically, matching src.

### Where the citation targets live

MasterPlan Integration Point 1 fixes directory ownership inside this repository: EP-1 owns
`keiki/`, EP-2 owns `kiroku/` and `migrations/`, EP-4 owns `keiro/`, EP-5 owns `messaging/`,
EP-6 owns `architecture/`, EP-8 owns `config/`; EP-7's docs live in
`/Users/shinzui/Keikaku/bokuno/haskell-jitsurei/api/`. DocRef keys follow
`<directory>-<file-slug>` (like the existing `keiki-*` keys in
`/Users/shinzui/Keikaku/bokuno/keiro-runtime-patterns/mori.dhall`). At implementation time the
exact filenames come from `mori.dhall` here and in haskell-jitsurei — that indirection is
deliberate. EP-6 is a hard dependency (its doc must exist); the soft-dependency docs (EP-1,
EP-2, EP-4, EP-5, EP-7, EP-8) may still be in flight — where a cited doc does not exist yet,
cite the owning directory plus the mori project key (`shinzui/keiro-runtime-patterns` or
`shinzui/haskell-jitsurei`) and record the gap in this plan's Decision Log so the citation is
tightened when the doc lands. This citation discipline is Integration Point 6: the blueprints
and the docs must not drift apart silently, and doc-path + mori-key citation is the mechanism
that prevents it.

### Verified doc-citation table

Blueprint reference material must cite these exact local paths and Mori DocRef keys. The
paths make review direct; the keys keep the same material discoverable when the blueprint is
applied outside this checkout.

| Standard | Local path | Mori project / DocRef key |
|---|---|---|
| Keiki build-time validation | `keiki/build-time-validation.md` | `shinzui/keiro-runtime-patterns` / `keiki-build-time-validation` |
| Kiroku operational invariants | `kiroku/operational-invariants.md` | `shinzui/keiro-runtime-patterns` / `kiroku-operational-invariants` |
| pg-migrate model | `migrations/pg-migrate-model.md` | `shinzui/keiro-runtime-patterns` / `migrations-pg-migrate-model` |
| Migration authoring | `migrations/authoring.md` | `shinzui/keiro-runtime-patterns` / `migrations-authoring` |
| Migration package | `migrations/service-package.md` | `shinzui/keiro-runtime-patterns` / `migrations-service-package` |
| Migration operations | `migrations/operations.md` | `shinzui/keiro-runtime-patterns` / `migrations-operations` |
| Migration testing | `migrations/testing.md` | `shinzui/keiro-runtime-patterns` / `migrations-testing` |
| Codd transition | `migrations/codd-transition.md` | `shinzui/keiro-runtime-patterns` / `migrations-codd-transition` |
| Runtime assembly | `keiro/runtime-assembly.md` | `shinzui/keiro-runtime-patterns` / `keiro-runtime-assembly` |
| Two-schema arrangement | `keiro/two-schema-arrangement.md` | `shinzui/keiro-runtime-patterns` / `keiro-two-schema-arrangement` |
| Command cycle and errors | `keiro/command-cycle-and-errors.md` | `shinzui/keiro-runtime-patterns` / `keiro-command-cycle-and-errors` |
| Keiro telemetry | `keiro/telemetry.md` | `shinzui/keiro-runtime-patterns` / `keiro-telemetry` |
| DSL adoption | `keiro/dsl-adoption.md` | `shinzui/keiro-runtime-patterns` / `keiro-dsl-adoption` |
| Shibuya processing | `messaging/shibuya-processing.md` | `shinzui/keiro-runtime-patterns` / `messaging-shibuya-processing` |
| Service packages | `architecture/service-packages.md` | `shinzui/keiro-runtime-patterns` / `architecture-service-packages` |
| Vertical slices | `architecture/vertical-slice-modules.md` | `shinzui/keiro-runtime-patterns` / `architecture-vertical-slice-modules` |
| Spec and scaffolding | `architecture/spec-and-scaffolding.md` | `shinzui/keiro-runtime-patterns` / `architecture-spec-and-scaffolding` |
| Test layout | `architecture/test-layout.md` | `shinzui/keiro-runtime-patterns` / `architecture-test-layout` |
| Settei service configuration | `config/settei-service-standard.md` | `shinzui/keiro-runtime-patterns` / `config-settei-service-standard` |
| Kubernetes configuration | `config/kubernetes-deployment.md` | `shinzui/keiro-runtime-patterns` / `config-kubernetes-deployment` |
| Health endpoints | `api/health-endpoints.md` | `shinzui/haskell-jitsurei` / `api-health-endpoints` |
| OpenTelemetry integration | `api/opentelemetry-integration.md` | `shinzui/haskell-jitsurei` / `api-opentelemetry-integration` |
| Request logging | `api/request-logging.md` | `shinzui/haskell-jitsurei` / `api-request-logging` |
| Servant routes | `api/servant-routes.md` | `shinzui/haskell-jitsurei` / `api-servant-routes` |
| RFC 7807 errors | `api/rfc7807-problem-details.md` | `shinzui/haskell-jitsurei` / `api-rfc7807-problem-details` |

### Verified release cohort

Hackage `preferred.json` and upstream release tags were checked on 2026-07-22 after locating
each source tree with Mori. The scaffold is Hackage-only and uses
`index-state: 2026-07-22T18:04:31Z`.

| Cohort | Versions selected | Upstream release evidence |
|---|---|---|
| Keiro | `keiro`, `keiro-core`, `keiro-migrations`, `keiro-pgmq`, `keiro-dsl` `0.3.0.0` | package tags peel to `c68dcc7b9cea8d9c180d1c04254a72aa43804cac` |
| Keiki | `keiki`, `keiki-codec-json` `0.2.0.0` | `v0.2.0.0` peels to `755a01de8febab5db81537b5235a1ab319017c33` |
| Kiroku | `kiroku-store` `0.3.1.0`; `kiroku-store-migrations` `0.3.0.0`; `kiroku-metrics` `0.1.0.1`; `kiroku-otel` `0.2.0.1` | store tag peels to `3009dda7238f7d05b1d0c97b04ec5d4c55031304`; migrations tag peels to `58aff77b3a6d6093e3613753a0543aab62db9fac` |
| pg-migrate | core, CLI, embed, import-codd, test-support `1.1.0.0` | `v1.1.0.0` peels to `f39d64e354818999667d345a1452f33eb4857fc1` |
| Shibuya | `shibuya-core`, `shibuya-metrics` `0.8.0.1`; `shibuya-pgmq-adapter` `0.12.0.0`; `shibuya-kiroku-adapter` `0.4.0.0` | release tags peel to `172df245f40a454af46dd7f4cde855eaa4414c5a`, `85931b45702faecc035d89bb5cff381e8679f793`, and `876fb66f60508441970211c56de0bfb234ccb3f6` |
| pgmq-hs | core/config/effectful/hasql/migration `0.4.0.1` | `v0.4.0.1` peels to `f4a101843ea6f5c055277fd84859ece02865eff4` |
| Settei | core plus env/formats/optparse-applicative/kubernetes adapters `0.2.0.0` | `v0.2.0.0` peels to `1bf62b0af110b4f42fe2528e9d459e0ccf12d626` |
| OpenTelemetry | API, SDK, OTLP exporter, WAI instrumentation, W3C propagator `1.0.0.0` | Hackage preferred versions and Mori-located `hs-opentelemetry` source agree |
| Kioku | API/core/migrations `0.1.0.0` | `v0.1.0.0` peels to `a99aa369701a76278ca33d83f8416dee443fa645` |
| Shikumi | `shikumi` `0.3.0.1`; `shikumi-cache` `0.1.2.1`; `shikumi-trace` `0.2.0.1` | all three release tags peel to `580b6c70a58bc96a8d52502c2e7c9376d2c46a15` |
| hasql notifications | `hasql-notifications` `0.2.5.0` | Hackage release is current; upstream tags stop at `0.2.4.0` |

### Drift catalogue: haskell-keiro-service 0.1.0 (what is wrong today)

Read `blueprints/haskell-keiro-service/{blueprint.dhall,prompt.md,files/*}` in
`/Users/shinzui/Keikaku/bokuno/seihou-modules` and confirm this catalogue before editing:

1. **codd throughout.** The blueprint description says "codd migrations"; prompt step 2
   specifies "`{{project.name}}-migrations` — codd SQL … real `YYYY-MM-DD-HH-MM-SS` UTC
   timestamps"; `files/cabal.project` pins codd, hasql-migration, and carries a
   `package codd / tests: False` stanza. All of it must become the pg-migrate
   component/manifest pattern described above.
2. **GitHub pin cohort.** `files/cabal.project` is a wall of `source-repository-package`
   stanzas (keiki, kiroku, keiro, codd, hasql-notifications, hasql-effectful, hasql-migration,
   typeid-hs, ephemeral-pg) with `index-state: 2026-06-16…`. The refreshed file is
   Hackage-only: new index-state, no source-repository-package stanzas for the cohort (the
   whole point of the 0.3 release train), plus whatever minimal `constraints`/`allow-newer`
   the re-verified cohort actually needs (determine empirically in M5, not by copying).
3. **No settei.** The prompt's "Effects and config" rule says "Configuration loads from Dhall
   via the `dhall` library" — replace with the settei standard.
4. **No OTel, no health endpoints, no request-logging standard.** Absent from prompt and
   files.
5. **No validated-stream/two-schema guidance.** The prompt never mentions
   `ValidatedEventStream`, startup rejection on replay warnings, or the `keiro` schema.
6. **Stale keiro-dsl invocation.** Steps 1 and 3 say `cd <keiro checkout> && cabal run -v0
   keiro-dsl -- …`; with keiro-dsl 0.3.0.0 on Hackage the instruction becomes installing or
   running the released tool (e.g. `cabal install keiro-dsl` once, then `keiro-dsl check …`).
7. **Thin test-suite guidance.** Only the diagrams freshness test is specified; the full
   layout (test-domain, test-postgres, migrations tests, server tests, workers Spec modules)
   is not.
8. **No doc citations.** Nothing points the scaffolding agent at the standards corpus, and
   `allowedTools` has no `Bash(mori *)` entry, so the agent could not pull docs even if told.

What is *not* drift: the six-package layout, `Generated.*` + `Holes` via `layout collocated`,
the two `common` stanzas, the custom prelude rules, the strict-fields/deriving rules, the
Mermaid diagram freshness gate, and the never-commit rule are all already correct — EP-6
confirmed the shipped-danwa convention the blueprint encodes. Preserve them.

### Drift catalogue: migrate-keiro-stack 0.1.1 (what is wrong today)

Read `blueprints/migrate-keiro-stack/{blueprint.dhall,prompt.md,files/*}` in
`/Users/shinzui/Keikaku/bokuno/agent-seihou` and confirm:

1. **Stale provenance revisions.** `cohort-and-runtime-reference.md` and
   `pg-migrate-implementation-reference.md` cite pre-release source revisions (pg-migrate
   `f39d64e…`, keiro `29bd795…`, kioku `a99aa36…`). Refresh to the released tags / current
   revisions verified in M1, and re-verify every statement that leaned on them.
2. **Missing kiroku history-import shortcut.** kiroku ships
   `Kiroku.Store.Migrations.History.Codd`, a prebuilt mapping of its 7 legacy codd migration
   names to pg-migrate positions `0001..0007` with `SamePayload` evidence. The references
   describe history import generically and never mention this — agents will re-derive by hand
   what the library already provides.
3. **Missing cohort-migrate skill pointer.** The `cohort-migrate` skill automates the
   persistent-database remediation for exactly this transition (renamed migration files, keiro
   tables relocated from the `kiroku` schema to the `keiro` schema, forward-only in-place
   remediation proven on a restored clone). The persistent-cutover reference should name it as
   the automated path and keep the manual runbook as the fallback. danwa's vendored
   remediation scripts (`danwa-migrations/remediation/` plus
   `docs/user/upgrading-a-persistent-danwa-database.md` in
   `/Users/shinzui/Keikaku/bokuno/danwa`) are the worked example to cite.
4. **No vertical-structure phase, no settei phase.** The workflow stops at cohort + runtime
   + migration adaptation; EP-6 and EP-8 make structure and configuration part of "on the
   standard stack".
5. **No doc discovery.** Phase 1's mori discovery list does not include
   `shinzui/keiro-runtime-patterns` or `shinzui/haskell-jitsurei`.
6. **Version/tags.** 0.1.1 → 0.2.0; tags gain `settei` and `vertical-slice`.

What is *not* drift: the cohort version table (already the 2026-07-14 baseline — still
re-verify in M1), the database-policy prompt guard, the fail-closed persistent cutover, the
plan order `pgmq -> kiroku -> keiro -> kioku -> application`, and the Never list. Preserve
them; they embody agent-seihou ADR 1.

### Writing-style rules for everything this plan writes

All markdown written by this plan (prompt edits, reference files) follows the established
blueprint reference-file style: a single `#` H1, prescriptive prose, fenced code blocks that
always carry a language tag (`bash`, `haskell`, `cabal`, `dhall`, `text`, …), no YAML
frontmatter. Dhall edits keep the pinned seihou-schema import (URL + sha256) untouched.


## Plan of Work

The work is five milestones. Milestones 2 and 3 are independent of each other; 1 precedes
both; 4 needs 2 and 3; 5 needs 4 (verification runs against *committed, installed* blueprint
content because `seihou install` clones the registry).

### Milestone 1: Ground truth and the citation table

Scope: no edits to the registries. Confirm both drift catalogues above by reading the files
they name. Re-verify the cohort versions against Hackage (the local corpus may lag upstream):
for each package in the baseline table, check the released version, e.g. `curl -s
https://hackage.haskell.org/package/keiro/preferred` or `cabal list --simple-output keiro`.
Read EP-6's produced doc(s) under `architecture/` in this repository end-to-end — the blueprint
scaffolds that standard and must not contradict a word of it. Read whatever exists of the
soft-dep docs (`keiki/`, `kiroku/`, `migrations/`, `keiro/`, `messaging/`, `config/` here;
`api/` in haskell-jitsurei) and both repos' `mori.dhall`. Then write the citation table into
this plan (update this section): one row per standard area — doc path, mori project key,
DocRef key (or "pending: cite directory," when the doc is not yet written). This table is the
single source the reference files transcribe in M2/M3. Acceptance: the table exists in this
plan; every cohort version in it carries a "verified on Hackage <date>" note; EP-6's doc has
been read (record its exact path here).

### Milestone 2: Refresh haskell-keiro-service

Scope: all edits inside
`/Users/shinzui/Keikaku/bokuno/seihou-modules/blueprints/haskell-keiro-service/`.

**blueprint.dhall.** Set `version = Some "0.2.0"`. Rewrite `description` to name pg-migrate
(not codd), Hackage cohort pins, settei configuration, OpenTelemetry, health endpoints, and
the EP-6 vertical structure (keep it one sentence-family like the current one; the registry
and okf-docs republish it verbatim). Update the `files` list to match the new `files/` set
below, each with a description that tells the agent what to adapt versus copy. Extend
`allowedTools` with `"Bash(mori *)"` (so the launched agent can run `mori registry docs …` to
pull cited docs) — keep every existing entry. Update the `{{project.name}}-migrations` clause
inside the `project.name` var description (it currently implies codd) and scrub any other
codd/Dhall-config mention in var descriptions. Do not touch the schema import, the var set,
the prompts list, or `baseModules`.

**prompt.md.** Keep the overall shape (Critical rules → Reference Files → numbered "How to
proceed" → hand off) and every still-correct rule (listed under "What is not drift" above).
Make these changes:

- Critical rules: replace the cabal.project rule ("GitHub https + Hackage only … typeid-hs
  pin") with: the cohort resolves **from Hackage** with `index-state` at or after the value
  verified in M1; no `source-repository-package` stanzas for the runtime stack; never
  `file://` or corpus paths. Replace the config rule with: configuration is **settei** per the
  fleet standard (cite the EP-8 doc path + mori key; state that settei is the fleet target and
  the scaffold is expected to wire it even though older services predate it). Add a rule:
  event streams are validated — the generated `Generated.EventStream` constructs a
  `ValidatedEventStream` via `mkEventStreamOrThrow`, any keiki replay warning rejects at
  startup, `mkEventStreamUnchecked` is forbidden, and application SQL schema-qualifies
  (framework tables in `keiro`, store connection schema stays `kiroku`). Add a rule:
  observability is real — hs-opentelemetry SDK in both executables, keiro metrics via
  `newKeiroMetrics` threaded with `& #metrics .~ metrics`, request logging and
  liveness/readiness endpoints per the haskell-jitsurei API standards (cite path + key);
  `logStdoutDev` and `runTracingNoop` are forbidden in the scaffold.
- Add, right after "Critical rules", a short "Current standards via mori" section: the
  authoritative, always-current versions of these standards are the keiro-runtime-patterns
  docs; run `mori registry docs shinzui/keiro-runtime-patterns` and
  `mori registry docs shinzui/haskell-jitsurei` and read the docs named in
  `files/standards-map.md` before deviating from anything in this prompt.
- Step 1 (DSL first): replace the `<keiro checkout>` invocations with the released tool
  (`cabal install keiro-dsl --overwrite-policy=always` once, then
  `keiro-dsl check domain/{{keiro.context}}.keiro`); keep the `layout collocated` and
  enum-annotation guidance.
- Step 2 (packages): rewrite the `{{project.name}}-migrations` bullet: pg-migrate SQL under
  `{{project.name}}-migrations/migrations/application/` as `NNNN-slug.sql` plus a strict
  `manifest`; a `{{project.namespace}}.Migrations` module exporting the `"{{project.name}}"`
  `MigrationComponent` (depends on `"keiro"`) via `embedMigrationManifest` with the
  RecompilePlugin pragma; plan composition kiroku → keiro → (pgmq if the service declares
  workqueues) → application; a `{{project.name}}-migrate` executable mounting the
  `pg-migrate-cli` commands with bare-invocation-is-usage-error; the public `test-support`
  sublibrary now wraps `pg-migrate-test-support`'s `withMigratedDatabase` (note its nested
  `Either` gotcha: the error type wraps the callback result — unwrap and fail loudly).
- Step 4 (wiring): fold in settei config loading, OTel setup in `Server.Boot` and the worker
  main, and the health endpoints; commands run against the `ValidatedEventStream` values from
  the Generated ring.
- Step 6 (build/test): expand to the full test-suite layout (test-domain harness driver,
  test-diagrams, test-postgres, migrations idempotency test, server handler test, workers
  Specs) and add `cabal run {{project.name}}-migrate -- plan` as a database-free smoke of the
  composed plan.

**files/.** Keep `Prelude.hs`, `Diagrams.hs`, `domain.keiro`, `fourmolu.yaml`, `Api.hs`
(extend `Api.hs` only if EP-7's health-endpoint standard prescribes a concrete route shape —
then add it there). Rewrite `cabal.project` (Hackage-only as described; keep the
ADAPT/KEEP header comment style). Update `core.cabal` (same stanzas; build-depends refreshed
to the M1-verified cohort; drop any codd-era comment). Update `AppConfig.hs` notes to mention
settei as the loading mechanism (the record shape itself stays). Add four files:

- `Migrations.hs` — the migrations-package reference: component module with the
  RecompilePlugin pragma + `embedMigrationManifest`, the plan composition (modelled on the
  `applicationMigrations` / `applicationPlan` shapes in
  `pg-migrate/examples/basic/app/Main.hs` and the migrate-keiro-stack reference — read the
  released pg-migrate source via `mori registry show shinzui/pg-migrate --full` before
  writing), and the CLI `Main` sketch.
- `manifest` — a two-line example manifest (`0001-create-read-models.sql` style) so the agent
  sees the exact format (no comments, no blank lines).
- `Telemetry.hs` — the OTel bootstrap reference (SDK acquisition bracket, tracer + meter,
  `newKeiroMetrics`, threading into run/worker options), derived from EP-7's doc and
  keiro-runtime-jitsurei's `HospitalCapacity.Telemetry`; verify names against keiro 0.3
  source via mori before writing.
- `standards-map.md` — the citation mechanism made concrete: the M1 table rendered as "topic →
  doc path in shinzui/keiro-runtime-patterns (or shinzui/haskell-jitsurei) → mori DocRef key →
  one-line why", plus the two `mori registry docs` commands. This file is what keeps the
  blueprint and the docs from drifting silently (Integration Point 6).
- One settei reference file (name it after what EP-8's standard calls the config module, e.g.
  `Settings.hs` or `config.dhall` — decide from the EP-8 doc and record the choice in the
  Decision Log) showing the settei wiring for a service exactly as the standard prescribes.

Acceptance for M2: `seihou validate-blueprint blueprints/haskell-keiro-service` exits 0 from
the seihou-modules root; `grep -ri codd blueprints/haskell-keiro-service` returns nothing;
every `files` entry in blueprint.dhall resolves; the prompt renders (debug render in a scratch
directory, M5).

### Milestone 3: Refresh migrate-keiro-stack

Scope: all edits inside
`/Users/shinzui/Keikaku/bokuno/agent-seihou/blueprints/migrate-keiro-stack/`.

**blueprint.dhall.** `version = Some "0.2.0"`; extend `description` with the two new workflow
phases (vertical structure, settei); add the two new reference files to `files`; tags gain
`"settei"` and `"vertical-slice"`. Keep the `database.policy` var, its validation string, and
the absence of `allowedTools` (deliberate per ADR 1 — destructive commands must keep
requiring interactive approval). Do not touch the schema import.

**prompt.md.** Keep Phases 1–6 and every safety rule intact, then:

- Phase 1: add `mori registry docs shinzui/keiro-runtime-patterns` and
  `mori registry docs shinzui/haskell-jitsurei` to the discovery commands, with one sentence:
  these are the prescriptive runtime standards the migrated service must land on.
- Phase 2: keep the cohort table, refreshed to the M1-verified versions (if unchanged, update
  only the verification date sentence). Keep the "reproducible fallback, not an eternal
  latest" framing.
- Phase 4 (or 5): add one paragraph on kiroku's `Kiroku.Store.Migrations.History.Codd`
  prebuilt mapping as the first-choice history import for the kiroku component, and name the
  `cohort-migrate` skill as the automated persistent-database remediation path when the
  target's database holds critical data (the skill discovers, composes, and proves the
  remediation on a restored clone).
- Insert two new phases between the current Phase 4 (author the native migration plan) and
  Phase 5 (database classification) — renumber the later phases:
  - **Adopt the vertical module structure.** Inline the essential rules (per ADR 1): the
    target shape is `Generated.*` + `Holes` vertical slices across the six-package layout;
    if the service is keiro-dsl-generated, re-scaffold with the matching 0.3 keiro-dsl and
    `layout collocated` and let module moves fall out; if hand-rolled, move modules
    concept-by-concept, updating `exposed-modules`, keeping each move compiling before the
    next; never hand-edit a `-- @generated` module; the full standard with worked examples is
    in `vertical-structure-refactor.md` and the cited EP-6 doc. State explicitly that this
    phase is code-motion only — no behavior change, proven by the existing test suite passing
    before and after.
  - **Migrate configuration to settei.** Inline the essentials: replace raw Dhall
    `FromDhall` / ad-hoc env wiring with settei layering per the fleet standard; preserve
    every existing config knob and its default; wire the `--check-config` gate; the full
    standard is in `settei-migration.md` and the cited EP-8 doc. This phase must not change
    what configuration values the service actually resolves — capture the resolved config
    before and after and diff.
- Phase 6 (validation): add the structure and settei outcomes to the handoff list.

**files/.** Refresh the four existing references per the drift catalogue (new provenance
revisions and re-verified statements; History.Codd paragraph in
`cohort-and-runtime-reference.md` and `pg-migrate-implementation-reference.md`;
cohort-migrate skill + danwa remediation example in `persistent-database-cutover.md`;
`disposable-database-fast-path.md` needs only the renumbered phase references and provenance).
Add two files:

- `vertical-structure-refactor.md` — the EP-6 refactor guide for an *existing* service:
  target tree, the generated/hand firewall, the concept-by-concept move recipe, the
  danwa-versus-flat-layout history (the shipped `Generated.*` + `Holes` convention is
  authoritative; the flat prose in danwa's cabal description was abandoned), test-layout
  target, and the citation block (doc path + mori key from the M1 table).
- `settei-migration.md` — the EP-8 migration guide: what settei is, the layering model, the
  before/after of danwa-style Dhall loading versus settei, the `--check-config` rollout gate,
  Kubernetes notes, and the citation block. Write it from EP-8's doc and
  `settei-example-service`; verify API names against settei source via
  `mori registry show shinzui/settei --full` — do not write settei code from memory.

Acceptance for M3: `seihou validate-blueprint blueprints/migrate-keiro-stack` exits 0 from the
agent-seihou root; the prompt still contains the database-policy guard verbatim as its first
instruction; the two new phases appear between plan authoring and database classification;
phase renumbering is consistent throughout prompt and files.

### Milestone 4: Registry mechanics and commits

Scope: registry files and git in both repos. In each registry root run `seihou
validate-blueprint` (again), `seihou registry sync-versions` (updates the blueprint's version
in `seihou-registry.dhall`; expect "1 entry updated" the first time, "0 entries updated" on
re-run), then `seihou registry validate` (exit 0). In seihou-modules only, regenerate the okf
bundle: `seihou extension run okf -- docs --force` and, if the `okf` CLI is on
PATH, `okf validate okf-docs`. Verify the regenerated
`okf-docs/blueprints/haskell-keiro-service.md` shows `version: 0.2.2` and the new
description/prompt. Commit per repo with Conventional Commits and the initiative trailers —
trailer paths are **relative to keiro-runtime-patterns**, the coordination repo, even though
these commits land elsewhere:

```text
fix(blueprints): prove the Keiro service cohort (0.2.2)

Scaffold pg-migrate migrations, Hackage cohort pins, validated event
streams, settei configuration, OpenTelemetry, health endpoints, and the
EP-6 vertical structure; cite the keiro-runtime-patterns docs via mori.

MasterPlan: docs/masterplans/1-keiro-runtime-standards-docs-and-seihou-blueprints.md
ExecPlan: docs/plans/9-refresh-the-seihou-blueprints-to-encode-the-standards.md
```

and correspondingly `feat(blueprints): refresh migrate-keiro-stack for the current cohort
(0.2.0)` in agent-seihou. Commit directly on each repo's current branch (no feature branches,
per workstation convention). Acceptance: `git log -1` in each repo shows the trailers;
`seihou registry sync-versions --check` exits 0 in both.

### Milestone 5: Verification

Scope: prove the refreshed blueprints behave, in scratch directories only. This is the
milestone that makes the change demonstrably working rather than merely edited. Details,
commands, and acceptance are in Concrete Steps and Validation and Acceptance below. Summary:
(a) debug-render both blueprints in disposable directories and read the rendered prompts
end-to-end; (b) install `haskell-keiro-service` from the committed registry and run it for
real against a scratch git repo with pinned variables and the reference Widget domain, then
run the tree-diff acceptance script, the negative greps, and the build/test gate inside the
scaffold; (c) for `migrate-keiro-stack`, whose full run needs a target repository and
database, the committed acceptance here is validate-blueprint plus the reviewed debug render —
and the plan states precisely how to set up the full rehearsal against a danwa clone, which is
the true acceptance test to run when an operator can supervise it.


## Concrete Steps

Commands are grouped by milestone; the working directory precedes each group. `$SCRATCH`
means a disposable directory you create with `mktemp -d`; nothing under it is ever committed.

**M1 — ground truth** (working directory: anywhere):

```bash
cabal list --simple-output keiro keiro-dsl keiki kiroku-store pg-migrate shibuya-core pgmq-core settei 2>/dev/null | sort -u
mori registry docs shinzui/keiro-runtime-patterns
mori registry docs shinzui/haskell-jitsurei
mori registry show shinzui/pg-migrate --full
mori registry show shinzui/settei --full
ls /Users/shinzui/Keikaku/bokuno/keiro-runtime-patterns/architecture/ \
   /Users/shinzui/Keikaku/bokuno/keiro-runtime-patterns/config/ 2>/dev/null
```

If `cabal list` is unavailable or stale, query Hackage directly, e.g.
`curl -s https://hackage.haskell.org/package/keiro/preferred`. Record the verified versions
and the citation table in this plan before proceeding.

**M2 — edit haskell-keiro-service** (working directory:
`/Users/shinzui/Keikaku/bokuno/seihou-modules`):

Edit `blueprints/haskell-keiro-service/blueprint.dhall`, `prompt.md`, and `files/` per the
Plan of Work. Then:

```bash
seihou validate-blueprint blueprints/haskell-keiro-service
grep -ri codd blueprints/haskell-keiro-service && echo "DRIFT REMAINS" || echo "clean"
```

Expected: the validator prints a clean report and exits 0; the grep prints `clean`.

**M3 — edit migrate-keiro-stack** (working directory:
`/Users/shinzui/Keikaku/bokuno/agent-seihou`):

Edit `blueprints/migrate-keiro-stack/blueprint.dhall`, `prompt.md`, and `files/` per the Plan
of Work. Then:

```bash
seihou validate-blueprint blueprints/migrate-keiro-stack
```

**M4 — registries and commits** (run the block once in each registry root):

```bash
seihou validate-blueprint blueprints/<the-blueprint>
seihou registry sync-versions
seihou registry validate
git add -A && git commit   # message per the templates in Milestone 4
```

Expected `sync-versions` transcript the first time (seihou-modules shown; agent-seihou
analogous):

```text
haskell-keiro-service  0.2.1 -> 0.2.2  (stale)
1 entry updated
```

In seihou-modules additionally, before the commit:

```bash
seihou extension run okf -- docs --force
grep -n "version: 0.2.2" okf-docs/blueprints/haskell-keiro-service.md
```

**M5 — debug renders** (working directory: a fresh `$SCRATCH/render`; debug renders write
`.seihou/manifest.json` into the cwd, which is why we are here and not in a registry):

```bash
seihou install /Users/shinzui/Keikaku/bokuno/seihou-modules --module haskell-keiro-service
seihou install /Users/shinzui/Keikaku/bokuno/agent-seihou --module migrate-keiro-stack
seihou list   # confirm bootstrap 0.2.2 and migration 0.2.0
seihou agent --debug run haskell-keiro-service \
  --var project.name=acme --var project.namespace=Acme \
  --var "project.description=Scratch verification service" --var keiro.context=acme \
  > rendered-bootstrap.md
seihou agent --debug run migrate-keiro-stack --var database.policy=ask \
  > rendered-migrate.md
```

Read both rendered prompts end-to-end. Reinstall (re-run `seihou install …`) after any fix
commit — install clones the registry, so uncommitted edits are invisible.

**M5 — real scratch apply** (working directory: a fresh `$SCRATCH/acme`):

```bash
git init
seihou agent run haskell-keiro-service \
  --var project.name=acme --var project.namespace=Acme \
  --var "project.description=Scratch verification service" --var keiro.context=acme \
  "Use the reference domain.keiro Widget domain verbatim (context acme) rather than inventing a new domain."
```

Prerequisites: `seihou` on PATH (`seihou --version`), the `claude` CLI installed and
authenticated (the default `claude-cli` provider), network access for Hackage, and `nix` for
the base-module dev shell. The run is interactive and long (the agent authors the spec,
scaffolds, fills holes, builds). When it finishes, run the acceptance checks from Validation
and Acceptance in the same directory.

**M5 — danwa rehearsal setup for migrate-keiro-stack** (documented; run when an operator can
supervise — see Validation and Acceptance):

```bash
git clone /Users/shinzui/Keikaku/bokuno/danwa "$SCRATCH/danwa-rehearsal"
cd "$SCRATCH/danwa-rehearsal"
seihou agent run migrate-keiro-stack --var database.policy=disposable
```

danwa is the ideal rehearsal target because it is still on codd and the pre-0.2 cohort, uses
raw Dhall config, and already has the six-package vertical structure — so the run exercises
the cohort, pg-migrate, and settei phases while the structure phase should be a near no-op.
Point it at a disposable local database only (the blueprint itself re-proves disposability
before any destructive step). Never push or copy results back into the real danwa checkout.


## Validation and Acceptance

**haskell-keiro-service — tree acceptance.** After the scratch apply in `$SCRATCH/acme`, save
this as `check-tree.sh` and run it there (`bash check-tree.sh`):

```bash
#!/usr/bin/env bash
set -u
missing=0
required=(
  cabal.project
  domain/acme.keiro
  docs/diagrams/domain-lifecycles.md
  acme-core/src/Acme/Prelude.hs
  acme-core/src/Acme/App/Config.hs
  acme-core/src/Acme/Postgres/Pool.hs
  acme-core/src/Acme/Postgres/Runner.hs
  acme-core/src/Acme/Widget/Generated/Domain.hs
  acme-core/src/Acme/Widget/Generated/Codec.hs
  acme-core/src/Acme/Widget/Generated/EventStream.hs
  acme-core/src/Acme/Widget/Generated/Projection.hs
  acme-core/src/Acme/Widget/Generated/Harness.hs
  acme-core/src/Acme/Widget/Holes.hs
  acme-core/src/Acme/Widgets/Generated/ReadModel.hs
  acme-core/src/Acme/Widgets/Generated/ReadModelHarness.hs
  acme-core/src/Acme/Widgets/Generated/ReadModelTable.hs
  acme-core/src/Acme/Widgets/ReadModelHoles.hs
  acme-api/src/Acme/Api.hs
  acme-api/src/Acme/Widget/Api.hs
  acme-migrations/migrations/application/manifest
  acme-server/src/Acme/Widget/Handler.hs
  acme-workers/src/Acme/Widget/Worker.hs
  acme-client/src/Acme/Client.hs
)
for p in "${required[@]}"; do
  [ -e "$p" ] || { echo "MISSING: $p"; missing=1; }
done
rg -q '^-- @generated' acme-core/src/Acme/Widget/Generated/Domain.hs \
  || { echo "MISSING @generated banner"; missing=1; }
rg -q embedMigrationManifest acme-migrations/src || { echo "MISSING pg-migrate embed"; missing=1; }
rg -qi '^[[:space:]]*source-repository-package' cabal.project \
  && { echo "FORBIDDEN: git pins"; missing=1; }
rg -qi '^[[:space:]]*(build-depends:.*\bcodd\b|,[[:space:]]*codd\b|package[[:space:]]+codd\b|import[[:space:]].*\bcodd\b)' \
  -g '*.hs' -g '*.cabal' -g 'cabal.project' . \
  && { echo "FORBIDDEN: codd dependency or import"; missing=1; }
rg -q mkEventStreamUnchecked -g '*.hs' . && { echo "FORBIDDEN: unchecked stream"; missing=1; }
rg -q logStdoutDev -g '*.hs' . && { echo "FORBIDDEN: logStdoutDev"; missing=1; }
rg -q settei -g '*.cabal' . || { echo "MISSING settei dependency"; missing=1; }
rg -q hs-opentelemetry -g '*.cabal' . || { echo "MISSING OTel dependency"; missing=1; }
exit $missing
```

Expected output: nothing but exit code 0. Any `MISSING:`/`FORBIDDEN:` line is a blueprint bug
— fix the blueprint (not the scratch output), commit, reinstall, re-apply. The exact
`migrations/application/` location and the health/settei module names must be reconciled in M1
against what EP-6/EP-7/EP-8 prescribe; update this script in the same edit if they differ.
Additionally confirm a health route exists (`rg -i health acme-api/src acme-server/src`
returns at least one route definition) and then prove behavior beyond structure:

```bash
nix develop path:. --command cabal build all
nix develop path:. --command cabal run acme-migrate -- plan   # renders kiroku -> keiro -> acme without a database
nix develop path:. --command cabal test all                   # harness, diagrams, postgres, migrations, server, workers suites
```

All three must succeed; `cabal test all` failing on the diagrams or harness suite means the
scaffold's freshness gates work (good) but the agent left them stale (blueprint prompt bug).

**migrate-keiro-stack — dry-run acceptance (committed for this plan).**
`seihou validate-blueprint blueprints/migrate-keiro-stack` exits 0. The debug render
(`rendered-migrate.md` from Concrete Steps) is read end-to-end and shows: the database-policy
guard first; mori discovery including `shinzui/keiro-runtime-patterns`; the M1-verified cohort
table; the two new phases in order (structure, then settei, after plan authoring and before
database classification); consistent phase numbering; the History.Codd and cohort-migrate
mentions. A second reviewer pass checks prompt and reference files do not contradict each
other (ADR 1's stated authoring cost).

**migrate-keiro-stack — full acceptance (the danwa rehearsal).** The blueprint's real
acceptance test is the supervised rehearsal from Concrete Steps: a danwa clone ends up
building against the Hackage 0.3 cohort with a single pg-migrate ledger
(`danwa-migrate plan` renders `kiroku -> keiro -> danwa`… order per the blueprint), its
vertical structure intact, settei-resolved configuration identical to the pre-migration
resolved config, and its full test suite green. If the rehearsal is deferred beyond this
plan, record that explicitly in the Decision Log and the handoff — do not silently claim it.

**Registry acceptance.** In both registry roots: `seihou registry sync-versions --check`
exits 0; `seihou registry validate` exits 0; `git log -1` shows the Conventional Commit with
both trailers. In seihou-modules: `okf-docs/blueprints/haskell-keiro-service.md` frontmatter
says `version: 0.2.2` and its embedded prompt contains "pg-migrate" and not "codd".


## Idempotence and Recovery

Every step here is safe to repeat. File edits are plain overwrites in git-tracked repos —
`git diff` reviews them and `git checkout -- <path>` reverts them before commit.
`seihou validate-blueprint` and `seihou registry validate` are read-only.
`seihou registry sync-versions` is idempotent (second run: "0 entries updated") but rewrites
`seihou-registry.dhall` whole-file; both registries are comment-free today, so nothing is
lost — still run it before hand-editing that file, not after. okf-docs regeneration with
`--force` is destructive only to `okf-docs/`, which is derived — regenerating is the recovery.
`seihou install` from a local path clones committed state; re-running it refreshes the cache,
which is also the recovery for a stale install. Debug renders and real applies mutate only
their scratch working directories; recovery is `rm -rf` of the scratch dir and a fresh
`mktemp -d`. The scratch apply can be re-run from an empty directory any number of times; if
an apply fails midway, do not repair the scratch tree by hand — fix the blueprint, commit,
reinstall, and re-apply, so the blueprint itself is what gets proven. The danwa rehearsal
works on a clone with a disposable database; its rollback is deleting the clone. Nothing in
this plan writes to a persistent database.

If a commit lands with a wrong trailer or message, do not amend after the other registry has
built on it; add a `chore:` correction commit. If `sync-versions` runs before the version
bump is saved in `blueprint.dhall` (yielding "0 entries updated"), just re-run it after
saving.


## Interfaces and Dependencies

**Tools that must be on PATH:** `seihou` (v0.4-line or later; check `seihou --version` — the
debug-render provenance and lenient variable-pattern behaviors this plan works around are the
v0.4 behaviors documented in agent-seihou ADR 1), Seihou's `okf` extension (for the okf-docs
regeneration; optional `okf` for bundle validation), `mori` (dependency and doc discovery),
`git`, `cabal`, `nix`, and the `claude` CLI (authenticated) for the real apply.

**Dhall contracts.** Both `blueprint.dhall` files keep their pinned seihou-schema import
(`https://raw.githubusercontent.com/shinzui/seihou-schema/a0fba0d…/package.dhall` with its
sha256) unchanged. The fields this plan touches: `version : Optional Text`,
`description : Optional Text`, `files : List BlueprintFile` (`{ src : Text, description :
Optional Text }`, each `src` resolving under `files/`), `tags : List Text`, and (bootstrap
blueprint only) `allowedTools : Optional (List Text)`.

**The dependency cohort the blueprints pin** (baseline verified 2026-07-14; M1 re-verifies
against Hackage before writing it anywhere): keiro, keiro-core, keiro-migrations, keiro-pgmq,
keiro-dsl 0.3.0.0; keiki, keiki-codec-json 0.2.0.0; kiroku-store 0.3.0.1;
kiroku-store-migrations 0.3.0.0; pg-migrate, pg-migrate-cli, pg-migrate-embed,
pg-migrate-import-codd, pg-migrate-test-support 1.1.0.0; shibuya-core, shibuya-metrics
0.8.0.1; shibuya-pgmq-adapter 0.12.0.0; shibuya-kiroku-adapter 0.4.0.0; pgmq-core,
pgmq-config, pgmq-effectful, pgmq-hasql, pgmq-migration 0.4.0.1; hasql-notifications 0.2.5.0;
settei (version from M1 — it postdates the 2026-07-14 table); `index-state` ≥
`2026-07-14T19:01:33Z`.

**Haskell interfaces the reference files must name correctly** (verify each against the
released source via `mori registry show <project> --full` before writing — never from
memory): `Database.PostgreSQL.Migrate` (`MigrationComponent`, `migrationPlan`,
`migrationComponentFromEmbeddedSql`, `DefinitionError`, `PlanError`),
`Database.PostgreSQL.Migrate.Embed` (`embedMigrationManifest`) and its `RecompilePlugin`,
`Database.PostgreSQL.Migrate.CLI`, `Database.PostgreSQL.Migrate.Test`
(`withMigratedDatabase`), `Kiroku.Store.Migrations.History.Codd` (the 7-entry SamePayload
mapping), `Keiro.EventStream.Validate` (`ValidatedEventStream`, `mkEventStreamOrThrow`),
`Keiro.Telemetry` (`newKeiroMetrics`, `KeiroMetrics`, span helpers), `Keiro.Schema`
(`keiroSchema`), and the settei configuration surface per EP-8's doc and
`settei-example-service`.

**Documents this plan's outputs must stay consistent with:** the EP-6 structure standard
(`architecture/` here — hard dependency), the EP-8 settei standard (`config/` here), EP-7's
API/OTel/health docs (haskell-jitsurei `api/`), EP-2's migrations standard (`migrations/`
here), and both repos' `mori.dhall` registrations, which supply the DocRef keys the
`standards-map.md` and the migrate-keiro-stack citation blocks transcribe. The parent
MasterPlan's registry row for EP-9 and its Progress checklist are updated as milestones land.
