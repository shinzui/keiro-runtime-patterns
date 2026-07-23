---
id: 10
slug: adopt-the-okf-pattern-catalog-profile-for-the-runtime-corpus
title: "Adopt the OKF pattern catalog profile for the runtime corpus"
kind: exec-plan
created_at: 2026-07-22T21:52:15Z
intention: "intention_01ky5agv9gehqa8dbw03cdcpwv"
---

# Adopt the OKF pattern catalog profile for the runtime corpus

This ExecPlan is a living document. The sections Progress, Surprises & Discoveries,
Decision Log, and Outcomes & Retrospective must be kept up to date as work proceeds.
If durable project context changes, update or create ADRs in docs/adr/ in the same change.


## Purpose / Big Picture

After this change, the runtime standards in this repository form one Open Knowledge Format
(OKF) bundle named `runtime-patterns`. A human can open the repository `README.md`, follow a
task-oriented entry point, and progressively browse generated indexes. An agent can ask Mori
for the registered bundle and concept list, inspect one concept with `okf show`, or consume the
whole link graph as JSON without first guessing which top-level directory contains the answer.

The bundle follows a reusable `documentation.patternCatalog` profile published by the
authoritative `shinzui/okf-profiles` repository. This repository consumes a tagged,
hash-pinned profile through `okf/runtime-patterns.dhall`; it does not define a one-off profile
whose name merely repeats this repository. The physical bundle directory is
`runtime-patterns/`, which describes the content rather than using the generic name
`knowledge/`.

Document updates become reviewable state rather than convention alone. Every concept carries
a producer `timestamp`, a lifecycle `status`, tags, and a stable Mori `resource` reference.
The nearest `log.md` records changes for each subject area. A checked-in validation command and
GitHub Actions workflow reject malformed metadata, unknown concept types, broken internal
links, stale generated indexes, and a changed concept whose nearest log was not changed in the
same diff. The observable completion proof is that `okf validate` reports 61 conforming
concepts, `mori registry concepts` lists those concepts from the registered bundle, and the
repository check passes from a clean checkout.


## Progress

- [x] (2026-07-23T04:02:50Z) Implement and validate the reusable
      `documentation.patternCatalog` profile and its three-concept fixture in
      `shinzui/okf-profiles`; committed locally as `611a79b`.
- [x] (2026-07-23T04:05:19Z) Published upstream commit `611a79b` and immutable tag
      `v0.2.0` after explicit approval; the remote tag dereferences to the expected commit and
      its root package type-checks through the tagged raw GitHub URL.
- [x] (2026-07-23T04:10:31Z) Created `runtime-patterns/`, moved the seven existing subject
      areas into it, renamed each subject `README.md` to `overview.md`, and mechanically
      verified that all 60 document bodies differ only by the planned link rewrites.
- [x] (2026-07-23T04:10:31Z) Added OKF frontmatter to the 60 migrated concepts and created
      the root `runtime-patterns/getting-started.md` navigation concept.
- [x] (2026-07-23T04:10:31Z) Rewrote internal and repository-local references, updated all
      60 existing Mori DocRef locations, normalized `keiro-gotchas`, and added the navigation
      DocRef without changing existing DocRef keys.
- [x] (2026-07-23T04:10:31Z) Created eight deterministic `index.md` files and eight scoped
      `log.md` files; strict core, enforced profile, and enforced log validation prints
      `OK: 61 concepts`, while the graph contains 61 nodes and 292 edges.
- [x] (2026-07-23T04:14:14Z) Upgraded the Mori schema pin, declared the
      `runtime-patterns` OKF bundle, refreshed the local registry through the approved targeted
      re-registration workaround, and verified one canonical bundle, 61 live concepts, and 61
      stable DocRefs with no old paths.
- [ ] Add human and agent discovery instructions, a repeatable validation script, and a pinned
      GitHub Actions check for metadata, links, indexes, and logs.
- [ ] Distill the durable OKF ownership, layout, and update-policy decisions into the next
      available ADR and update every affected ADR link after the directory move.


## Surprises & Discoveries

- Discovery: OKF recursively treats every non-reserved Markdown file beneath a bundle root as a
  concept and has no ignore mechanism. `index.md` and `log.md` are the only reserved Markdown
  names. Making the repository root the bundle would therefore absorb `docs/plans/`,
  `docs/adr/`, and `agents/skills/` into the profile.
  Evidence: `Okf.Bundle.discoverMarkdownFiles` in the released `shinzui/okf` source descends
  through every directory and excludes only `isReservedMarkdownFile`, whose list is
  `["index.md", "log.md"]`.

- Discovery: the corpus is already one linked body rather than seven independent bundles.
  There are 60 Markdown files in `keiki/`, `keiro/`, `kiroku/`, `migrations/`, `messaging/`,
  `architecture/`, and `config/`; none has YAML frontmatter. The files contain 329 Markdown
  links, 49 of which cross from one subject directory to another. Splitting by subject would
  prevent OKF from validating those cross-subject edges.
  Evidence: the inventory and link counts were measured on 2026-07-22 with `find` and `rg` from
  the repository root.

- Discovery: the central profile repository already exists upstream even though it is not in
  the local Mori registry. `https://github.com/shinzui/okf-profiles` declares itself the single
  source of truth for reusable profiles, publishes tag `v0.1.0`, and already demonstrates
  composition through `postgresql` and `tanPostgresql`. New documentation profiles belong
  there, not in a generic local `profiles/` directory.

- Discovery: the installed `okf` reports `v0.1.0.0`, while profile and log support entered in
  `0.1.1.0`. Upstream tags and Hackage currently identify `0.1.2.0` as the latest published
  version. The upstream `okf-cli/CHANGELOG.md` also records an untagged `0.1.2.1` fix for a
  missing-file error in the `0.1.2.0` Hackage source distribution. Use the Git tag source for
  `v0.1.2.0`, not the broken Hackage tarball, until a newer fixed release is verified.

- Discovery: OKF's `recommended` profile fields are documentation only and are not currently
  validated. Profiles can require a non-empty extension field such as `status`, but cannot
  restrict that field to an enum. The repository must document the allowed lifecycle words and
  use review plus the checked-in validation script for conventions the profile language cannot
  express.

- Discovery: `okf log --since <ref>` prints a `git:` diagnostic when a concept changed without
  its nearest log, but the command still exits successfully. `--log-enforce` fails date-based
  staleness, yet cannot detect a missing second log entry on a day that already has one. The
  repository check must inspect `--since` diagnostics and fail on lines beginning with `git:`.

- Discovery: the implementation-time dependency check on 2026-07-22 still found no Mori
  registration for `okf-profiles`, no OKF tag newer than `v0.1.2.0`, and no Hackage version
  newer than `okf-cli-0.1.2.0`. The installed `okf v0.1.0.0` lacks profile and log commands, so
  fixture validation used `nix shell github:shinzui/okf/v0.1.2.0#okf-cli`.
  Evidence: `mori registry search okf-profiles`, both upstream `git ls-remote --tags` results,
  Hackage `preferred.json`, and the pinned Nix validation that printed `OK: 3 concepts`.

- Discovery: a concept link to reserved `index.md` is still checked as though the target were
  a normal concept and fails referential-integrity validation as `link to missing concept:
  index`. The task-oriented navigation therefore links the generated root index through its
  absolute GitHub URL, while generated indexes continue to link concepts internally.
  Evidence: the first strict bundle validation failed only on
  `getting-started: link to missing concept: index`; replacing that edge produced
  `OK: 61 concepts`.

- Discovery: `okf index --write` in `v0.1.2.0` canonically ends each generated index with a
  blank line, which Git's default `blank-at-eof` rule reports even though a second generator
  run is byte-for-byte identical.
  Evidence: all eight generated indexes ended in `0a 0a`, `git diff --check` reported only
  those files, and pre/post SHA-256 inventories proved the second generator run was unchanged.

- Discovery: Mori `v1.0.0.0` parses `okfBundles` from the upgraded manifest but omits that
  field from the existing-project diff in `Mori.Modules.Project.Domain.Decider`. Consequently,
  `mori register --local` updates DocRefs and dependencies but cannot add a first OKF bundle to
  an already registered project.
  Evidence: `mori show --json` returned the declared `runtime-patterns` value while
  `mori registry bundles` returned none; the current authoritative source at commit `021ff66`
  passes `okfBundles` into `UpdateProjectData` but its `decide (UpdateProject d)` list contains
  no `diffOkfBundles` operation. A remove dry-run shows the project can be re-created from this
  manifest, but `shinzui/kikan` currently depends on its stable qualified name.


## Decision Log

- Decision: Use one isolated bundle rooted at `runtime-patterns/`.
  Rationale: the name describes this corpus, avoids the generic `knowledge/` bucket, preserves
  all cross-subject edges, and prevents OKF's recursive walker from treating plans, ADRs, and
  agent skills as concepts.
  Date: 2026-07-22

- Decision: Publish the reusable profile as `documentation.patternCatalog` in
  `shinzui/okf-profiles`, and keep only a tagged, hash-pinned consumer wrapper at
  `okf/runtime-patterns.dhall` in this repository.
  Rationale: the profile describes a reusable document structure, not the identity of one
  corpus. The existing profile repository is explicitly the authoritative home and can grow
  by namespaced families such as `documentation`, `data`, and `architecture` without filling
  consuming repositories with unrelated definitions.
  Date: 2026-07-22

- Decision: Keep the existing 60 Mori DocRef keys stable and use their canonical
  `mori://shinzui/keiro-runtime-patterns/docs/<key>` values as concept `resource` fields.
  Rationale: DocRef keys are already the stable cross-repository identities used by agents and
  blueprints. Mori's stored concept-level index and nested concept URIs are deferred, so the
  existing DocRefs remain useful and should not be replaced by speculative URIs.
  Date: 2026-07-22

- Decision: Convert each subject `README.md` into an `Overview` concept named `overview.md`,
  and let `okf index --write` own every `index.md`.
  Rationale: OKF reserves `index.md` and excludes it from the concept graph. Keeping curated
  reading paths in `overview.md` preserves them as validated concepts while generated indexes
  provide deterministic progressive disclosure.
  Date: 2026-07-22

- Decision: Use the concept vocabulary `Navigation`, `Overview`, `Standard`, `Guide`,
  `Pattern`, `Runbook`, `Reference`, and `Gotcha`.
  Rationale: these words describe how a reader should use a document. They map deterministically
  from the existing Mori kinds and filenames while avoiding a repository-specific type for
  every subject area.
  Date: 2026-07-22

- Decision: Create this as a standalone follow-up ExecPlan with intention
  `intention_01ky5agv9gehqa8dbw03cdcpwv`, not as a tenth child of the completed nine-plan
  MasterPlan.
  Rationale: the original MasterPlan's four delivery waves and all nine registered child plans
  are complete. OKF adoption organizes and governs their resulting corpus; it does not reopen
  their implementation scope. The shared intention preserves initiative-level traceability.
  Date: 2026-07-22

- Decision: Preserve the untracked `.mina/` worktree entry and all unrelated user changes.
  Rationale: it predates this plan and is outside OKF adoption. Implementation must never stage,
  edit, remove, or otherwise absorb it.
  Date: 2026-07-22

- Decision: Release the new profile family as `v0.2.0` from upstream commit
  `611a79bf1f478bbd5ccd8a9a7cdcb9123d52a35f`.
  Rationale: `v0.2.0` remains unused and adding the first namespaced profile family is the
  planned compatible minor expansion. The local package semantic hash is
  `sha256:88441b239d99b3dd1cd3e641c882de1c401849e26504c5d76d3da106436034d6`.
  The annotated tag object is `e4b0f8d1f116c9f36681767867f44d702bb66f18`; the tag was
  published after explicit approval and dereferences to the intended commit.
  Date: 2026-07-22

- Decision: Disable only Git's `blank-at-eof` whitespace check for
  `runtime-patterns/index.md` and `runtime-patterns/**/index.md` in `.gitattributes`.
  Rationale: generated indexes must remain exact OKF output and must also be accepted by the
  repository-wide `git diff --check` gate. All other whitespace rules and all non-generated
  files remain covered.
  Date: 2026-07-22

- Decision: Work around Mori's missing existing-project `okfBundles` diff with one approved,
  targeted `mori registry remove shinzui/keiro-runtime-patterns --force` followed immediately
  by `mori register --local`.
  Rationale: the manifest and profile already validated, the dry run showed the exact local
  projection to be recreated, canonical references are based on the stable qualified name, and
  the workaround produced one bundle, 61 concepts, 61 DocRefs, and no stale DocRef paths.
  Date: 2026-07-22


## Outcomes & Retrospective

Summarize outcomes, gaps, and lessons learned at major milestones or at completion.
Compare the result against the original purpose. Before marking the plan complete,
distill durable project context from the Decision Log, Surprises & Discoveries, and
this section into docs/adr/. Keep task-local execution details here.

(To be filled during and after implementation.)


## Context and Orientation

Work from the `keiro-runtime-patterns` repository root. In the environment where this plan was
written, that path is `/Users/shinzui/Keikaku/bokuno/keiro-runtime-patterns`, but all paths in
the plan are repository-relative unless an upstream checkout is explicitly named.

This is a documentation repository, not an application package. Its normative runtime corpus
currently lives directly in seven top-level directories. `keiki/` covers typed transducers;
`keiro/` covers runtime assembly and the DSL; `kiroku/` covers the event store; `migrations/`
covers pg-migrate; `messaging/` covers process managers and transports; `architecture/` covers
service package and module layout; and `config/` covers Settei and Kubernetes. Each directory
has a hand-authored `README.md` that acts as a local index. Together these directories contain
60 Markdown files. `mori.dhall` registers exactly 60 `Schema.DocRef` values whose locations
point to those files.

The repository also contains execution memory in `docs/plans/`, durable architectural
decisions in `docs/adr/`, a completed initiative coordinator in `docs/masterplans/`, and agent
skills in `agents/skills/`. These Markdown files do not belong to the runtime pattern catalog.
The worktree also contains an unrelated untracked `.mina/` entry. Do not include any of these
areas in the OKF bundle or alter `.mina/`.

OKF, or Open Knowledge Format, is a directory-tree convention implemented by the `okf-core`
library and `okf` command-line tool from the Mori project `shinzui/okf`. A normal Markdown file
beneath a bundle root is a concept. Its bundle-relative path without `.md` is its concept ID;
for example, after the move `runtime-patterns/keiro/runtime-assembly.md` has concept ID
`keiro/runtime-assembly`. YAML frontmatter supplies machine-readable `type`, `title`,
`description`, `timestamp`, `resource`, and `tags`. Markdown links between concepts become
directed graph edges. A dangling internal Markdown link is a validation failure.

OKF reserves `index.md` and `log.md`. Generated `index.md` files list immediate subdirectories
and concepts grouped by type, but are not concepts themselves. A `log.md` is a dated update log
for its directory. A concept uses the closest enclosing log; therefore the target layout needs
one root log and one log in each of the seven subject directories.

An OKF profile is a Dhall value describing house conventions layered on top of permissive OKF.
The profile can allow or reject concept types, require non-empty frontmatter fields, constrain a
type's segment-glob path, require a `resource` URI scheme, and require a specific `# Schema`
table shape. Profile violations are advisory unless `--profile-enforce` is passed. This plan
uses strict core validation and profile enforcement together.

The canonical profile schema is published by `shinzui/okf` under
`okf-core/dhall/package.dhall`. Reusable profile values live in the separate upstream
repository `https://github.com/shinzui/okf-profiles`. That repository currently has a flat
`profiles/` directory, root `package.dhall`, schema-completion helpers under `Profile/`, and tag
`v0.1.0`. It is not currently returned by `mori registry search okf-profiles`; use Mori first,
then clone the authoritative GitHub repository if it remains absent from the local registry.

The repository's current `mori.dhall` schema import is stale. `mori status` reports hash
`18258ef58358` and instructs the operator to run `mori schema upgrade`. The current schema's
`Schema.Project` record adds `okfBundles : List Schema.OkfBundle.Type`. Each `OkfBundle` has a
unique `name`, project-relative `path`, optional profile path or URL, OKF format version, and
optional description. After local registration, `mori registry bundles` reads stored bundle
metadata, while `mori registry concepts` walks the bundle live through `okf-core`.

The content-to-type conversion is deterministic. Each current `README.md` becomes
`overview.md` with type `Overview`. Any file named `gotchas.md` becomes `Gotcha`. For every
other file, existing Mori kind `BestPractice` becomes `Standard`, `Guide` remains `Guide`,
`Pattern` remains `Pattern`, `Runbook` remains `Runbook`, and `Reference` remains `Reference`.
The two current `Notes` entries are both gotcha files. This produces 7 overviews, 24 standards,
17 guides, 5 patterns, 3 runbooks, 1 reference, and 3 gotcha concepts. Adding
`getting-started.md` as `Navigation` produces 61 concepts total.

For every migrated concept, take `title` from the existing H1 without changing the H1, take
`description` from the matching `mori.dhall` DocRef, and use the DocRef's canonical Mori URI as
`resource`. Set `status: current` because this is the accepted corpus produced by the completed
initiative; `status` describes the document, not whether every API mentioned inside it is
stable. Set `tags` to at least the subject directory and file slug, for example
`[keiro, runtime-assembly]`. Set `timestamp` to the last material commit timestamp of the
original file, in RFC 3339 form, rather than pretending that a path-only move re-reviewed the
content. Preserve unknown frontmatter keys if implementation encounters any, although the
initial inventory found none.

Three existing concept documents link to ADRs and four occurrences link to EP-5 outside the
future bundle. A relative link that escapes `runtime-patterns/` cannot be an OKF concept edge.
Rewrite these as absolute GitHub URLs to the owning repository so humans retain navigation and
OKF correctly treats them as external. Links between the seven pattern areas remain internal
and must be rewritten from `README.md` to `overview.md`. Links from ADRs, plans, the MasterPlan,
and other repository files into the moved corpus must gain the `runtime-patterns/` path prefix.

The relevant durable decision is [ADR 0006](../adr/0006-separate-pattern-product-and-general-haskell-docs.md).
It declares this repository the terse, prescriptive, agent-discoverable source for runtime
implementation standards, distinct from the product website and general Haskell guidance.
OKF adoption strengthens that decision; it must not pull the Fumadocs product site or
`haskell-jitsurei` content into this bundle. ADR 0007 was reviewed but does not change the
structural work: it keeps Kiroku in scope and Kioku out of scope. At implementation completion,
create the next-numbered ADR recording the durable OKF bundle, profile ownership, and update-log
policy; do not assume that `0008` remains free.


## Plan of Work

### Milestone 1: publish the reusable documentation profile

First establish the reusable contract in `shinzui/okf-profiles`; the runtime corpus must consume
an authoritative release rather than copying a profile locally. Run `mori registry search
okf-profiles` before locating source. If Mori still has no project, clone
`https://github.com/shinzui/okf-profiles.git` to a specific sibling checkout and record that
Mori did not provide a local path. Do not search `/` or `/nix/store`.

In that checkout, add `profiles/documentation/pattern-catalog.dhall`. Build it with the existing
`Profile::{ ... }` and `TypeRule::{ ... }` completion records, not against a hand-copied schema.
The complete value is:

```dhall
--| Profile for a Mori-addressable catalog of implementation patterns and standards.
let Profile = ../../Profile/Type.dhall

let TypeRule = ../../Profile/TypeRule.dhall

let rule =
      \(conceptType : Text) ->
      \(path : Text) ->
        TypeRule::{
        , type = conceptType
        , pathPattern = Some path
        , resourceScheme = Some "mori"
        }

in  Profile::{
    , name = "mori-documentation-pattern-catalog"
    , frontmatter =
      { required =
        [ "type"
        , "title"
        , "description"
        , "timestamp"
        , "resource"
        , "tags"
        , "status"
        ]
      , recommended = [ "sources", "supersedes" ]
      }
    , types =
      [ rule "Navigation" "getting-started"
      , rule "Overview" "*/overview"
      , rule "Standard" "*/**"
      , rule "Guide" "*/**"
      , rule "Pattern" "*/**"
      , rule "Runbook" "*/**"
      , rule "Reference" "*/**"
      , rule "Gotcha" "*/**"
      ]
    }
```

Add `profiles/documentation/package.dhall` exporting the value as
`{ patternCatalog = ./pattern-catalog.dhall }`. Add a `documentation` field importing that
package to the upstream root `package.dhall`; keep the existing `postgresql` and
`tanPostgresql` exports intact. Update the upstream `README.md` layout, consumption example,
profile catalog, and compatibility notes so future profile families use namespaced directories
without moving or breaking the existing flat exports.

Add a committed conforming fixture at
`fixtures/documentation-pattern-catalog/`. It contains `getting-started.md`,
`runtime/overview.md`, and `runtime/startup.md` with full profile metadata, resolvable internal
links, and `mori://example/patterns/docs/...` resource values. The fixture makes profile
validation independent of this repository's migration. Type-check the root package and the new
profile, then validate the fixture with OKF. The milestone is independently complete when Dhall
type-checks and `okf validate` reports exactly three concepts with no `profile:` lines.

Prepare a Conventional Commit named `feat(documentation): add pattern catalog profile`, with
the ExecPlan and Intention trailers from this plan. Verify upstream tags again. If `v0.2.0` is
still unused, it is the intended next profile release because the package gains a new namespaced
family; if it is no longer free, choose the next compatible minor tag and record the choice in
this plan. Publishing the commit and tag changes an external repository, so request explicit
user approval immediately before pushing. The next milestone may proceed only after the tag is
fetchable from GitHub; otherwise use a pushed immutable commit temporarily and record the
release blocker.

### Milestone 2: migrate the corpus into the runtime-patterns bundle

Create the isolated `runtime-patterns/` directory in this repository. Move `keiki/`, `keiro/`,
`kiroku/`, `migrations/`, `messaging/`, `architecture/`, and `config/` beneath it with `git mv`.
Within each moved directory rename `README.md` to `overview.md`. Do not copy files: Git must
recognize the migration as moves so history remains navigable.

Before moving, capture each source file's latest commit timestamp with `git log -1 --format=%cI
-- <path>`; use that timestamp in the new frontmatter. Add frontmatter to all 60 documents using
the deterministic mapping in Context and Orientation. The document body, H1, code examples,
and prescriptive wording remain unchanged except where links must be repaired. Use the existing
Mori DocRef description verbatim and the canonical URI printed by `mori show --json` or derived
from the stable key. A representative migrated concept is:

```yaml
---
type: Standard
title: Keiro runtime assembly
description: Store acquisition, validated event streams, resource effects, options, and startup order
timestamp: 2026-07-22T00:00:00Z
resource: mori://shinzui/keiro-runtime-patterns/docs/keiro-runtime-assembly
tags: [keiro, runtime-assembly]
status: current
---
```

Use the actual historical timestamp and exact existing H1/DocRef description rather than this
illustrative timestamp and title. YAML lists must remain lists of text because strict OKF
validation checks the shape of `tags`.

Add `runtime-patterns/getting-started.md` as the only root concept. Give it type `Navigation`, a
stable new DocRef-backed `resource`, and task-oriented routes rather than another package list.
It should answer at least: starting a new service, defining an aggregate, assembling the runtime,
choosing a transport, implementing process coordination, evolving events or database schemas,
structuring packages/modules, configuring a service, and operating Kubernetes. Each answer
links to one concept that gives the safest starting point and may link to a subject overview for
depth.

Rewrite all links between subject overviews from `README.md` to `overview.md`. Because all seven
areas move under the same parent, their other relative cross-area paths should retain the same
shape. Convert concept-to-ADR and concept-to-plan links that leave the bundle into absolute
`https://github.com/shinzui/keiro-runtime-patterns/blob/master/...` URLs. Update every live
Markdown link elsewhere in this repository that targets a moved concept, especially
`docs/adr/*.md`, `docs/plans/*.md`, and
`docs/masterplans/1-keiro-runtime-standards-docs-and-seihou-blueprints.md`. In historical command
transcripts, preserve a deliberately historical path only when changing it would falsify the
record; add a nearby note explaining the new location. A final repository-wide `rg` audit must
distinguish intentional history from broken navigation.

Update all 60 existing DocRef `LocalFile` values in `mori.dhall` to begin with
`runtime-patterns/`; change overview locations to end with `overview.md`. Do not rename their
keys. Normalize `keiro-gotchas` from `Schema.DocKind.BestPractice` to `Schema.DocKind.Notes` so
all three `Gotcha` concepts map consistently. Add one Guide DocRef named
`runtime-patterns-getting-started` for the new navigation concept.

At the end of the milestone, ordinary Git history shows moves rather than duplicate add/delete
pairs, every concept has complete frontmatter, and a provisional validation against the
upstream profile succeeds structurally. Generated indexes and logs arrive in the next milestone.

### Milestone 3: add progressive indexes and update logs

Create one root `log.md` and one in each subject directory. Use `okf log add` rather than
hand-formatting logs. The root entry records creation of the task-oriented navigation concept;
each subject log records migration of that subject to the pattern-catalog profile. Use kind
`Migration` and a concise description. Because logs are scoped by nearest directory, every
concept must resolve to one of these eight logs.

Run `okf index runtime-patterns --write` to generate `runtime-patterns/index.md` and one
`index.md` for each subject directory. Do not add prose manually to generated indexes. The
curated prose is in `getting-started.md` and each `overview.md`, both of which remain graph
concepts.

Create a root `README.md` outside the bundle for GitHub visitors. It explains the corpus's
normative role from ADR 0006, links first to `runtime-patterns/getting-started.md`, links to the
generated root index, names the OKF/Mori discovery commands, and explains the update contract in
one short section. Add a root `AGENTS.md` section that tells coding agents to run Mori discovery
before guessing at a document, use `okf show runtime-patterns <concept-id>` for focused context,
and update the concept timestamp plus nearest log when changing content. Preserve the dependency
lookup and filesystem safety instructions already supplied to agents; if an `AGENTS.md` appears
before implementation, merge rather than replace it.

Validate with strict core rules, enforced profile rules, and enforced log-date rules. The
milestone is complete when validation prints `OK: 61 concepts`, the graph contains 61 nodes and
at least one edge, and rerunning `okf index --write` creates no diff.

### Milestone 4: register the bundle in Mori

Create `okf/runtime-patterns.dhall` as the consumer boundary. It imports the tagged upstream
`okf-profiles/package.dhall` and returns `profiles.documentation.patternCatalog`. Author the
tagged import without a hash:

```dhall
let profiles =
      https://raw.githubusercontent.com/shinzui/okf-profiles/v0.2.0/package.dhall

in  profiles.documentation.patternCatalog
```

Then run `dhall freeze --inplace okf/runtime-patterns.dhall`; the command adds the real semantic
hash to the checked-in import. Replace `v0.2.0` with the recorded release tag if Milestone 1
selected a later compatible tag. Never leave `master` or an unhashed import in the committed
file.

Run `mori schema upgrade` from this repository and inspect only the resulting `mori.dhall` diff.
The command has no dry-run flag, but the file is version-controlled and can be restored by
applying the inverse patch if the migration is unsuitable. Do not use `git reset` or
`git checkout` to recover. Add `shinzui/okf` to the project dependencies if the upgraded
manifest does not already contain it. Do not add `shinzui/okf-profiles` until that project is
actually registered in Mori; the pinned URL is the truthful dependency boundary meanwhile.

Add this bundle declaration to the upgraded project record:

```dhall
, okfBundles =
  [ Schema.OkfBundle::{
    , name = "runtime-patterns"
    , path = "runtime-patterns"
    , profile = Some "okf/runtime-patterns.dhall"
    , okfVersion = "0.1"
    , description = Some
        "Prescriptive Keiro runtime standards, patterns, guides, and runbooks"
    }
  ]
```

Type-check and validate `mori.dhall`, then run `mori register --local`. Registration's profile
checks are advisory, so the enforced `okf validate` command remains the acceptance gate. Verify
the registry with `mori registry bundles`, `mori registry concepts`, and `mori registry docs`.
The expected canonical bundle reference is
`mori://shinzui/keiro-runtime-patterns/okf/runtime-patterns`; concept discovery should list 61
concepts, and DocRef discovery should list 61 entries with their stable keys.

### Milestone 5: enforce the authoring and update contract

Add executable `scripts/check-runtime-patterns`. It accepts an optional Git base ref. It verifies
that the `okf` CLI supports profiles and logs, type-checks `okf/runtime-patterns.dhall` and
`mori.dhall`, runs strict/profile/log validation, regenerates indexes and fails if tracked index
files differ, and generates the graph to prove serialization succeeds. When a valid base ref is
provided, it also runs `okf log runtime-patterns --since <ref>`, captures stderr, and fails if
any line begins with `git:`. If the base ref does not exist, it prints a clear skip for only the
diff-aware log check; all deterministic validation still runs.

Add `.github/workflows/runtime-patterns-okf.yml`. Checkout full history, install Nix, and invoke
the check in a shell containing the Git-tag source
`github:shinzui/okf/v0.1.2.0#okf-cli`, `nixpkgs#dhall`, and `nixpkgs#ripgrep`. Do not install
`okf-cli-0.1.2.0` from Hackage because its published source distribution omits embedded help
files. Recheck authoritative tags and Hackage at implementation time; if a fixed release newer
than `0.1.2.0` exists, update the pin and record why in this plan before using it.

For pull requests, pass the pull request base SHA to the script. For pushes, pass the event's
`before` SHA unless it is the all-zero initial-push value. The workflow must use
`actions/checkout@v4` with `fetch-depth: 0` so `okf log --since` can inspect both sides of the
diff. The local check and workflow are complete when a clean tree passes, changing a concept
without its log fails, adding the log makes it pass, and a manually edited generated index fails
until it is regenerated.

Finally, create or update the next available ADR under `docs/adr/` with the title “Adopt OKF for
the runtime pattern corpus.” Record the isolated `runtime-patterns/` root, central
`documentation.patternCatalog` ownership, stable DocRef resource join, generated-index policy,
and timestamp-plus-nearest-log update rule. Update links in ADR 0006 and every other ADR whose
Related Guidance moved. Complete this plan's Outcomes & Retrospective and ADR distillation pass.


## Concrete Steps

Start from `/Users/shinzui/Keikaku/bokuno/keiro-runtime-patterns`. Confirm the worktree and
dependency sources without traversing `/` or `/nix/store`:

```bash
git status --short
mori registry search okf-profiles
mori registry show shinzui/okf --full
mori registry show shinzui/mori --full
git -C /Users/shinzui/Keikaku/bokuno/okf ls-remote --tags origin
```

Expected initial facts include the unrelated `.mina/` entry, no locally registered
`okf-profiles` project, and OKF tags through `v0.1.2.0`. If these facts changed, update this plan
before choosing pins or paths.

Obtain a dedicated upstream profile checkout only if Mori still cannot provide one:

```bash
cd /Users/shinzui/Keikaku/bokuno
git clone https://github.com/shinzui/okf-profiles.git okf-profiles
cd okf-profiles
git status --short
git tag --sort=-version:refname
```

Use `apply_patch` for every authored file. After adding the namespaced profile, package export,
fixture, and README documentation, validate from the `okf-profiles` checkout:

```bash
dhall type --file package.dhall
dhall type --file profiles/documentation/pattern-catalog.dhall
okf validate fixtures/documentation-pattern-catalog \
  --strict \
  --profile profiles/documentation/pattern-catalog.dhall \
  --profile-enforce
```

Expected terminal proof:

```text
OK: 3 concepts
```

Before publishing, inspect the upstream diff and construct a Conventional Commit with both
trailers. Do not include unrelated changes:

```bash
git diff --check
git status --short
git add README.md package.dhall profiles/documentation fixtures/documentation-pattern-catalog
git diff --cached --check
git commit -m "feat(documentation): add pattern catalog profile" \
  -m "ExecPlan: docs/plans/10-adopt-the-okf-pattern-catalog-profile-for-the-runtime-corpus.md" \
  -m "Intention: intention_01ky5agv9gehqa8dbw03cdcpwv"
```

After explicit approval, push the commit, tag the chosen release, and verify the remote tag with
`git ls-remote --tags origin`. Record the exact commit, tag, and package semantic hash in this
plan's Surprises & Discoveries or Decision Log.

Back in `keiro-runtime-patterns`, inventory before moving so counts can be compared later:

```bash
cd /Users/shinzui/Keikaku/bokuno/keiro-runtime-patterns
find keiki keiro kiroku migrations messaging architecture config -type f -name '*.md' | sort
rg -n '\]\([^)]*\.md(?:#[^)]*)?\)' \
  keiki keiro kiroku migrations messaging architecture config
rg -n 'Schema\.DocRef::' mori.dhall
```

Record each file's timestamp before moving. Then create `runtime-patterns/` and use `git mv` for
the seven directories and seven overview files. A representative sequence is:

```bash
mkdir -p runtime-patterns
git mv keiki runtime-patterns/keiki
git mv keiro runtime-patterns/keiro
git mv kiroku runtime-patterns/kiroku
git mv migrations runtime-patterns/migrations
git mv messaging runtime-patterns/messaging
git mv architecture runtime-patterns/architecture
git mv config runtime-patterns/config
git mv runtime-patterns/keiki/README.md runtime-patterns/keiki/overview.md
```

Repeat the final rename for the other six directories. Add metadata and rewrite links with
reviewed `apply_patch` edits. Do not use a blind repository-wide replacement for prose,
transcripts, or unrelated plans. After the migration, audit paths:

```bash
find runtime-patterns -type f -name '*.md' | sort
rg --files-without-match '^---$' runtime-patterns -g '*.md' -g '!index.md' -g '!log.md'
rg -n '\]\((\.\./)+docs/[^)]+\)' runtime-patterns
rg -n '/README\.md|\(README\.md' runtime-patterns
```

The second, third, and fourth commands should produce no output once all concepts are annotated
and links are valid. The final corpus count before adding reserved files should be 61 normal
concepts.

Create logs through the CLI so their format is canonical:

```bash
okf log add runtime-patterns getting-started \
  --kind Migration \
  -m "Created task-oriented navigation for the OKF pattern catalog"
okf log add runtime-patterns keiki/overview \
  --kind Migration \
  -m "Adopted the OKF pattern-catalog profile for Keiki guidance"
```

Repeat the subject command for `keiro`, `kiroku`, `migrations`, `messaging`, `architecture`, and
`config`. Then generate indexes and validate:

```bash
okf index runtime-patterns --write
okf validate runtime-patterns \
  --strict \
  --profile okf/runtime-patterns.dhall \
  --profile-enforce \
  --log-enforce
okf graph runtime-patterns --json
okf show runtime-patterns messaging/process-managers
```

Expected validation output:

```text
OK: 61 concepts
```

Freeze and type-check the local consumer profile:

```bash
dhall freeze --inplace okf/runtime-patterns.dhall
dhall freeze --check okf/runtime-patterns.dhall
dhall type --file okf/runtime-patterns.dhall
```

Upgrade and register Mori only after the bundle validates:

```bash
mori schema upgrade
git diff -- mori.dhall
mori validate
mori register --local
mori registry bundles shinzui/keiro-runtime-patterns
mori registry concepts shinzui/keiro-runtime-patterns --bundle runtime-patterns
mori registry docs shinzui/keiro-runtime-patterns
```

Expected bundle evidence contains:

```text
runtime-patterns
mori://shinzui/keiro-runtime-patterns/okf/runtime-patterns
```

Run the final repository check from a clean checkout or after staging the intended changes:

```bash
scripts/check-runtime-patterns HEAD^
git diff --check
git status --short
```

When committing implementation work in this repository, use Conventional Commits and include
both trailers, for example:

```text
docs(okf): adopt the runtime pattern catalog

ExecPlan: docs/plans/10-adopt-the-okf-pattern-catalog-profile-for-the-runtime-corpus.md
Intention: intention_01ky5agv9gehqa8dbw03cdcpwv
```


## Validation and Acceptance

Acceptance is behavioral and must be demonstrated from a clean checkout, not inferred from file
presence.

The reusable profile is accepted when its upstream package and value type-check, its committed
fixture passes strict enforced validation with exactly three concepts, and a tagged, immutable
profile package can be fetched and hash-checked by `dhall freeze --check`. The upstream root
package exposes `documentation.patternCatalog` without removing the existing `postgresql` or
`tanPostgresql` exports.

The local bundle is accepted when this command exits zero and prints exactly `OK: 61 concepts`:

```bash
okf validate runtime-patterns \
  --strict \
  --profile okf/runtime-patterns.dhall \
  --profile-enforce \
  --log-enforce
```

Every normal concept must have non-empty `type`, `title`, `description`, `timestamp`,
`resource`, `tags`, and `status`; every type must be in the eight-value vocabulary; every
concept must match its type's path rule; and every resource must use `mori://`. All internal
Markdown links must resolve. The bundle contains no plans, ADRs, MasterPlans, or agent skill
documents.

Progressive discovery is accepted when `runtime-patterns/index.md` lists the seven subjects and
`getting-started`, each subject index lists its immediate concepts by type, and a second
`okf index runtime-patterns --write` leaves the worktree unchanged. The root `README.md` routes a
new visitor to `runtime-patterns/getting-started.md`. `okf show runtime-patterns
messaging/process-managers` must print the concept ID, type, title, description, and document
body without requiring a user to locate the file manually.

Graph discovery is accepted when `okf graph runtime-patterns --json` produces parseable JSON
with 61 nodes and a non-empty edge list. Every edge source and target must appear among those
nodes. Links to repository plans and ADRs appear as external URLs and therefore do not produce
dangling OKF edges.

Update tracking is accepted with a deliberate negative test. Change one sentence and its
`timestamp` in a concept without editing the nearest `log.md`, then run
`scripts/check-runtime-patterns <base-ref>`; it must exit non-zero and identify the changed
concept. Add an `okf log add` entry in the concept's directory and rerun; it must pass. Revert
the test-only sentence through an `apply_patch` edit rather than a destructive Git command.

Mori discovery is accepted after `mori register --local` when
`mori registry bundles shinzui/keiro-runtime-patterns` prints the `runtime-patterns` row and its
canonical bundle URI, `mori registry concepts ... --bundle runtime-patterns` lists 61 live
concepts, and `mori registry docs` lists 61 stable DocRefs with paths beneath
`runtime-patterns/`. Registration warnings do not substitute for enforced OKF validation.

Repository acceptance requires `scripts/check-runtime-patterns <valid-base-ref>`, `mori
validate`, `dhall freeze --check okf/runtime-patterns.dhall`, and `git diff --check` all to exit
zero. The GitHub Actions workflow must reproduce the script from a clean Linux checkout. The
unrelated `.mina/` worktree entry must remain unmodified and unstaged.


## Idempotence and Recovery

Profile type-checking, OKF validation, graph generation, Mori validation, and registry listing
are read-only and safe to rerun. `okf index --write` is deterministic; a second run should be a
no-op. `mori register --local` refreshes the project projection and is safe to rerun after a
manifest change. `dhall freeze --check` is read-only; `dhall freeze --inplace` is deterministic
for the same remote content and should only be rerun when the tagged import changes.

`okf log add` is intentionally not idempotent: repeating it appends another bullet. Before
retrying, inspect the target `log.md`; if the intended entry already exists, do not run the
command again. If a duplicate is created, remove only that duplicate with `apply_patch` and
revalidate the log.

Directory moves are recoverable through Git because `git mv` changes only tracked paths. If the
migration is interrupted, inspect `git status --short`, finish missing moves, and continue; do
not run `git reset --hard`, `git checkout --`, or delete broad directories. If frontmatter edits
are partly applied, `rg --files-without-match '^---$' runtime-patterns -g '*.md' -g '!index.md'
-g '!log.md'` identifies remaining concepts. Preserve all unrelated dirty or untracked files,
particularly `.mina/`.

`mori schema upgrade` mutates `mori.dhall` and has no dry-run flag. Run it with an otherwise
understood worktree, inspect `git diff -- mori.dhall`, and correct an unsuitable migration with
an explicit inverse `apply_patch`. Do not restore the whole file in a way that discards DocRef
edits made by this plan.

Publishing the upstream profile commit and tag is the only external, difficult-to-reverse
operation. Validate locally first, verify the exact remote and unused tag, and request approval
before pushing. Never move or retag a published version. If publication is unavailable, stop at
the locally validated upstream commit, record the blocker, and do not commit a consumer import
that points to a nonexistent tag. Once a profile tag is published, future changes require a new
tag and an explicit pin update in `okf/runtime-patterns.dhall`.

If the GitHub Actions check exposes platform-specific tool problems, keep the local script as
the source of truth and adjust only the workflow's tool provisioning. Do not weaken
`--profile-enforce`, `--log-enforce`, link validation, or index-diff checks to make CI green.


## Interfaces and Dependencies

`shinzui/okf` owns the format engine and CLI. The relevant released source interfaces are
`Okf.Bundle.walkBundle`, which recursively discovers concepts;
`Okf.Validation.validateBundle`, which checks documents and referential integrity;
`Okf.Profile.loadProfileFile` and `Okf.Profile.validateProfile`, which load and apply the Dhall
profile; `Okf.Index.writeBundleIndexes`, which owns deterministic `index.md` files;
`Okf.Graph.buildGraph`, which emits concept nodes and Markdown-link edges; and the log functions
used by `okf log`. No Haskell code in this repository calls these modules directly; the stable
boundary is the `okf` executable.

The required command surface is:

```text
okf validate BUNDLE --strict --profile PROFILE --profile-enforce --log-enforce
okf index BUNDLE --write
okf log BUNDLE --since REF
okf log add BUNDLE CONCEPT_ID --kind KIND -m MESSAGE
okf graph BUNDLE --json
okf show BUNDLE CONCEPT_ID
```

Pin CLI provisioning to the verified Git source tag `v0.1.2.0` unless implementation-time
registry and upstream-tag checks identify a newer fixed release. Profile and log support require
at least `0.1.1.0`. Do not select bounds or workarounds from memory: rerun Mori lookup, upstream
tag inspection, and Hackage preferred-version inspection before changing the pin.

`shinzui/okf-profiles` owns reusable convention values. Its root `package.dhall` must expose a
new field with this effective interface:

```dhall
{ documentation =
  { patternCatalog :
      { name : Text
      , okfVersion : Text
      , frontmatter : { required : List Text, recommended : List Text }
      , allowUnknownTypes : Bool
      , types : List
          { type : Text
          , pathPattern : Optional Text
          , resourceScheme : Optional Text
          , requireSchemaSection : Bool
          , schemaColumns : List Text
          }
      }
  }
}
```

This is an excerpt, not a replacement for the existing root fields. The profile schema remains
owned by OKF and imported through `okf-profiles/Profile/okf.dhall`; the new profile value must use
the existing completion helpers.

`shinzui/mori` owns project and bundle discovery. After schema upgrade, this repository uses
`Schema.OkfBundle.Type` through record completion. The on-disk bundle declaration has name and
path `runtime-patterns`, profile path `okf/runtime-patterns.dhall`, format version `0.1`, and a
description. `mori register --local` projects it into the local registry. `mori registry
concepts` reads concepts live from disk; it does not yet provide stored cross-bundle concept
search. Existing `Schema.DocRef` values therefore remain the stable per-document registry
interface.

The repository-level authoring interface is `scripts/check-runtime-patterns [BASE_REF]`. With no
base ref it performs deterministic schema, bundle, index, graph, and timestamp-versus-log-date
checks. With a valid base ref it additionally enforces that each changed concept's nearest log
changed in the same diff. Exit zero means the corpus is fit to commit; any diagnostic means the
author must correct the content, metadata, link, index, or log rather than suppress the check.

GitHub Actions is only a clean-environment caller of that script. It must provision OKF from the
pinned Git tag because the current Hackage `0.1.2.0` source distribution is known broken, and it
must fetch full Git history for diff-aware log checks. The workflow does not publish profiles,
mutate Mori's registry, or push commits.

Every implementation commit uses Conventional Commits and carries both:

```text
ExecPlan: docs/plans/10-adopt-the-okf-pattern-catalog-profile-for-the-runtime-corpus.md
Intention: intention_01ky5agv9gehqa8dbw03cdcpwv
```
