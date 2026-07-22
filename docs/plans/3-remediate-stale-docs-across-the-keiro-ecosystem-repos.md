---
id: 3
slug: remediate-stale-docs-across-the-keiro-ecosystem-repos
title: "Remediate stale docs across the keiro ecosystem repos"
kind: exec-plan
created_at: 2026-07-22T14:55:29Z
master_plan: "docs/masterplans/1-keiro-runtime-standards-docs-and-seihou-blueprints.md"
---

# Remediate stale docs across the keiro ecosystem repos

This ExecPlan is a living document. The sections Progress, Surprises & Discoveries,
Decision Log, and Outcomes & Retrospective must be kept up to date as work proceeds.
If durable project context changes, update or create ADRs in docs/adr/ in the same change.


## Purpose / Big Picture

The keiro runtime reached API stability with the keiro 0.2.0.0 (2026-07-13) and 0.3.0.0
(2026-07-14) releases, and about twenty services are about to be written or refactored on
top of it. A planning research pass catalogued a small set of documentation statements in
five sibling repositories that flatly contradict that shipped reality: a motivation
document that still claims keiro is "in research phase" with "no production-ready Haskell
library yet", a package README that describes shipped features as future work, a version
constant frozen at "0.1.0.0" while the package ships 0.3.0.0, a quick-start that
instructs a migration workflow (codd, `CODD_SCHEMAS`) that was replaced by native
pg-migrate, release notes pinned to a superseded version number, prose describing an
abandoned module layout as if it were current, a migration guide still marked "blocked on
upstream" though the upstream shipped, and a Dhall schema pin that drifted between files
in one repository.

After this plan is complete, every one of those catalogued statements is corrected at its
source. Anyone (human or agent) reading those files — and the downstream doc plans EP-4
through EP-9 of the parent MasterPlan, which cite these repos — will no longer be misled.
Each fix is verifiable with a one-line `grep` (the stale phrase is gone; the corrected
phrase is present), and the one code-level fix (`Keiro.version`) compiles and carries a
changelog entry. Every claim and line number below was verified against the actual file
contents on 2026-07-22 during plan authoring; the offending text is quoted verbatim so an
implementer can locate it even if line numbers drift.


## Progress

- [ ] M1: Rewrite `docs/why-keiro.md` §7.4 ("Pre-1.0 today") in the keiro repo and fix the same stale claim in the "Do **not** choose keiro when" bullet (lines ~788-789).
- [ ] M1: Rewrite the "Status" section of the package README `keiro/README.md` (lines ~86-95).
- [ ] M1: Set `Keiro.version` in `keiro/src/Keiro.hs` to `"0.3.0.0"` with a lockstep comment, and record the fix under `## [Unreleased]` in the repo-root `CHANGELOG.md`.
- [ ] M1: Run the keiro acceptance greps; commit as two commits (docs, fix) with MasterPlan/ExecPlan trailers.
- [ ] M2: Replace the codd/`CODD_SCHEMAS` quick-start paragraph in the kiroku `README.md` with the native `kiroku-store-migrate up` instruction; acceptance grep; commit.
- [ ] M3: Update all four `0.1.0.0` release-status references in settei `README.md` (lines ~12, ~42) and `docs/compatibility.md` (lines ~3, ~74) to `0.2.0.0`; acceptance grep; commit.
- [ ] M4: Fix the stale `description:` field of `danwa-core/danwa-core.cabal` (lines ~7-12).
- [ ] M4: Insert two clearly-marked editorial notes in `docs/masterplans/1-bootstrap-danwa-event-sourced-conversation-substrate.md` (before the package list at line ~90 and before the superseded Decision Log entries at line ~571), each pointing at the reversal entry.
- [ ] M4: Update the status line of `docs/migrate-to-validated-event-stream.md` from "blocked on upstream" to "unblocked — pending adoption".
- [ ] M4: Run the danwa acceptance greps; commit with trailers.
- [ ] M5: Align `mori/tech-radar.dhall` in haskell-jitsurei to the `a3c59033…` mori-schema pin (both imports), verify hashes, confirm `dhall --file mori/tech-radar.dhall` type-checks; commit with trailers.
- [ ] Final: Update the living sections of this plan (Progress, Surprises & Discoveries, Decision Log, Outcomes & Retrospective) and mark the corresponding MasterPlan progress items for EP-3 complete.


## Surprises & Discoveries

Document unexpected behaviors, bugs, optimizations, or insights discovered during
implementation. Provide concise evidence.

(None yet.)


## Decision Log

- Decision: In `docs/why-keiro.md`, fix the "Do **not** choose keiro when" bullet at
  lines 788-789 ("A production-ready library is needed in 2026 (today's keiro is
  pre-implementation; the design is in flight)") together with §7.4, even though the
  catalogue named only §7.4.
  Rationale: It is the identical stale claim in the same file; fixing §7.4 while leaving
  the bullet would leave the document self-contradictory, and the acceptance grep for
  "pre-implementation" would still fire.
  Date: 2026-07-22

- Decision: Leave the rest of `docs/why-keiro.md`'s "once fully implemented in all
  phases" / v1-versus-v2 framing (the intro at lines ~24-28, §7.5, §9) untouched.
  Rationale: Bounded scope. Those passages describe design phasing rather than flatly
  denying the library exists; reworking the whole comparison document is doc-rewrite work
  adjacent to EP-4, not a mechanical stale-statement fix. Only statements the research
  pass catalogued as contradicting shipped reality are corrected here. If the implementer
  judges any of them equally misleading, record it in Surprises & Discoveries and leave
  it for the doc plans.
  Date: 2026-07-22

- Decision: Edit `Keiro.version` directly (plus a lockstep comment and a CHANGELOG entry)
  rather than routing the change through a release process.
  Rationale: Verified during plan authoring that no release automation owns the constant:
  it has zero consumers inside the repo (`Keiro.Telemetry.keiroInstrumentationLibrary`
  hardcodes `libraryVersion = ""`), there is no release script or checklist that bumps
  it, and the repo-root `CHANGELOG.md` carries an `## [Unreleased]` section waiting for
  exactly this kind of entry. A source comment telling future release authors to keep it
  in lockstep with `keiro/keiro.cabal` is the cheapest durable guard available without
  inventing release tooling (out of scope here).
  Date: 2026-07-22

- Decision: In settei, fix all four `0.1.0.0` occurrences across `README.md` (lines 12
  and 42) and `docs/compatibility.md` (lines 3 and 74), not just the two the catalogue
  named; leave `docs/release-checklist.md` (which also says 0.1.0.0) untouched.
  Rationale: The acceptance criterion is a clean `grep -rn "0\.1\.0\.0"` over the two
  catalogued files, and half-fixing a file is worse than not touching it. The release
  checklist, by contrast, is the record of the 0.1.0.0 release preparation as it
  happened; renumbering it is the settei release owner's call, not a mechanical doc fix.
  Date: 2026-07-22

- Decision: In the danwa MasterPlan document, add editorial notes; do not rewrite or
  delete the stale prose or the superseded Decision Log entries.
  Rationale: Explicit instruction from the parent MasterPlan: a completed plan document
  is a historical record. The reversal is already recorded in its Decision Log ("Adopt
  keiro-dsl's configurable module placement (`layout collocated`) …", dated 2026-06-24);
  the notes make the supersession impossible to miss without falsifying history. The
  `danwa-core.cabal` description, by contrast, is live package metadata, not a historical
  record, so it is corrected outright.
  Date: 2026-07-22

- Decision: Verification during plan authoring showed the library-stanza comment at
  `danwa-core/danwa-core.cabal` lines 47-52 (which the research report had flagged
  together with the description) already correctly describes the `Generated.*` + `Holes`
  convention. Only the `description:` field (lines 7-12) is edited.
  Rationale: Read the file before prescribing the edit; the comment needs no change.
  Date: 2026-07-22

- Decision: Commit messages follow Conventional Commits, and every commit in every repo
  carries both git trailers exactly as written below, with paths relative to the
  keiro-runtime-patterns repository even though the commits land in foreign repos:
  `MasterPlan: docs/masterplans/1-keiro-runtime-standards-docs-and-seihou-blueprints.md`
  and `ExecPlan: docs/plans/3-remediate-stale-docs-across-the-keiro-ecosystem-repos.md`.
  Rationale: The parent MasterPlan decided that keiro-runtime-patterns is the
  coordination home and that cross-repo commits point back at its plan files. No
  Intention ID is active (neither this plan's frontmatter nor the MasterPlan's carries
  one), so no `Intention:` trailer is added.
  Date: 2026-07-22

- Decision: For the haskell-jitsurei pin fix, the base `package.dhall` sha256 is copied
  from `mori.dhall` (which already pins commit `a3c59033…`), and the tech-radar extension
  hash is verified by hashing the file at that commit in the local mori-schema clone via
  a temporary git worktree — it was confirmed during plan authoring to be unchanged
  between the two commits (`sha256:13ddc091…`), so only the URLs and the base hash change.
  Rationale: Dhall frozen imports are content-addressed (the sha256 is a semantic hash of
  the resolved expression, independent of the URL), so the correct hashes can be obtained
  and verified entirely offline from the local clone; trust-but-verify beats copying a
  hash this plan asserts.
  Date: 2026-07-22


## Outcomes & Retrospective

Summarize outcomes, gaps, and lessons learned at major milestones or at completion.
Compare the result against the original purpose. Before marking the plan complete,
distill durable project context from the Decision Log, Surprises & Discoveries, and
this section into docs/adr/. Keep task-local execution details here.

(To be filled during and after implementation.)


## Context and Orientation

This plan lives in the coordination repository
`/Users/shinzui/Keikaku/bokuno/keiro-runtime-patterns`, but every file it edits lives in
one of five other repositories. All six repositories are plain git checkouts on the
`master` branch; per the user's standing instructions, commit directly to `master` (no
feature branches) using Conventional Commits.

`docs/adr/` does not exist in this coordination repository — there are no relevant ADRs
to consult, and this plan is not expected to create any: the one durable-context
candidate it touches (the authoritative `Generated.*` + `Holes` module convention in
danwa) is owned by EP-6 of the parent MasterPlan, which will write the standard and any
ADR. (The kiroku repo has its own `docs/adr/` directory — e.g. its ADR 0003 on the
dedicated `kiroku` schema — but this plan does not edit any ADR there either.)

Background you need, in plain language:

- **The keiro release train.** keiro is a Haskell event-sourcing framework at
  `/Users/shinzui/Keikaku/bokuno/keiro`. Its 0.2.0.0 release (2026-07-13) and 0.3.0.0
  release (2026-07-14) are recorded in the repo-root `CHANGELOG.md`; `keiro/keiro.cabal`
  says `version: 0.3.0.0`. The repo-root `README.md` (lines 13-16) is current and is the
  anchor for tone: "**keiro is under active development.** It is already used in
  production, but the public API is not yet stable and may change in breaking ways
  between releases." Its "Status" section (lines 142-151) lists the implemented surface
  and points to `docs/user/production-status.md` ("production-shaped for controlled
  early use, not yet a 1.0"). Two other files in the same repo contradict this and are
  fixed by Milestone 1.

- **kiroku and the migration engine swap.** kiroku, at
  `/Users/shinzui/Keikaku/bokuno/kiroku-project/kiroku`, is the PostgreSQL event store
  under keiro. It recently swapped its migration engine from **codd** (an external
  migration tool configured through `CODD_*` environment variables such as
  `CODD_SCHEMAS`) to a **native pg-migrate component**: migrations are embedded in the
  `kiroku-store-migrations` package and applied by its `kiroku-store-migrate` executable
  (`kiroku-store-migrate up --database-url "$DATABASE_URL"`; when `--database-url` is
  omitted the executable reads the `DATABASE_URL` environment variable). The repo-root
  `README.md` quick-start still instructs the codd path and is fixed by Milestone 2.

- **settei's version drift.** settei, at `/Users/shinzui/Keikaku/bokuno/settei`, is a
  provenance-aware configuration library. All of its publishable packages ship
  `version: 0.2.0.0` (verified across the eight `.cabal` files; `settei/CHANGELOG.md`
  dates 0.2.0.0 at 2026-07-19), but the README "Release status" section and the
  compatibility matrix still say 0.1.0.0. Fixed by Milestone 3.

- **danwa's abandoned flat module layout.** danwa, at
  `/Users/shinzui/Keikaku/bokuno/danwa`, is the DDD reference service. Early in its
  build, modules were planned as a flat layout — generated modules at
  `Danwa.<Concept>.{Domain,Codec,EventStream,Harness}` with no `Generated` path segment,
  and the hand-owned code split into `Danwa.<Concept>.Transducer` and
  `Danwa.<Concept>.Projection`. That plan was **reversed**: the shipped code uses
  keiro-dsl's collocated placement, `Danwa.<Concept>.Generated.{Domain,Codec,
  EventStream,Projection,Harness}` (regenerated on every scaffold, marked
  `-- @generated`) plus a single hand-owned `Danwa.<Concept>.Holes` module per concept
  (created once, never overwritten). The reversal is recorded in the danwa MasterPlan's
  Decision Log entry titled "Adopt keiro-dsl's configurable module placement (`layout
  collocated`) and delete the hand-rolled `domain/normalize-scaffold.py`" (dated
  2026-06-24, at lines ~638-660 of
  `docs/masterplans/1-bootstrap-danwa-event-sourced-conversation-substrate.md`), but the
  earlier prose in the same document and the `danwa-core.cabal` description were never
  reconciled. Separately, danwa's `docs/migrate-to-validated-event-stream.md` is still
  headed "**Status: blocked on upstream.**" although the upstream change it waits for
  (keiro ExecPlan 84, the `ValidatedEventStream` command boundary) shipped in keiro
  0.2.0.0. All fixed by Milestone 4.

- **Dhall pins in haskell-jitsurei.** haskell-jitsurei, at
  `/Users/shinzui/Keikaku/bokuno/haskell-jitsurei`, is a curated Haskell patterns repo
  whose `mori.dhall` (a project manifest for the local `mori` registry tool) and
  `mori/*.dhall` files import a shared schema package from GitHub. Dhall imports here
  are **frozen**: each import URL carries a `sha256:…` which is a *semantic hash* of the
  resolved expression — Dhall verifies the fetched content against it and can satisfy
  the import from its local content-addressed cache without touching the network.
  `mori.dhall` and `mori/checklist.dhall` pin mori-schema commit
  `a3c59033a08c2eaef2cfba4a3c99fc9c192ca6d7`; `mori/tech-radar.dhall` still pins the
  older `f53517e1a532275569bb14a452359f11c3e02c03`. The mori-schema source is cloned
  locally at `/Users/shinzui/Keikaku/bokuno/mori-project/mori-schema` (found via
  `mori registry show shinzui/mori-schema --full`) and contains the `a3c59033…` commit,
  which lets us compute the correct hashes offline. Fixed by Milestone 5.

Terms used below: a **trailer** is a `Key: value` line at the very end of a git commit
message, separated from the body by a blank line. **Conventional Commits** means commit
subjects shaped like `docs(scope): summary` or `fix(scope): summary`.

One hygiene rule for every commit in this plan: the target repos may contain unrelated
untracked files (for example, the keiro repo currently has an untracked
`docs/plans/111-…md`). Always stage by explicit path (`git add <file> …`), never
`git add -A` or `git add .`.


## Plan of Work

The work is five independent milestones, one per repository, in any order (they touch
disjoint repos; the numbering below is just a suggestion). Each milestone follows the
same shape: verify the stale text is still present with a grep, make the prescribed
edits, run the acceptance greps, and commit with the two trailers. Milestone 1 (keiro)
produces two commits because it mixes documentation fixes with a code fix; every other
milestone is a single commit.

Milestone 1 — keiro repo (`/Users/shinzui/Keikaku/bokuno/keiro`). At the end, the
motivation document `docs/why-keiro.md` no longer claims keiro is unimplemented research,
the package README `keiro/README.md` no longer describes shipped subsystems as future
work, and `Keiro.version` reports `"0.3.0.0"` with a changelog entry. Acceptance: the
greps in Validation return empty for the stale phrases and hits for the new ones.

Milestone 2 — kiroku repo (`/Users/shinzui/Keikaku/bokuno/kiroku-project/kiroku`). At the
end, the README "Schema Management" quick-start instructs `kiroku-store-migrate up`
instead of `CODD_SCHEMAS=kiroku`. Acceptance: `grep -rn "CODD_SCHEMAS" README.md` is
empty.

Milestone 3 — settei repo (`/Users/shinzui/Keikaku/bokuno/settei`). At the end, the
README release-status section and the compatibility matrix reference 0.2.0.0.
Acceptance: `grep -rn "0\.1\.0\.0" README.md docs/compatibility.md` is empty.

Milestone 4 — danwa repo (`/Users/shinzui/Keikaku/bokuno/danwa`). At the end, the
`danwa-core.cabal` description matches the shipped `Generated.*` + `Holes` convention,
the danwa MasterPlan document carries two dated editorial notes pointing at its own
reversal entry, and the validated-event-stream migration doc says "unblocked — pending
adoption". Acceptance: the greps in Validation.

Milestone 5 — haskell-jitsurei repo (`/Users/shinzui/Keikaku/bokuno/haskell-jitsurei`).
At the end, `mori/tech-radar.dhall` pins the same mori-schema commit as `mori.dhall`,
with correct frozen hashes, and `dhall --file mori/tech-radar.dhall` type-checks.

After the last milestone, update this plan's living sections and tick the two EP-3 items
in the parent MasterPlan's Progress section
(`docs/masterplans/1-keiro-runtime-standards-docs-and-seihou-blueprints.md` in this
repository) and set EP-3's registry row to Complete — that edit happens in
keiro-runtime-patterns and is committed here with the same two trailers.


## Concrete Steps

Every "current text" block below was read from the named file on 2026-07-22. Before each
edit, confirm the text is still present (a plain `grep` for a distinctive phrase is
enough); if it has drifted, adapt the edit to preserve its intent and record the drift in
Surprises & Discoveries.


### Milestone 1 — keiro

Working directory: `/Users/shinzui/Keikaku/bokuno/keiro`.

**Step 1.1 — rewrite §7.4 of `docs/why-keiro.md`.** The subsection currently reads
(lines 685-697):

```markdown
### 7.4 Pre-1.0 today

The repository is currently in research phase
(`README.md`, "Status"). What exists is design documents and validating
spikes; there is no production-ready Haskell library yet. The MasterPlan
[`docs/masterplans/1-keiro-research-foundation.md`](masterplans/1-keiro-research-foundation.md)
sequences the design effort into six child plans; a separate
implementation MasterPlan ships the production library.

Teams that need to ship today should pick a system that exists today —
DBOS, Temporal, Marten, Eventide. Teams evaluating where to invest for
the next 18 months can reasonably consider keiro now, with the
understanding that the implementation is downstream of the research.
```

This contradicts the same repo's root `README.md` ("It is already used in production")
and the shipped 0.2.0.0/0.3.0.0 releases. Replace the whole subsection (heading kept,
body rewritten) with:

```markdown
### 7.4 Pre-1.0 today

The library is implemented and shipping: the 0.2.0.0 (2026-07-13) and
0.3.0.0 (2026-07-14) releases deliver the event-sourcing core, hardened
replay validation, snapshots, fenced read models and projections, process
managers, routers, durable timers, transactional outbox/inbox, dead-letter
tooling, named-step durable workflows, the typed-spec toolchain
(`keiro-dsl`), and native migrations. Keiro is already used in production
(`README.md`, "Status"), but it is not yet a 1.0: the public API may still
change in breaking ways between releases, and
[`docs/user/production-status.md`](user/production-status.md) describes it
as production-shaped for controlled early use rather than a turnkey,
externally polished framework.

Teams that need a stable, polished 1.0-grade system today should still
weigh DBOS, Temporal, Marten, or Eventide. Teams comfortable tracking a
pre-1.0 API in exchange for the integrated design this document argues
for can adopt keiro now.
```

**Step 1.2 — fix the matching bullet later in the same file.** In the "Do **not**
choose keiro when:" list (lines 788-789), the current bullet reads:

```markdown
- A production-ready library is needed in 2026 (today's keiro is
  pre-implementation; the design is in flight).
```

Replace it with:

```markdown
- A stable 1.0 API contract is required today (keiro ships and is used in
  production, but pre-1.0 breaking changes between releases are still
  expected).
```

**Step 1.3 — rewrite the package README status.** `keiro/README.md` lines 86-95
currently read:

```markdown
## Status

The v1 implementation MasterPlan is complete. The library currently includes
the package scaffold, public `EventStream` and codec contract, command cycle,
snapshots, read models and projections, process managers, and durable timer APIs.

Remaining work is future-facing: the v2 deterministic durable-execution runtime,
exactly-once async projection checkpoint/user-SQL transactions once shibuya
exposes that boundary, and higher-level ergonomic facades over the low-level v1
APIs.
```

This describes durable execution ("the v2 deterministic durable-execution runtime") as
future work although named-step durable workflows shipped in 0.2.0.0, and undersells the
implemented surface. Replace the section body (keep the `## Status` heading) with text
aligned to the authoritative repo-root README:

```markdown
## Status

The event-sourcing core, hardened replay validation, snapshots, fenced read
models and projections, process managers, routers, durable timers,
transactional messaging (outbox/inbox), dead-letter tooling, and named-step
durable workflows are implemented — production-shaped for controlled early
use, not yet a 1.0. See the repository-level [`README.md`](../README.md) and
[`docs/user/production-status.md`](../docs/user/production-status.md) for the
authoritative status.

Remaining work is future-facing: exactly-once async projection
checkpoint/user-SQL transactions once shibuya exposes that boundary, and
higher-level ergonomic facades over the low-level APIs.
```

**Step 1.4 — fix `Keiro.version` (code fix).** `keiro/src/Keiro.hs` lines 55-57
currently read:

```haskell
-- | The Keiro library version, as a 'Text' for display and telemetry.
version :: Text
version = "0.1.0.0"
```

while `keiro/keiro.cabal` declares `version: 0.3.0.0`. Verified: nothing in the
repository consumes `Keiro.version` (the OpenTelemetry instrumentation library in
`keiro/src/Keiro/Telemetry.hs` hardcodes `libraryVersion = ""`), and no release script
or checklist owns the constant — so this plan edits it directly and leaves a guard
comment. Replace the three lines with:

```haskell
-- | The Keiro library version, as a 'Text' for display and telemetry.
-- Keep in lockstep with the @version:@ field in @keiro/keiro.cabal@ when
-- cutting a release.
version :: Text
version = "0.3.0.0"
```

Then record it in the repo-root `CHANGELOG.md`, whose head currently reads:

```markdown
## [Unreleased]

_No unreleased changes._
```

Replace the `_No unreleased changes._` placeholder with:

```markdown
- `keiro`: `Keiro.version` now reports the current package version. It had
  been left at `"0.1.0.0"` since the initial scaffold while the package
  shipped 0.2.0.0 and 0.3.0.0; keep it in lockstep with `keiro/keiro.cabal`
  when cutting a release.
```

Optionally confirm the module still compiles (the edit is a string literal and a
comment, so this is belt-and-braces): from the repo root, `cabal build keiro` should
succeed as before.

**Step 1.5 — commit.** Two commits, staged by explicit path:

```bash
cd /Users/shinzui/Keikaku/bokuno/keiro
git add docs/why-keiro.md keiro/README.md
git commit -m "docs: reflect shipped 0.2/0.3 releases in why-keiro and package README

why-keiro §7.4 claimed keiro was in research phase with no
production-ready library, and keiro/README.md described named-step
durable execution as future v2 work; both contradicted the root README
and the shipped 0.2.0.0/0.3.0.0 releases.

MasterPlan: docs/masterplans/1-keiro-runtime-standards-docs-and-seihou-blueprints.md
ExecPlan: docs/plans/3-remediate-stale-docs-across-the-keiro-ecosystem-repos.md"

git add keiro/src/Keiro.hs CHANGELOG.md
git commit -m "fix(keiro): align Keiro.version with the released package version

Keiro.version still reported \"0.1.0.0\" while keiro.cabal ships
0.3.0.0. No in-repo consumer reads the constant and no release
automation owns it; a lockstep comment and a changelog entry guard
future releases.

MasterPlan: docs/masterplans/1-keiro-runtime-standards-docs-and-seihou-blueprints.md
ExecPlan: docs/plans/3-remediate-stale-docs-across-the-keiro-ecosystem-repos.md"
```


### Milestone 2 — kiroku

Working directory: `/Users/shinzui/Keikaku/bokuno/kiroku-project/kiroku`.

**Step 2.1 — replace the codd quick-start.** `README.md` lines 90-94 (in "Schema
Management") currently read:

```markdown
Run the migration executable from `kiroku-store-migrations` first (with
`CODD_SCHEMAS=kiroku`), then start the application normally with
`withStore (defaultConnectionSettings connString)`. See
[`kiroku-store-migrations/README.md`](kiroku-store-migrations/README.md) for
the migration command and runtime settings.
```

The project moved from codd to a native pg-migrate component; the current command (per
`kiroku-store-migrations/README.md`, verified) is `kiroku-store-migrate up`. Replace the
paragraph with:

````markdown
Run the migration executable from `kiroku-store-migrations` first:

```bash
kiroku-store-migrate up --database-url "$DATABASE_URL"
```

(when `--database-url` is omitted the executable reads the `DATABASE_URL`
environment variable), then start the application normally with
`withStore (defaultConnectionSettings connString)`. See
[`kiroku-store-migrations/README.md`](kiroku-store-migrations/README.md) for
the full command set (`plan`, `list`, `check`, `up`, `verify`, `status`,
`new`, `repair`) and runtime settings.
````

**Step 2.2 — commit.**

```bash
cd /Users/shinzui/Keikaku/bokuno/kiroku-project/kiroku
git add README.md
git commit -m "docs(readme): replace codd quick-start with kiroku-store-migrate

The quick-start still instructed CODD_SCHEMAS=kiroku; migrations moved
to the native pg-migrate component applied via kiroku-store-migrate up.

MasterPlan: docs/masterplans/1-keiro-runtime-standards-docs-and-seihou-blueprints.md
ExecPlan: docs/plans/3-remediate-stale-docs-across-the-keiro-ecosystem-repos.md"
```


### Milestone 3 — settei

Working directory: `/Users/shinzui/Keikaku/bokuno/settei`. All eight publishable
packages ship `version: 0.2.0.0` (verified in the `.cabal` files); four sentences still
say 0.1.0.0.

**Step 3.1 — `README.md` line 12.** Current:

```markdown
Settei 0.1.0.0 is implementation-complete and prepared for its initial release. The eight
```

Change the version only:

```markdown
Settei 0.2.0.0 is implementation-complete and prepared for its initial release. The eight
```

**Step 3.2 — `README.md` line 42.** Current (mid-sentence, inside the "has **not** been
tagged" paragraph):

```markdown
remain tracked in the [release checklist](docs/release-checklist.md). Version 0.1.0.0 is
```

Change to:

```markdown
remain tracked in the [release checklist](docs/release-checklist.md). Version 0.2.0.0 is
```

**Step 3.3 — `docs/compatibility.md` line 3.** Current:

```markdown
This matrix records the workspace actually validated for Settei 0.1.0.0 on 2026-07-20.
```

Change to (the 2026-07-20 validation described in the README post-dates the 0.2.0.0
changelog entry of 2026-07-19, so the date stands):

```markdown
This matrix records the workspace actually validated for Settei 0.2.0.0 on 2026-07-20.
```

**Step 3.4 — `docs/compatibility.md` line 74.** Current:

```markdown
Version 0.1.0.0 is experimental and does not promise semantic stability beyond these
```

Change to:

```markdown
Version 0.2.0.0 is experimental and does not promise semantic stability beyond these
```

Note: `docs/release-checklist.md` also mentions 0.1.0.0; it is deliberately left
untouched (see Decision Log).

**Step 3.5 — commit.**

```bash
cd /Users/shinzui/Keikaku/bokuno/settei
git add README.md docs/compatibility.md
git commit -m "docs: bump release-status references from 0.1.0.0 to 0.2.0.0

README and the compatibility matrix still described 0.1.0.0 as the
prepared release while every publishable package ships 0.2.0.0.

MasterPlan: docs/masterplans/1-keiro-runtime-standards-docs-and-seihou-blueprints.md
ExecPlan: docs/plans/3-remediate-stale-docs-across-the-keiro-ecosystem-repos.md"
```


### Milestone 4 — danwa

Working directory: `/Users/shinzui/Keikaku/bokuno/danwa`.

**Step 4.1 — fix the `danwa-core.cabal` description.** Lines 7-12 currently read:

```cabal
description:
  danwa-core holds the custom prelude (Danwa.Prelude), shared value types, and
  the AppConfig record. Later plans add per-concept verticals: the keiro-DSL-scaffolded
  Danwa.<Concept>.{Domain,Codec,EventStream,Harness} modules (marked -- @generated) and the
  hand-filled Danwa.<Concept>.Transducer / Danwa.<Concept>.Projection modules. Everything
  depends on it.
```

This describes the abandoned flat layout. (The comment above `exposed-modules` at lines
47-52 already describes the shipped convention correctly — verified; do not touch it.)
Replace the description with:

```cabal
description:
  danwa-core holds the custom prelude (Danwa.Prelude), shared value types, the
  AppConfig record, and the per-concept verticals: the keiro-DSL-scaffolded
  Danwa.<Concept>.Generated.{Domain,Codec,EventStream,Projection,Harness}
  modules (marked -- @generated, overwritten on every scaffold) and the
  hand-owned Danwa.<Concept>.Holes module (the keiki transducer + read-model
  apply, created once, never overwritten). Everything depends on it.
```

**Step 4.2 — editorial note near the stale package-list prose in the danwa
MasterPlan.** File:
`docs/masterplans/1-bootstrap-danwa-event-sourced-conversation-substrate.md`. The stale
region is lines ~90-125: the `danwa-core` bullet describes
"`Danwa.<Concept>.{Domain,Codec,EventStream,Harness}` … the hand-filled
`Danwa.<Concept>.Transducer` / `Danwa.<Concept>.Projection` modules", and the "Module
organization across all packages" paragraph ends "There is no `Danwa.Domain.*` or
`Danwa.Generated.*` layer-first tree." Insert the following blockquote as its own
paragraph immediately after the paragraph ending "— see the Decision Log entry
"Eliminate `danwa-postgres`".)" (line 88) and before the `- danwa-core —` bullet
(line 90):

```markdown
> **Editorial note (2026-07-22).** The module layout described in the package
> list and the "Module organization" paragraph below is the abandoned flat
> scheme (no `Generated` path segment; hand code split into
> `Transducer`/`Projection` modules). It was reversed by the Decision Log
> entry "Adopt keiro-dsl's configurable module placement (`layout
> collocated`) …" later in this document: the shipped code uses
> `Danwa.<Concept>.Generated.*` plus a single hand-owned
> `Danwa.<Concept>.Holes` per concept. The prose is preserved unedited as
> the historical record of this completed plan.
```

**Step 4.3 — editorial note before the superseded Decision Log entries.** In the same
file, the superseded entries are at lines ~571-604: the entry beginning "- Decision:
Module organization is **vertical-slice by domain concept**, with scaffolded modules
flat (no `Generated` segment)." and the following entry beginning "- Decision: EP-3
normalizes `keiro-dsl scaffold` output to the vertical-slice scheme above". Insert this
blockquote immediately before the first of them (after the "Date: 2026-06-24" line of
the preceding mmzk-typeid decision and a blank line):

```markdown
> **Editorial note (2026-07-22).** The next two decisions (flat module
> layout without a `Generated` segment; the scaffold-normalization step)
> were superseded by the later entry "Adopt keiro-dsl's configurable module
> placement (`layout collocated`) …" below. They are preserved unedited as
> the historical record.
```

**Step 4.4 — unblock the validated-event-stream migration doc.** File:
`docs/migrate-to-validated-event-stream.md`, lines 10-12. Current:

```markdown
**Status: blocked on upstream.** This migration cannot be executed until keiro
ExecPlan 84 has landed and a keiro + keiro-dsl release exists to pin. The steps
below are the exact, ready-to-apply plan; run them once that release is available.
```

Replace with:

```markdown
**Status: unblocked — pending adoption.** keiro ExecPlan 84 landed and shipped
in keiro 0.2.0.0 (2026-07-13; current release 0.3.0.0, 2026-07-14), so a keiro +
keiro-dsl release exists to pin. The steps below are the exact, ready-to-apply
plan; danwa has not executed them yet (its `cabal.project` still pins the older
cohort).
```

**Step 4.5 — commit.**

```bash
cd /Users/shinzui/Keikaku/bokuno/danwa
git add danwa-core/danwa-core.cabal \
  docs/masterplans/1-bootstrap-danwa-event-sourced-conversation-substrate.md \
  docs/migrate-to-validated-event-stream.md
git commit -m "docs: reconcile stale module-layout prose and migration status

The danwa-core.cabal description still described the abandoned flat
layout (no Generated segment, split Transducer/Projection); the shipped
convention is Generated.* + Holes per the MasterPlan's reversal entry,
which now has editorial notes pointing at it from the stale sections.
migrate-to-validated-event-stream.md is unblocked: keiro 0.2 shipped
ExecPlan 84.

MasterPlan: docs/masterplans/1-keiro-runtime-standards-docs-and-seihou-blueprints.md
ExecPlan: docs/plans/3-remediate-stale-docs-across-the-keiro-ecosystem-repos.md"
```


### Milestone 5 — haskell-jitsurei

Working directory: `/Users/shinzui/Keikaku/bokuno/haskell-jitsurei`.

**Step 5.1 — align the mori-schema pin in `mori/tech-radar.dhall`.** The file currently
begins:

```dhall
let Schema =
      https://raw.githubusercontent.com/shinzui/mori-schema/f53517e1a532275569bb14a452359f11c3e02c03/package.dhall
        sha256:3b79aae9216456678300441ca8616b64a4b4fa520a1286dfcc418f60899d5d4a

let TechRadar =
      https://raw.githubusercontent.com/shinzui/mori-schema/f53517e1a532275569bb14a452359f11c3e02c03/extensions/tech-radar/package.dhall
        sha256:13ddc09176a770d63369db71987441c8be357889c3f3b67f044e855138434e80
```

while `mori.dhall` and `mori/checklist.dhall` both pin commit
`a3c59033a08c2eaef2cfba4a3c99fc9c192ca6d7`. The frozen `sha256:` is a semantic hash of
the resolved expression, so it must match the content at the *new* commit:

- The base `package.dhall` hash at `a3c59033…` is obtained by copying it from
  `mori.dhall` lines 2-3 (it is
  `sha256:18258ef583580a897f4af3e7c86db0342afb42fb40efc535b217ba1089230141`;
  `mori/checklist.dhall` lines 2-3 carry the identical pin, corroborating it).
- The tech-radar extension is not imported by `mori.dhall`, so verify its hash from the
  local mori-schema clone at the pinned commit (offline, no trust required):

```bash
cd /Users/shinzui/Keikaku/bokuno/mori-project/mori-schema
git worktree add /tmp/mori-schema-a3c5 a3c59033a08c2eaef2cfba4a3c99fc9c192ca6d7
dhall hash --file /tmp/mori-schema-a3c5/extensions/tech-radar/package.dhall
git worktree remove /tmp/mori-schema-a3c5
```

Expected output of the `dhall hash` call (verified during plan authoring — the
extension's semantic hash is unchanged between the two commits, because
`extensions/tech-radar/` and the `types/Language.dhall` it imports did not change):

```text
sha256:13ddc09176a770d63369db71987441c8be357889c3f3b67f044e855138434e80
```

Edit `mori/tech-radar.dhall` accordingly: replace
`f53517e1a532275569bb14a452359f11c3e02c03` with
`a3c59033a08c2eaef2cfba4a3c99fc9c192ca6d7` in **both** import URLs, replace the base
hash `sha256:3b79aae9216456678300441ca8616b64a4b4fa520a1286dfcc418f60899d5d4a` with
`sha256:18258ef583580a897f4af3e7c86db0342afb42fb40efc535b217ba1089230141`, and leave the
extension hash `sha256:13ddc091…` as is (it is already correct for the new commit). The
result begins:

```dhall
let Schema =
      https://raw.githubusercontent.com/shinzui/mori-schema/a3c59033a08c2eaef2cfba4a3c99fc9c192ca6d7/package.dhall
        sha256:18258ef583580a897f4af3e7c86db0342afb42fb40efc535b217ba1089230141

let TechRadar =
      https://raw.githubusercontent.com/shinzui/mori-schema/a3c59033a08c2eaef2cfba4a3c99fc9c192ca6d7/extensions/tech-radar/package.dhall
        sha256:13ddc09176a770d63369db71987441c8be357889c3f3b67f044e855138434e80
```

If `dhall hash` ever prints a hash different from the one in the file, use the printed
value — the file's hash must always match the pinned content, and a mismatch means the
extension did change between commits after all (record that in Surprises & Discoveries).

**Step 5.2 — type-check.** Both hashes are already in Dhall's local content-addressed
cache (from `mori.dhall` and the old tech-radar pin respectively), so this works
offline:

```bash
cd /Users/shinzui/Keikaku/bokuno/haskell-jitsurei
dhall --file mori/tech-radar.dhall > /dev/null && echo TYPECHECK-OK
```

Expected output:

```text
TYPECHECK-OK
```

**Step 5.3 — commit.**

```bash
cd /Users/shinzui/Keikaku/bokuno/haskell-jitsurei
git add mori/tech-radar.dhall
git commit -m "fix(mori): align tech-radar mori-schema pin with mori.dhall

tech-radar.dhall pinned mori-schema f53517e while mori.dhall and
checklist.dhall pin a3c59033; the extension's semantic hash is
unchanged, the base package hash comes from mori.dhall.

MasterPlan: docs/masterplans/1-keiro-runtime-standards-docs-and-seihou-blueprints.md
ExecPlan: docs/plans/3-remediate-stale-docs-across-the-keiro-ecosystem-repos.md"
```


### Final step — close out in keiro-runtime-patterns

Working directory: `/Users/shinzui/Keikaku/bokuno/keiro-runtime-patterns`. Update this
plan file's Progress (check items with timestamps), Surprises & Discoveries, Decision
Log (any judgment calls made during implementation), and Outcomes & Retrospective. In
`docs/masterplans/1-keiro-runtime-standards-docs-and-seihou-blueprints.md`, check the two
EP-3 Progress items and set EP-3's Exec-Plan Registry row Status to Complete. Commit both
files together:

```bash
cd /Users/shinzui/Keikaku/bokuno/keiro-runtime-patterns
git add docs/plans/3-remediate-stale-docs-across-the-keiro-ecosystem-repos.md \
  docs/masterplans/1-keiro-runtime-standards-docs-and-seihou-blueprints.md
git commit -m "docs(plans): mark EP-3 stale-doc remediation complete

MasterPlan: docs/masterplans/1-keiro-runtime-standards-docs-and-seihou-blueprints.md
ExecPlan: docs/plans/3-remediate-stale-docs-across-the-keiro-ecosystem-repos.md"
```

No ADR distillation pass is expected: the durable-context candidate touched here (the
authoritative `Generated.*` + `Holes` convention) is EP-6's to codify. If implementation
surfaces genuinely durable context anyway, create `docs/adr/` in this repository and
record it in the same change.


## Validation and Acceptance

Acceptance is behavioral and per item: for each fix, a grep for the stale phrase returns
nothing (exit code 1, no output) and a grep for the corrected phrase shows the new text.
Run each block from the named repo root.

Keiro (`/Users/shinzui/Keikaku/bokuno/keiro`):

```bash
grep -rn "research phase" docs/why-keiro.md            # must return empty
grep -rn "pre-implementation" docs/why-keiro.md        # must return empty
grep -rn "no production-ready" docs/why-keiro.md       # must return empty
grep -n  "already used in production" docs/why-keiro.md   # must show §7.4's new text
grep -n  "v2 deterministic durable-execution" keiro/README.md   # must return empty
grep -n  "production-shaped" keiro/README.md           # must show the new Status text
grep -n  '"0.1.0.0"' keiro/src/Keiro.hs                # must return empty
grep -n  'version = "0.3.0.0"' keiro/src/Keiro.hs      # must show the constant
grep -n  "Keiro.version" CHANGELOG.md                  # must show the Unreleased entry
```

Kiroku (`/Users/shinzui/Keikaku/bokuno/kiroku-project/kiroku`):

```bash
grep -rn "CODD_SCHEMAS" README.md                      # must return empty
grep -n  "kiroku-store-migrate up" README.md           # must show the new quick-start
```

Settei (`/Users/shinzui/Keikaku/bokuno/settei`):

```bash
grep -rn "0\.1\.0\.0" README.md docs/compatibility.md  # must return empty
grep -rn "0\.2\.0\.0" README.md docs/compatibility.md  # must show exactly 4 lines
```

Danwa (`/Users/shinzui/Keikaku/bokuno/danwa`):

```bash
grep -n "Transducer / Danwa.<Concept>.Projection" danwa-core/danwa-core.cabal   # empty
grep -n "Generated" danwa-core/danwa-core.cabal | head -3   # description now mentions Generated.*
grep -c "Editorial note (2026-07-22)" docs/masterplans/1-bootstrap-danwa-event-sourced-conversation-substrate.md   # prints 2
grep -n "blocked on upstream" docs/migrate-to-validated-event-stream.md   # must return empty
grep -n "pending adoption" docs/migrate-to-validated-event-stream.md      # must show the new status
```

Also confirm the edited cabal file still parses: `cabal build danwa-core --dry-run`
exits 0 (it only plans, it does not build; any pre-existing solver noise is fine as long
as the file parses).

Haskell-jitsurei (`/Users/shinzui/Keikaku/bokuno/haskell-jitsurei`):

```bash
grep -c "a3c59033a08c2eaef2cfba4a3c99fc9c192ca6d7" mori/tech-radar.dhall   # prints 2
grep -n "f53517e" mori/tech-radar.dhall                                    # must return empty
dhall --file mori/tech-radar.dhall > /dev/null && echo TYPECHECK-OK        # prints TYPECHECK-OK
```

Finally, in each of the five repos, `git log -2 --format=%B` must show the Conventional
Commits subject and both trailers (`MasterPlan:` and `ExecPlan:` with the
keiro-runtime-patterns-relative paths) on the commits made here, and
`git status --porcelain` must show no unintended staged or committed files (remember the
untracked `docs/plans/111-…md` in keiro stays untracked).


## Idempotence and Recovery

Every step is a guarded text edit and is safe to re-run: each step starts by grepping
for the quoted stale phrase, and if the phrase is already gone (because the step was
already applied) there is nothing to do — skip to that milestone's acceptance greps. No
step is destructive; no databases, generated code, or build artifacts are touched. The
two editorial notes in the danwa MasterPlan are keyed by the literal string "Editorial
note (2026-07-22)" — before inserting, grep for it to avoid duplicate insertion.

If an edit goes wrong before committing, `git checkout -- <file>` in the affected repo
restores the original. After committing, each milestone is one or two self-contained
commits on `master` of its own repo; `git revert <sha>` rolls it back without affecting
the other milestones. The mori-schema worktree in step 5.1 is temporary; if a previous
attempt left it behind, `git worktree remove /tmp/mori-schema-a3c5 --force` (run from
`/Users/shinzui/Keikaku/bokuno/mori-project/mori-schema`) cleans it up, and
`git worktree list` shows whether it exists. The mori-schema clone itself is only ever
read (worktree add/remove), never modified.

If the actual file contents have drifted from the verbatim quotes in Concrete Steps
(someone edited these repos between plan authoring and implementation), do not force the
prescribed replacement text in blindly: re-verify the surrounding text, adapt the edit
to preserve the correction's intent, and record the drift in Surprises & Discoveries.


## Interfaces and Dependencies

No library interfaces change. The only code-level surface touched is the constant
`Keiro.version :: Text` in module `Keiro` (`keiro/src/Keiro.hs` in
`/Users/shinzui/Keikaku/bokuno/keiro`), whose value changes from `"0.1.0.0"` to
`"0.3.0.0"`; its type and export are unchanged, and it has no in-repo consumers.

Tools required on PATH, all already present in this environment:

- `git` — staging by explicit path, committing with trailers, `git worktree` for the
  mori-schema hash verification, `git revert` for recovery.
- `grep` — the verification and acceptance mechanism throughout.
- `dhall` (verified at `~/.nix-profile/bin/dhall`) — `dhall hash --file` to compute the
  semantic hash of the tech-radar extension at the pinned commit, and
  `dhall --file mori/tech-radar.dhall` for the type-check; both work offline via Dhall's
  content-addressed cache.
- `cabal` (optional) — belt-and-braces compile/parse checks in Milestones 1 and 4.

Repositories involved, all local checkouts on `master`:

- `/Users/shinzui/Keikaku/bokuno/keiro` (Milestone 1)
- `/Users/shinzui/Keikaku/bokuno/kiroku-project/kiroku` (Milestone 2)
- `/Users/shinzui/Keikaku/bokuno/settei` (Milestone 3)
- `/Users/shinzui/Keikaku/bokuno/danwa` (Milestone 4)
- `/Users/shinzui/Keikaku/bokuno/haskell-jitsurei` (Milestone 5)
- `/Users/shinzui/Keikaku/bokuno/mori-project/mori-schema` (read-only source for the
  Dhall hash verification; contains commit `a3c59033a08c2eaef2cfba4a3c99fc9c192ca6d7`)
- `/Users/shinzui/Keikaku/bokuno/keiro-runtime-patterns` (this plan and the parent
  MasterPlan; final close-out commit)
