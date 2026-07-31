---
name: update-patterns
description: >
  Reconcile the runtime-patterns catalog with upstream keiro-ecosystem source. Reports which
  upstream repositories moved since the catalog last tracked them, rewrites the affected concepts
  from the real source, adds concepts for capabilities the catalog does not yet cover, retires
  ones whose feature is gone, and advances per-project git watermarks so the next run only
  inspects new commits. TRIGGER when: the user wants to update, refresh, re-verify, or check
  drift or coverage gaps in the runtime patterns against
  keiki/keiro/kiroku/shibuya/pgmq-hs/pg-migrate/settei.
argument-hint: <status|update|record|add-source> [project]
user-invocable: true
---

# Update patterns skill

This repository is a derived artifact: every concept under `runtime-patterns/` states how the
upstream libraries actually behave. It goes stale whenever those libraries move. This skill makes
the update incremental — it tracks, per upstream project, the last commit whose behaviour was
reconciled with the catalog, so a refresh reads only the commits since that watermark instead of
re-deriving the whole corpus.

Read [AGENTS.md](../../../AGENTS.md) first; its update contract (timestamp, log entry, index
regeneration, check script) governs every edit you make here.

## State

`sources.json`, next to this file, is the watermark ledger. It is tracked in git and is the only
place watermarks live. Each entry:

| Field | Meaning |
| --- | --- |
| `project` | Mori qualified name, e.g. `shinzui/keiro` |
| `uri` | `mori://` URI used to resolve the local checkout — never hardcode a path |
| `branch` | Ref to compare against; upstream checkouts are often parked on feature branches, so compare against this, not `HEAD` |
| `subjects` | Catalog subdirectories under `runtime-patterns/` this project's behaviour feeds |
| `watch` | Paths inside the upstream repo whose changes usually imply a catalog change |
| `last_checked_commit` | The watermark: upstream commit already reconciled with the catalog |
| `last_checked_at` | When that reconciliation happened (UTC) |
| `notes` | What evidence the watermark rests on |

A watermark means "the catalog reflects upstream as of this commit". Advance it only after the
affected concepts were re-read against the new source and corrected, or confirmed still correct.
Never advance it just because the commits looked irrelevant from their subjects alone.

## Helper

`sources.sh` reads the ledger, resolves each checkout through Mori, and reports drift:

```bash
agents/skills/update-patterns/sources.sh status              # drift for every source
agents/skills/update-patterns/sources.sh status --project keiro --files
agents/skills/update-patterns/sources.sh path keiro          # resolved checkout path
agents/skills/update-patterns/sources.sh record keiro        # watermark := branch head
agents/skills/update-patterns/sources.sh record keiro <sha>  # watermark := specific commit
```

`record` writes both `last_checked_commit` and `last_checked_at`. If a source reports
`unresolved` or `unknown watermark`, the checkout is missing or unfetched — say so and stop for
that project rather than guessing.

## Mode: status

Default mode. Run `sources.sh status`, then summarize per project: commits since the watermark,
which upstream packages they touched, and which catalog subjects are implicated. Flag release
commits (`chore(release):`, `CHANGELOG.md`, `.cabal` version bumps) — a major/minor bump almost
always invalidates version claims in the concepts. Call out separately any upstream capability
that appears to have no covering concept at all — those are the candidates for new concepts, and
they are easy to miss when only scanning for stale claims. Do not edit anything in this mode.

## Mode: update

Argument is an optional project name; with none, work through every project that shows drift,
one at a time.

1. **Scope.** `sources.sh status --project <name> --files`. Read the actual diff of the watch
   paths in the upstream checkout — `git -C <path> log -p <watermark>..<branch> -- <watch paths>`.
   Judge from source and CHANGELOG, never from commit subjects alone.
2. **Read the source, not memory.** Resolve the checkout with `sources.sh path <name>` and read
   the modules that back the claim: exported symbols, signatures, defaults, error constructors,
   SQL and migration files. Follow the global instruction — verify released versions against the
   package registry and upstream tags before writing any version bound.
3. **Locate the affected concepts, and the gaps.** `mori registry concepts
   shinzui/keiro-runtime-patterns --bundle runtime-patterns`, or `rg` the symbol across the
   `subjects` directories. A single upstream change usually touches several concepts plus the
   subject `overview.md` and `gotchas.md`. Classify every upstream change into one of three
   outcomes and say which you chose: **correct** an existing concept, **create** a new one (see
   below), or **no catalog change** with the reason. A capability that no concept mentions is a
   gap, not an absence of work — silence about a new footgun or a new required call reads as
   "the standard does not cover it".
4. **Edit prescriptively.** Keep the catalog's voice: terse, imperative, standard-setting; no
   product rationale (that belongs in `keiro-runtime-docs`) and no general Haskell advice (that
   belongs in `haskell-jitsurei`). Correct stale claims outright rather than appending caveats.
   When an upstream feature is removed or superseded, retire its concept: fold the surviving
   guidance into the concept that replaces it and delete the file plus its `mori.dhall` `DocRef`,
   or, if the name still means something to readers, keep the file as a pointer to its successor.
   Do not leave a standard describing something that no longer exists.
5. **Frontmatter.** Set `timestamp` to the material change time (RFC3339 with offset, matching
   siblings). Any `reviews:` entry whose `document_timestamp` no longer matches the new
   `timestamp` is stale evidence — leave the record in place; it is history, and it correctly
   reads as not-current. Do not bump `timestamp` for a review-only or watermark-only change.
6. **Log.** Add an entry to the nearest enclosing `log.md` with `okf log add`, using the existing
   `**Added**` / `**Update**` / `**Migration**` prefixes. Every changed concept needs one — CI
   enforces it diff-aware.
7. **Regenerate and check.**

   ```bash
   okf index runtime-patterns --write
   scripts/check-runtime-patterns origin/master
   ```

   If you added or removed concepts, `scripts/check-runtime-patterns` asserts an exact graph node
   count; update that number in the script as part of the same change.
8. **Record.** `sources.sh record <name>` — passing the exact commit you reconciled against if it
   is not the branch head (for example when upstream has unreleased work in flight you chose to
   exclude; record the older commit and say why in `notes`).
9. **Commit.** Conventional Commits, directly on the current branch. Include the catalog edits,
   `sources.json`, and regenerated indexes together, and cite upstream by `mori://` URI plus the
   commit range in the body, e.g. `mori://shinzui/keiro @ 430c3d2..d49e27a`.

If the diff turns out to change nothing the catalog claims, skip to step 8: record the watermark
and commit `sources.json` alone with a `chore(patterns): record <project> upstream review` message
noting the range reviewed. That is the mechanism that keeps future runs cheap.

## Creating a new concept

A new concept is warranted when the upstream capability carries its own standing rules — what a
service must do, must not do, or must check — and no existing concept can absorb it without
becoming two documents. Prefer extending a sibling; a capability that amounts to one new function
belongs in the concept that already covers its area. When the gap is a whole new subject area
(a new upstream project, a new operational surface), create a subdirectory with its own
`overview.md`, `log.md`, and routes rather than parking the file under the nearest existing one.

Creating one is a checklist, and skipping any step fails CI:

1. **File.** `runtime-patterns/<subject>/<slug>.md`, mirroring a sibling's frontmatter exactly:
   `type`, `title`, `description`, `timestamp`, `resource`, `tags`, `status: current`. `type` must
   be one of the profile's closed set — `Standard`, `Guide`, `Pattern`, `Runbook`, `Reference`,
   `Gotcha` (plus `Overview` for `*/overview` and `Navigation` for `getting-started`). `resource`
   is `mori://shinzui/keiro-runtime-patterns/docs/<subject>-<slug>`. No `reviews:` — that list is
   earned, not authored.
2. **Body.** Lead with a one-line bolded rule stating the standard, then imperative sections. Read
   two siblings first and match their altitude; a new concept that argues instead of prescribing
   is in the wrong repository.
3. **`mori.dhall`.** Add a `DocRef` with `key = "<subject>-<slug>"`, the right `DocKind`,
   `audience = Module`, a one-line description, and the `LocalFile` path.
4. **Routes.** Add it to the subject `overview.md` and to the matching task route in
   `getting-started.md`. An unrouted concept is invisible; a past review caught exactly this
   (`keiro/service-workspaces` shipped with no route reaching it).
5. **Links.** Cross-link from the concepts a reader arrives from, and check `okf graph
   runtime-patterns --json` leaves no orphan node.
6. **Check script.** `scripts/check-runtime-patterns` asserts an exact node count; raise it by the
   number of concepts you added, in the same change.
7. **Log, index, check, record.** Steps 6–9 of the update mode apply unchanged; use the
   `**Added**` prefix in `log.md`.

## Mode: record

Advance a watermark without a catalog edit — use only after actually reviewing the range. State
in the commit body which commit range was reviewed and why nothing changed.

## Mode: add-source

When the catalog starts depending on a new upstream project:

1. Confirm the project resolves: `mori path mori://<namespace>/<project>`.
2. Add it to `dependencies` in `mori.dhall` if absent.
3. Append an entry to `sources.json` with `subjects`, `watch`, and a watermark set to the commit
   you actually verified the new content against (not blindly the branch head), and `notes`
   naming that evidence.

## Boundaries

- Never edit generated `index.md` files by hand; OKF owns them.
- Do not traverse `/nix/store` or `/`. Resolve every dependency through Mori.
- `seihou` blueprints consume these standards rather than feeding them; they are deliberately not
  a source. Changes flow patterns → blueprints, via `docs/plans/9-*`.
- Do not fetch or pull in upstream checkouts without asking; they are the user's working trees and
  may hold uncommitted work.
