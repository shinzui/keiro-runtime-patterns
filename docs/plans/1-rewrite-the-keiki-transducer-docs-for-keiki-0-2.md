---
id: 1
slug: rewrite-the-keiki-transducer-docs-for-keiki-0-2
title: "Rewrite the keiki transducer docs for keiki 0.2"
kind: exec-plan
created_at: 2026-07-22T14:55:29Z
intention: intention_01ky5agv9gehqa8dbw03cdcpwv
master_plan: "docs/masterplans/1-keiro-runtime-standards-docs-and-seihou-blueprints.md"
---

# Rewrite the keiki transducer docs for keiki 0.2

This ExecPlan is a living document. The sections Progress, Surprises & Discoveries,
Decision Log, and Outcomes & Retrospective must be kept up to date as work proceeds.
If durable project context changes, update or create ADRs in docs/adr/ in the same change.


## Purpose / Big Picture

The eight documents in `keiki/` of this repository are the prescriptive best-practice corpus for keiki, the pure typed-state-machine ("transducer") library at the bottom of the keiro event-sourcing runtime. They were written in June 2026 against keiki 0.1.0.0. Keiki has since shipped 0.2.0.0 (released 2026-07-13; version pinned at `/Users/shinzui/Keikaku/bokuno/keiki/keiki.cabal` line 3), a hardening release that changed the validation surface (three checks became seven), made builder output intent mandatory, added a structured replay/diagnostics surface, added an event-schema-evolution story to the JSON codec package, added checked composition, changed every snapshot hash once, and removed an API (the Decider facade). On top of that, one section of the current docs presents an abstraction keiki does not have — a `ProcessManager` record with an `EventStream`/`ProcessManagerAction` shape — as if it were keiki API; that abstraction belongs to the keiro framework.

After this plan is implemented, a developer or coding agent who opens `keiki/README.md` finds an index that reflects keiki 0.2.0.0: the four stale documents are corrected, four new documents cover the 0.2 capabilities (structured replay, event-schema evolution, checked composition, and a 0.1-to-0.2 upgrade guide), the process-manager misattribution is gone and replaced by a correct one-paragraph redirect to keiro, and every document is discoverable through `mori.dhall` so `mori registry docs shinzui/keiro-runtime-patterns` lists the complete corpus. Observable proof: every code sample names only symbols that exist in the keiki 0.2 source; `git grep -n "ProcessManagerAction" keiki/` returns nothing; `dhall --file mori.dhall` still type-checks; and every document is reachable by link from `keiki/README.md`.

This plan is EP-1 of the MasterPlan at `docs/masterplans/1-keiro-runtime-standards-docs-and-seihou-blueprints.md`. Per that MasterPlan's Integration Points, EP-1 owns the `keiki/` directory and only appends its own `Schema.DocRef` entries to `mori.dhall` (never reordering existing ones), and EP-1 is the first plan to apply the documentation style contract in this repository — later plans copy the shape realized here.


## Progress

- [x] (2026-07-22 16:34Z) Milestone 1: `transducer-best-practices.md` corrected (mandatory output intent added, validation section updated to seven checks, structured-replay cross-reference added, builder import ritual added, process-manager section removed and replaced with the keiro redirect).
- [x] (2026-07-22 16:34Z) Milestone 1: `build-time-validation.md` corrected (eight `ValidationOptions` fields, eight warning constructors, updated determinism-pass description, keiro `mkEventStream` rejection note, symbolic-modeling gotchas).
- [x] (2026-07-22 16:34Z) Milestone 1: `json-event-codecs.md` corrected (five generated bindings, eight `EventCodecOptions` fields, in-band `"v"` version, `fcOnMissing`, cross-link to the new evolution guide).
- [x] (2026-07-22 16:34Z) Milestone 1: `diagram-docs.md` reframed ("Include Process Managers" replaced with orchestrator framing; `ProcessManagerDiagram` labeled cosmetic) and given additive cross-references.
- [x] (2026-07-22 16:34Z) Milestone 1: additive cross-references and style conformance applied to `diagnosing-rejected-commands.md`, `collections-and-opaque-guards.md`, and `operator-conflicts.md`.
- [ ] Milestone 2: new doc `keiki/structured-replay-and-hydration.md` written.
- [ ] Milestone 2: new doc `keiki/event-schema-evolution.md` written.
- [ ] Milestone 2: new doc `keiki/checked-composition.md` written.
- [ ] Milestone 2: new doc `keiki/upgrading-to-keiki-0-2.md` written.
- [ ] Milestone 3: `keiki/README.md` rewritten as the 0.2 index linking all eleven guides.
- [ ] Milestone 3: `mori.dhall` updated with five new DocRefs (the missing `keiki-diagram-docs` plus one per new file); `dhall --file mori.dhall` passes.
- [ ] Milestone 4: symbol audit completed — every named symbol in every `keiki/*.md` code sample located in the keiki 0.2 source.
- [ ] Milestone 4: acceptance commands run and recorded (`git grep ProcessManagerAction`, link check, DocRef count, dhall type-check).


## Surprises & Discoveries

Document unexpected behaviors, bugs, optimizations, or insights discovered during
implementation. Provide concise evidence.

(None yet.)


## Decision Log

- Decision: Create exactly four new files — `structured-replay-and-hydration.md`, `event-schema-evolution.md`, `checked-composition.md`, and `upgrading-to-keiki-0-2.md`. The other two 0.2 capability areas (the four new default-on validation checks, and mandatory builder output intent with `buildTransducerEither`) are documented by rewriting the existing `build-time-validation.md` and `transducer-best-practices.md` respectively, with a migration-angle summary of both in `upgrading-to-keiki-0-2.md`.
  Rationale: the validation checks and the builder rule are extensions of topics the corpus already owns; a second validation doc or a standalone `noEmit` doc would create two competing homes for one rule. The upgrade guide gives them the "what changes for existing code" treatment without duplicating the reference treatment.
  Date: 2026-07-22

- Decision: The four still-accurate docs (`diagnosing-rejected-commands.md`, `collections-and-opaque-guards.md`, `operator-conflicts.md`, `diagram-docs.md`) receive only additive edits: cross-references, the style-contract tagline and "Related Patterns" section, and (for `diagram-docs.md` only) the process-manager reframing. Their verified technical content is not rewritten.
  Rationale: the research audit verified every named symbol in these files against the 0.2 source; rewriting verified content risks introducing errors for no gain.
  Date: 2026-07-22

- Decision: All twelve files (eight existing, four new) conform to the documentation style contract from the MasterPlan's Integration Point 2 (restated in full in Context and Orientation below), because EP-1 is the first plan to apply it in this repository.
  Rationale: later doc plans (EP-2, EP-4, EP-5, EP-6, EP-8) copy EP-1's realized shape rather than re-deriving the contract; inconsistency here would propagate.
  Date: 2026-07-22

- Decision: New `mori.dhall` DocRef keys and kinds: `keiki-diagram-docs` (Guide), `keiki-structured-replay-and-hydration` (Guide), `keiki-event-schema-evolution` (Guide), `keiki-checked-composition` (Pattern), `keiki-upgrading-to-keiki-0-2` (Guide); all `DocAudience.Module`, all `DocLocation.LocalFile`.
  Rationale: matches the existing `keiki-<file-slug>` key convention and the existing kind usage in this file (Guides for how-to material, Pattern for modeling/wiring patterns such as `keiki-collections-and-opaque-guards`).
  Date: 2026-07-22

- Decision: The process-manager replacement text states that in keiki an orchestrator is itself a transducer (events in, commands out) wired with `Keiki.Composition`, that the hosted `ProcessManager` record lives in keiro at `/Users/shinzui/Keikaku/bokuno/keiro/keiro/src/Keiro/ProcessManager.hs`, and points forward to the messaging standards that `docs/plans/5-document-process-managers-integration-events-and-messaging-standards.md` will produce — referenced by that plan path, since the target doc files do not exist yet.
  Rationale: keiki has no `ProcessManager`, `Saga`, `Policy`, `Reactor`, or `EventStream` type anywhere in its source tree (the only literal `ProcessManager` token is the cosmetic `ProcessManagerDiagram` constructor of `MermaidSectionKind` at `/Users/shinzui/Keikaku/bokuno/keiki/src/Keiki/Render/Mermaid.hs` lines 999-1001). Presenting keiro's record as keiki API is the highest-priority staleness found by the audit. Pointing at EP-5's plan path avoids inventing file names EP-5 owns.
  Date: 2026-07-22


## Outcomes & Retrospective

Summarize outcomes, gaps, and lessons learned at major milestones or at completion.
Compare the result against the original purpose. Before marking the plan complete,
distill durable project context from the Decision Log, Surprises & Discoveries, and
this section into docs/adr/. Keep task-local execution details here.

(To be filled during and after implementation.)


## Context and Orientation

This repository, `/Users/shinzui/Keikaku/bokuno/keiro-runtime-patterns`, is a documentation-only repository: terse, agent-facing patterns and best practices for the keiro runtime stack. It contains no Haskell code. The files this plan touches are the eight Markdown documents under `keiki/` plus the registry file `mori.dhall` at the repository root. Nothing outside this repository is edited.

`docs/adr/` does not exist yet in this repository — there are no relevant ADRs to consult. This plan (or a sibling under the same MasterPlan) may seed the first ones at completion, per the distillation pass described in Outcomes & Retrospective.

**What keiki is.** Keiki is a Haskell library for pure, typed, event-sourced state machines called *transducers*. A transducer has a finite set of control states ("vertices"), a typed record of durable variables (the "register file", whose fields are "slots"), and "edges": transitions that fire on an input command, check a "guard" (a predicate over registers and command fields), update registers, and emit zero or more output events. An "aggregate" (the event-sourcing term for a consistency boundary) is a transducer from commands to events. "Replay" (also called "hydration" or "reconstitution") is rebuilding the current state purely from the previously emitted events; keiki does this by *inverting* edges — reconstructing, from each stored event, the command information the edge consumed — which is why "emit every command field a guard or update reads" is the corpus's most important rule. An "ε-edge" (epsilon edge) is an edge that fires without consuming a command. A "wire constructor" is the event constructor an edge emits, as it appears on the stored event.

**Source of truth.** The keiki source lives at `/Users/shinzui/Keikaku/bokuno/keiki`, version 0.2.0.0. Three cabal packages matter here: `keiki` (the pure core, modules under `src/Keiki/`), `keiki-codec-json` (JSON codecs, under `keiki-codec-json/src/`), and the worked-examples package `jitsurei/` (idiomatic aggregate modules under `jitsurei/src/Jitsurei/`, notably `EmailDelivery.hs`, `LoanApplication.hs`, `OrderCart.hs`, `UserRegistration.hs`). The 0.2.0.0 changes are catalogued in `/Users/shinzui/Keikaku/bokuno/keiki/CHANGELOG.md` (the `[0.2.0.0] — 2026-07-13` section, lines 12-157). Key source anchors used throughout this plan, all verified on 2026-07-22:

- `src/Keiki/Core.hs` — export list at lines 49-188; `step` at 951; `StepFailure` at 1000; `stepEither` at 1010; `InFlight` at 1102; `ReplayStepFailure` at 1116; `ReplayFailureReason` at 1125; `ReplayFailure` at 1134; `replayEvents` at 1245; `reconstituteEither` at 1286; `TransducerValidationWarning` (8 constructors) at 1740; `ValidationOptions` (8 fields) at 1823; `defaultValidationOptions` at 1855; `validateTransducer` at 1892.
- `src/Keiki/Builder.hs` — export list at lines 154-214; `noEmit` at 525; `BuilderDefect` at 714; `buildTransducerEither` at 856; `renderBuilderErrors` at 908; the load-bearing import ritual documented at lines 71-79.
- `src/Keiki/Composition.hs` — `checkComposeAlignment` at 1238; `composeChecked` at 1318; `feedback1` signature at 1792 (its long design note spans 1718-1791).
- `src/Keiki/Symbolic.hs` — z3-backed exact checks (`checkTransitionDeterminismSym`, `checkDeadEdgesSym`, `satResultIsProvablyUnsat`).
- `src/Keiki/Shape.hs` — `regFileShapeHash` and the `CanonicalTypeName` class (module header explains the pinned-name change).
- `keiki-codec-json/src/Keiki/Codec/JSON/Event.hs` — module export list at lines 94-114; the five-binding splice contract in the module haddock at lines 19-27; `FieldCodec` at ~140 with `fcOnMissing`; `fieldCodec` smart constructor at ~147; `EventCodecOptions` (8 fields) at ~166.

**The keiro boundary.** Keiro (at `/Users/shinzui/Keikaku/bokuno/keiro`) is the runtime framework that hosts keiki transducers against a Postgres event store. Two keiro facts matter to this plan. First, keiro — not keiki — owns the hosted process-manager abstraction: the record `ProcessManager` with fields `name`, `correlate`, `eventStream`, `streamFor`, `targetEventStream`, `targetProjections`, and `handle :: input -> ProcessManagerAction ci targetCi`, in `/Users/shinzui/Keikaku/bokuno/keiro/keiro/src/Keiro/ProcessManager.hs` (record at lines 183-195, `ProcessManagerAction {command, commands, timers}` at 202-207). The current `keiki/transducer-best-practices.md` lines 335-375 present that shape as keiki API; it must be removed from the keiki corpus. Second, keiro's `mkEventStream` (in `/Users/shinzui/Keikaku/bokuno/keiro/keiro-core/src/Keiro/EventStream/Validate.hs`) is a fail-fast smart constructor that runs `validateTransducer` and returns `Left warnings` — i.e. **rejects at startup** — if the keiki validation produces *any* warning. That makes the four new default-on 0.2 checks operationally load-bearing for every keiro service, and the rewritten docs must say so.

**Current state of the eight docs** (per the research audit, re-verified where cited):

- `keiki/README.md` — index; its "What changed recently (2026-06)" section stops at the MasterPlan-14 round and misses the entire 0.2 cycle; it links no replay or schema-evolution material.
- `keiki/transducer-best-practices.md` — core guidance still correct (builder DSL, `step`/`stepEither`, emit-every-field, operators, `derive*All`/`derive*With`, register hygiene, collections). Stale in four ways: (a) it never states the now-mandatory output-intent rule (`noEmit`); (b) its validation section says `validateTransducer` covers three warning kinds; (c) it never mentions structured hydration; (d) its lines 335-375, the section "Process-Manager State Streams", present keiro's `ProcessManager`/`EventStream`/`ProcessManagerAction` as keiki API. The final checklist (lines 377-397) needs matching updates.
- `keiki/build-time-validation.md` — shows `ValidationOptions` with 4 fields (actual: 8), a 3+1 warning list (actual: 8 constructors), and calls the umbrella "three checks" (actual: seven default-on plus the opt-in opaque-guard audit). Its description of the pure determinism pass understates the 0.2 upgrade. Still-correct parts to keep: the `== []` idiom, `EdgeRef`, the opt-in `warnOpaqueGuards` audit, and the solver-backed `checkTransitionDeterminismSym`/`checkDeadEdgesSym` escalation.
- `keiki/json-event-codecs.md` — the skeleton/options framing is correct, but the splice now emits five bindings (adds `<prefix>SchemaVersion :: Int`), `EventCodecOptions` has 8 fields (adds `kindOverrides`, `versionFieldName`, `currentVersion`, `upcasters`), encoded objects carry an in-band `"v"` version, and `FieldCodec` gained `fcOnMissing` plus the `fieldCodec` smart constructor.
- `keiki/diagnosing-rejected-commands.md`, `keiki/collections-and-opaque-guards.md`, `keiki/operator-conflicts.md` — verified accurate; they receive only additive cross-references and style conformance.
- `keiki/diagram-docs.md` — verified accurate symbol-wise, but its "Include Process Managers" section carries the same ownership confusion; and it is the one file missing from `mori.dhall` (registry drift: `mori.dhall` registers 7 DocRefs for 8 files).

**The documentation style contract** (MasterPlan Integration Point 2; this plan applies it first). Every doc in this corpus: has no YAML frontmatter; opens with a single `#` H1 title, then a **bold one-line tagline**, then a one-paragraph scope statement; is written as prescriptive, rule-first prose; uses code samples with language tags, favoring `-- CORRECT` / `-- WRONG` or `-- Before` / `-- After` contrast pairs; cross-links sibling docs with relative Markdown links; and ends with a "Related Patterns" section listing those links.

**The mori.dhall contract** (MasterPlan Integration Point 1). `mori.dhall` at the repository root registers each doc as a `Schema.DocRef` with fields `key` (convention: `keiki-<file-slug>`), `kind` (`Schema.DocKind.Guide`/`BestPractice`/`Pattern`), `audience` (`Schema.DocAudience.Module` for all keiki docs), `description` (`Some "…"`, one line), and `location` (`Schema.DocLocation.LocalFile "keiki/<file>.md"`). This plan appends its five new entries at the end of the existing `docs` list and does not reorder or rewrite the seven existing entries.


## Plan of Work

The work is four milestones: correct the stale files (including the process-manager removal), write the four new docs, rewrite the index and register everything in `mori.dhall`, then run the symbol audit and acceptance checks. Milestones 1 and 2 can be done in either order, but the README rewrite (Milestone 3) must come after both because it links every file. Commit at least once per milestone with a Conventional Commits message carrying the trailer `ExecPlan: docs/plans/1-rewrite-the-keiki-transducer-docs-for-keiki-0-2.md`.


### Milestone 1 — Correct the four stale docs and remove the process-manager misattribution

Scope: edit `keiki/transducer-best-practices.md`, `keiki/build-time-validation.md`, `keiki/json-event-codecs.md`, and `keiki/diagram-docs.md` per the corrections below; make additive-only edits to the three accurate guides. At the end of this milestone, no keiki doc claims a keiki API that does not exist, and every corrected claim matches the 0.2 source anchors listed in Context and Orientation. Acceptance: `git grep -n "ProcessManagerAction" keiki/` returns nothing, and spot-checking each corrected claim against the cited source line confirms it.

**`keiki/transducer-best-practices.md`** — six edits:

1. In the "Author With The Builder DSL" section, add the mandatory output-intent rule: every `onCmd`/`onEpsilon` edge body must declare its output explicitly with `emit`, `emitWith`, or `noEmit` before `goto`; a body that reaches `goto` without one is an eager construction error (no longer a silent ε-edge). Deliberately silent edges call `noEmit` (`src/Keiki/Builder.hs:525`). Show a contrast pair:

    ```haskell
    -- WRONG (0.2): rejected at construction — no output intent declared
    B.onCmd inCtorAcknowledge $ \d -> B.do
      B.requireEq (B.reg @"settled") (lit False)
      B.goto Acknowledged

    -- CORRECT: a deliberately silent edge declares noEmit
    B.onCmd inCtorAcknowledge $ \d -> B.do
      B.requireEq (B.reg @"settled") (lit False)
      B.noEmit
      B.goto Acknowledged
    ```

    In the same section, mention `buildTransducerEither` (`Builder.hs:856`) as the structured-error form — it returns every eagerly located defect as `BuilderError` values (render with `renderBuilderErrors`, `Builder.hs:908`) instead of `buildTransducer`'s `error` call — and recommend it wherever build failures should surface as values (test suites, CLIs). Note the 0.2 constraint change: both build forms now require `DistinctNames (Names rs)` (duplicate slot names are a compile-time error) and `Eq v`; the old `Bounded v`/`Enum v` constraints are gone.

2. Still in the builder section, add the load-bearing import ritual (from `Builder.hs:71-79`): the module needs `{-# LANGUAGE QualifiedDo #-}` and `{-# LANGUAGE BlockArguments #-}`, a qualified `import qualified Keiki.Builder as B`, **and** an unqualified `import Keiki.Builder ((.=))` — the assignment operator must be in scope unqualified for record-update sugar inside `B.do` blocks.

3. Rewrite the "Add Build-Time Validation Tests" section's claim inventory: `validateTransducer defaultValidationOptions` now runs **seven** default-on checks and can return **eight** warning constructors — `HiddenInput`, `HeadUnrecoverable`, `InversionAmbiguity`, `UnguardedInputRead`, `StateChangingEpsilon`, `NondeterministicPair`, `PossiblyDeadEdge`, and (opt-in only) `OpaqueGuard`. Keep the `== []` assertion idiom. Add one sentence with operational teeth: keiro's `mkEventStream` runs this same validation at service startup and rejects the stream on *any* warning, so a warning here is a deployment blocker, not advice. Link to `build-time-validation.md` for the full menu.

4. In the "Emit Every Command Field Needed For Replay" section, add the multi-event sharpening: streaming replay inverts only the **first** emitted event of a multi-event edge, so every command field the edge consumes must be recoverable from the head event alone — tail-only coverage now produces `HeadUnrecoverable`. Add a cross-reference to the new `structured-replay-and-hydration.md` for diagnosing replay failures with `reconstituteEither`/`replayEvents`.

5. Delete the entire "## Process-Manager State Streams" section (lines 335-375 of the current file) and replace it with a short section titled "Orchestrators Are Transducers Too" saying, in substance: in keiki, a process manager / saga / policy is not a separate abstraction — it is itself a transducer, the dual of an aggregate (an aggregate maps commands to events; an orchestrator maps events to commands), authored with the same builder, validated with the same `validateTransducer`, and wired to aggregates with `compose`/`composeChecked`/`alternative`/`feedback1` from `Keiki.Composition` (see `checked-composition.md`). The hosted, durable `ProcessManager` record — correlation keys, a saga event stream, target dispatch, durable timers — is **keiro's** abstraction (`Keiro.ProcessManager` in the keiro repository), which wraps a keiki transducer for its saga state; the messaging standards being produced under `docs/plans/5-document-process-managers-integration-events-and-messaging-standards.md` will document it. No keiki code sample in this replacement — the `EventStream`/`ProcessManagerAction` snippet must not survive in any form.

6. Update the "Minimum Checklist" to match: add "declare output intent on every edge (`emit`/`emitWith`/`noEmit`)", update the validation bullet to "covers all seven default-on checks", add "add a replay round-trip test using `replayEvents`/`reconstituteEither`", and reword the final process-manager bullet to "If the transducer backs a keiro process manager's saga stream, test timer-fired and already-settled paths as well" so the ownership is unambiguous.

**`keiki/build-time-validation.md`** — rewrite the body while keeping the still-correct skeleton (`== []` idiom, `EdgeRef`, opt-in audit, solver escalation):

1. Replace "runs three checks" with the seven-check inventory and show the real option record (from `Core.hs:1823-1852`):

    ```haskell
    data ValidationOptions = ValidationOptions
      { failOnEpsilonReadsInput   :: Bool  -- hidden-input check
      , checkDeterminism          :: Bool  -- pure structural determinism check
      , checkReachability         :: Bool  -- structural dead-edge check
      , warnOpaqueGuards          :: Bool  -- opt-in opaque-guard audit (default OFF)
      , checkHeadRecoverability   :: Bool  -- head event must recover all consumed fields
      , checkInversionAmbiguity   :: Bool  -- outgoing edges must not share a head wire ctor
      , checkGuardImpliesInputRead :: Bool -- input-field reads need a matching ctor guard
      , checkStateChangingEpsilon :: Bool  -- output-free edges must not change state
      }
    ```

    State that `defaultValidationOptions` (`Core.hs:1855`) enables all seven soundness checks and leaves only `warnOpaqueGuards` off, and that options should be built by record-updating `defaultValidationOptions` so future checks stay enabled.

2. Document all eight warning constructors with their fix guidance, matching `Core.hs:1740-1821`: keep the existing `HiddenInput`, `NondeterministicPair`, `PossiblyDeadEdge`, `OpaqueGuard` entries and add `HeadUnrecoverable { tvwEdge, tvwInCtor, tvwTailOnlySlots, tvwDetail }` (multi-event edge whose head event cannot recover every consumed field — move the fields onto the first event), `InversionAmbiguity { tvwSource, tvwEdgeA, tvwEdgeB, tvwWireCtor, tvwDetail }` (two outgoing edges emit the same head wire constructor, so the observed event cannot pick a unique inverting edge — give them distinct head events), `UnguardedInputRead { tvwEdge, tvwInCtor, tvwDetail }` (an edge reads an input constructor's field without the matching top-level constructor guard, so a different command can make evaluation throw), and `StateChangingEpsilon { tvwEdge, tvwChangesVertex, tvwWritesRegisters, tvwDetail }` (an output-free edge changes vertex or writes registers — the persisted log cannot reproduce it; emit an event or make the edge inert). Carry over the source doc-comment's warning that `checkStateChangingEpsilon` must never be disabled for a transducer whose events are persisted.

3. Update the determinism-pass description to the 0.2 reality (from the `validateTransducer` haddock, `Core.hs:1868-1890`): the pure pass proves overlap through supported conjunction spines — constructor consistency, exact integral intervals for integral-typed variables, concrete literal witnesses for other types — and stays silent on disjunction, negation, arithmetic, opaque terms, and variable-versus-variable comparisons. No false positives; overlaps outside that fragment need the z3-backed exact gate.

4. Add a short "Why keiro makes this mandatory" section: `mkEventStream` in keiro (`keiro-core/src/Keiro/EventStream/Validate.hs`) returns `Left warnings` if this validation yields anything, so a service that skips the CI assertion discovers the warning as a startup failure instead.

5. Add two symbolic-modeling gotchas to the solver-backed section: platform-sized `Int` is modeled as an unbounded `Integer` (analyses whose truth depends on `Int` overflow must use `Int32`/`Int64`/`Word*`, which get exact fixed-width wraparound), and 0.2 made solver uncertainty conservative — `Unknown`/`ProofError` results no longer count as proof of disjointness or deadness (`satResultIsProvablyUnsat` exposes the verdict). Keep the existing "z3 must be on PATH; the symbolic checks throw without it" note.

**`keiki/json-event-codecs.md`** — four corrections:

1. "four top-level bindings" becomes five, adding `<prefix>SchemaVersion :: Int` (splice contract in the module haddock, `Event.hs:19-27`).
2. Show the real 8-field `EventCodecOptions` (from `Event.hs:~166`): the existing four (`fieldCodecOverrides`, `passthroughFields`, `kindFieldName`, `onMissingCodec`) plus `kindOverrides :: Map String String` (constructor base name to pinned wire kind), `versionFieldName :: String` (default `"v"`), `currentVersion :: Int` (stamped by the encoder; at least 1), and `upcasters :: [(Int, Name)]` (one whole-envelope migration per historical version; the splice requires exact coverage of `[1 .. currentVersion - 1]`).
3. State the new wire shape: every encoded object carries the in-band version key (default `"v"`) alongside the `"kind"` discriminator, and the wire kind is the pinned override when `kindOverrides` names the constructor.
4. Note `FieldCodec` now has `fcOnMissing :: Maybe Name` (a top-level constant used when the JSON key is absent — the additive-field evolution hook) and the `fieldCodec encodeName decodeName` smart constructor for the strict two-field form. Close with a pointer to the new `event-schema-evolution.md` for the full evolution playbook.

**`keiki/diagram-docs.md`** — replace the "Include Process Managers" section with one titled "Include Orchestrator Transducers": the atlas should still show orchestrator state machines beside aggregates, because in keiki an orchestrator is just another transducer; `ProcessManagerDiagram` is a **cosmetic** `MermaidSectionKind` label for atlas sections (`src/Keiki/Render/Mermaid.hs:999-1001`), not evidence of a process-manager abstraction — the hosted abstraction is keiro's (same redirect sentence and EP-5 plan-path pointer as in `transducer-best-practices.md`). Keep the `MermaidSection`/`toMermaidAtlasWith`/`replaceMarkdownDiagramBlock` guidance unchanged.

**The three accurate guides** — additive only. `diagnosing-rejected-commands.md`: add one paragraph noting the replay-side mirror — `ReplayStepFailure` (`ReplayNoInvertingEdge`/`ReplayAmbiguousInversions`/`ReplayQueueMismatch`) plays the same explanatory role for hydration that `StepFailure` plays for forward steps — linking to `structured-replay-and-hydration.md`. `collections-and-opaque-guards.md`: add the nuance that a `warnOpaqueGuards = True` call also runs the seven default checks, so audits that expect only opaque-guard findings should filter for `OpaqueGuard{}` (the doc's own list-comprehension sample already does this — say so explicitly). `operator-conflicts.md`: no content change. All three (and every other file) get the style-contract tagline and a trailing "Related Patterns" section in this milestone or as the files are otherwise touched.


### Milestone 2 — Write the four new keiki 0.2 docs

Scope: create four new files in `keiki/`, each conforming to the style contract, each with code samples whose every named symbol exists in the keiki 0.2 source. At the end of this milestone the files exist and read as self-contained guides; they become navigable in Milestone 3. Acceptance: the symbol-audit procedure of Milestone 4 passes for these files, and each file's samples visibly mirror the idioms in `/Users/shinzui/Keikaku/bokuno/keiki/jitsurei/src/Jitsurei/*.hs`.

**`keiki/structured-replay-and-hydration.md`** (new; Guide). Content contract: explain that replay in 0.2 has a primary, structured surface and that the old `Maybe`-returning functions are compatibility wrappers over it. Cover: `reconstituteEither` (`Core.hs:1286` — replay a whole log from `(initial t, initialRegs t)`), `replayEvents` (`Core.hs:1245`), `applyEventsEither`, and `applyEventStreamingEither` (single-event streaming step); the `InFlight` wrapper state (`Core.hs:1102`) — `Settled s` at a stable vertex versus `InFlight s [co]` mid-way through a multi-event edge, with the queue holding the remaining expected events; the failure taxonomy: `ReplayStepFailure` = `ReplayNoInvertingEdge s [RejectedEdgeSummary s]` (no outgoing edge's head event matches the observed event; empty list means no outgoing edges at all) | `ReplayAmbiguousInversions s [MatchedEdgeSummary s]` (more than one edge could have produced it — the replay twin of `AmbiguousEdges`) | `ReplayQueueMismatch s co [co]` (the observed event does not equal the next expected event of an in-flight chain); `ReplayFailureReason` = `ReplayEventFailed …` | `ReplayLogTruncated [co]` (input ended mid-chain); and `ReplayFailure { replayFailedIndex, replayFailedState, replayFailureReason }` where `replayFailedIndex` is the zero-based position of the offending event (for truncation, the input length). Two design facts to state: diagnostics deliberately carry no register values (they summarize, they do not dump state), and — the bridge to validation — a transducer that validates clean under `defaultValidationOptions` can replay every log it produces, which is exactly what the four new checks defend. Include a worked sample in the shape of:

```haskell
case reconstituteEither orderTransducer storedEvents of
  Right (wrapperState, regs) -> …            -- hydrated
  Left ReplayFailure {replayFailedIndex, replayFailureReason} ->
    -- log the index and reason; do NOT fall back to a partial state
    …
```

and a "-- WRONG" contrast showing the pre-0.2 habit of treating a `Nothing` from `reconstitute` as an opaque dead end.

**`keiki/event-schema-evolution.md`** (new; Guide). Content contract: the playbook for changing a persisted event type without breaking stored JSON, using `keiki-codec-json`. Cover, rule-first: (1) every encoded object carries an in-band schema version under `versionFieldName` (default `"v"`), stamped from `currentVersion`; (2) wire kinds can be pinned with `kindOverrides` so a Haskell constructor rename does not change stored JSON — pin kinds from day one for any persisted sum; (3) restructuring changes bump `currentVersion` and add an upcaster — `upcasters :: [(Int, Name)]` names one whole-envelope migration function per historical version, where the version-`n` function upgrades an envelope to version `n + 1`, and the splice fails unless `[1 .. currentVersion - 1]` is covered exactly (no gaps, no duplicates); (4) purely additive fields need no version bump — give the new field a `fcOnMissing` default in its `FieldCodec` so old envelopes decode; (5) decoding tolerates unknown keys, so removing a field is a decode-side non-event (but consider whether replay still needs it — link the emit-every-field rule). Mention the runtime helpers generated code uses (`migrateEnvelope`, `lookupVersion`) exist in the module but are not usually called directly. Structure the worked example as three "-- Before / -- After" evolutions of one `OrderEvent` sum: add-a-field-with-default, rename-a-constructor (kind pin), restructure-a-payload (upcaster).

**`keiki/checked-composition.md`** (new; Pattern). Content contract: how to wire transducers together safely in 0.2. Cover: `compose` as the unchecked construction primitive and `composeChecked` (`Composition.hs:1318`) as the checked form — it runs `checkComposeAlignment` (`Composition.hs:1238`), which reports constructor-name drift, unmatched expectations, field-arity mismatches, and mapped/poisoned boundary names with exact source-edge locations; prefer `composeChecked` at every aggregate↔policy boundary. Cover poison provenance: `SomeSymTransducer` carries input/output provenance, variance rewrites stamp constructor names with `#lmapped`/`#rmapped`, and categorical composition across a poisoned boundary raises `PoisonedCompositionError` instead of silently producing a dead pipeline. Cover `alternative` (choice between machines, with `PLeftArm`/`PRightArm` giving concrete and symbolic Either-arm exclusion) plus the boundary caveat: `alternative` composes machines *inside one consistency boundary*; sibling aggregates that need separate identity/versioning belong on separate streams under a runtime primitive, not under one composed keiki machine. Give the `feedback1` trap its own section (from `Composition.hs:1718-1808`): `feedback1 t f = compose t (compose f t)` is a single-round, **two-copy** aggregate↔policy cascade — the `Disjoint (Names rs1) (Names (Append rs2 rs1))` constraint is only satisfiable when `rs1 ~ '[]`, i.e. the aggregate copy must be stateless for a single call (and nesting also forces `rs2 ~ '[]`); it is deliberately *not* shared-state feedback (the policy-produced command updates the inner copy, not the state that handled the external command), and there is deliberately no `feedback1Checked`. Also record the 0.2 semantics fixes an implementer must not contradict: `UCombine` register updates have snapshot (parallel-assignment) semantics — every right-hand side reads the edge-entry register file — and sequential `compose` threads the second machine's register writes across multi-event chains. End with the orchestrator framing sentence (orchestrators are transducers; hosted PM is keiro's; EP-5 plan-path pointer) so all three PM-adjacent docs tell one story.

**`keiki/upgrading-to-keiki-0-2.md`** (new; Guide). Content contract: the migration note for a codebase moving from keiki 0.1 to 0.2, ordered by how loudly each change announces itself. (1) Compile-time: every builder edge body must declare output intent — bodies that silently became ε-edges now fail eagerly; add `noEmit` to deliberately silent edges; `buildTransducerEither` gives the defects as values; `DistinctNames (Names rs)` rejects duplicate slot names; `Eq v` replaces `Bounded v`/`Enum v`. Code that exhaustively pattern-matches `TransducerValidationWarning` must add the four new cases. The codec splice now emits a fifth binding (`<prefix>SchemaVersion`). (2) Startup/CI: previously-clean transducers may now produce `HeadUnrecoverable`, `InversionAmbiguity`, `UnguardedInputRead`, or `StateChangingEpsilon` warnings — these are true positives; repair the transducer rather than pinning old options, because keiro's `mkEventStream` rejects the stream on any warning. (3) One-time operational blip: built-in `CanonicalTypeName` instances now use pinned, module-independent names (`Int`, `Text`, `Maybe(Int)`), so every non-empty register-file shape hash changed once; snapshot stores keyed by the old hash treat existing snapshots as cache misses and fall back to full replay — benign, but expect one slow hydration per stream after upgrade. Custom types used inside containers may need `deriving anyclass (CanonicalTypeName)`; missing evidence is a compile error, never silent hash drift. (4) Removal: the lossy pre-release Decider facade is gone — use `stepEither` for forward decisions and the structured replay functions (`reconstituteEither` and friends) for hydration; there is no letter-only replay facade that silently retains the input state after a failure. (5) Solver behavior: symbolic emptiness checks now treat `Unknown`/`ProofError` conservatively, so solver-backed suites may report previously-blessed pairs as unproven. Source every claim to `/Users/shinzui/Keikaku/bokuno/keiki/CHANGELOG.md` lines 12-157 (Decider removal at 153-156).


### Milestone 3 — Rewrite the index and register everything in mori.dhall

Scope: rewrite `keiki/README.md` and append five DocRefs to `mori.dhall`. At the end, every doc is reachable from the README and discoverable via mori. Acceptance: the link-check loop and the DocRef count in Concrete Steps pass, and `dhall --file mori.dhall` succeeds.

`keiki/README.md`: keep the role (index; start-here pointer to `transducer-best-practices.md`), apply the style contract, list all eleven sibling guides grouped as today ("Start here" / "Focused guides", adding the four new files with one-line descriptions), and replace the "What changed recently (2026-06)" section with "What changed in keiki 0.2.0.0 (2026-07)" summarizing: seven default-on validation checks (four new replay-safety checks) and keiro's reject-on-any-warning posture; mandatory builder output intent (`noEmit`) and `buildTransducerEither`; the structured replay surface (`reconstituteEither`, `replayEvents`, `ReplayFailure`); event-schema evolution in `keiki-codec-json` (in-band `"v"`, pinned kinds, upcasters, `fcOnMissing`); checked composition (`composeChecked`, poison provenance); the one-time snapshot-hash change; and the Decider removal — each item linking the doc that covers it.

`mori.dhall`: append exactly five `Schema.DocRef` entries at the end of the `docs` list, before the closing bracket, following the existing entry shape verbatim (see any existing entry in the file for the pattern). The five entries, with suggested descriptions:

```dhall
, Schema.DocRef::{
  , key = "keiki-diagram-docs"
  , kind = Schema.DocKind.Guide
  , audience = Schema.DocAudience.Module
  , description = Some
      "Generating Mermaid diagrams, atlas sections, and edge inspectors from transducers"
  , location = Schema.DocLocation.LocalFile "keiki/diagram-docs.md"
  }
, Schema.DocRef::{
  , key = "keiki-structured-replay-and-hydration"
  , kind = Schema.DocKind.Guide
  , audience = Schema.DocAudience.Module
  , description = Some
      "Diagnosing hydration failures with reconstituteEither, replayEvents, and ReplayFailure"
  , location = Schema.DocLocation.LocalFile "keiki/structured-replay-and-hydration.md"
  }
, Schema.DocRef::{
  , key = "keiki-event-schema-evolution"
  , kind = Schema.DocKind.Guide
  , audience = Schema.DocAudience.Module
  , description = Some
      "Evolving persisted event JSON with in-band versions, pinned kinds, and upcaster chains"
  , location = Schema.DocLocation.LocalFile "keiki/event-schema-evolution.md"
  }
, Schema.DocRef::{
  , key = "keiki-checked-composition"
  , kind = Schema.DocKind.Pattern
  , audience = Schema.DocAudience.Module
  , description = Some
      "Wiring transducers with composeChecked, alternative, and the feedback1 stateless-only trap"
  , location = Schema.DocLocation.LocalFile "keiki/checked-composition.md"
  }
, Schema.DocRef::{
  , key = "keiki-upgrading-to-keiki-0-2"
  , kind = Schema.DocKind.Guide
  , audience = Schema.DocAudience.Module
  , description = Some
      "Migration notes for keiki 0.2: noEmit, new validation warnings, snapshot-hash change, Decider removal"
  , location = Schema.DocLocation.LocalFile "keiki/upgrading-to-keiki-0-2.md"
  }
```

Do not touch the `dependencies` list or any existing DocRef.


### Milestone 4 — Symbol audit and acceptance

Scope: prove the rewritten corpus is faithful to keiki 0.2 and meets the acceptance criteria. No new content; only verification, with fixes folded back into the earlier files if the audit finds a discrepancy. The exact procedure and commands are in Concrete Steps and Validation and Acceptance below. Acceptance: all four acceptance checks pass and their transcripts are recorded in this plan's Progress notes.


## Concrete Steps

All commands run from the repository root, `/Users/shinzui/Keikaku/bokuno/keiro-runtime-patterns`, unless stated otherwise.

**Step 1 — Baseline.** Confirm the starting state so you can tell your edits changed things:

```bash
git grep -n "ProcessManagerAction" keiki/
```

Expected before the work:

```text
keiki/transducer-best-practices.md:357:    , handle = \input -> ProcessManagerAction { command, commands, timers }
```

**Step 2 — Milestone 1 edits.** Edit the seven existing files as specified in Plan of Work. When rewriting a claim, open the cited keiki source anchor first and copy the truth from the source, not from memory. For example, before writing the `ValidationOptions` block:

```bash
sed -n '1823,1866p' /Users/shinzui/Keikaku/bokuno/keiki/src/Keiki/Core.hs
```

**Step 3 — Milestone 2.** Create the four new files. For every code sample you write, mirror the authoring idioms of the worked examples — qualified `B.` builder calls, `TermFields` record emission, `derive*All` splices — as found in:

```bash
ls /Users/shinzui/Keikaku/bokuno/keiki/jitsurei/src/Jitsurei/
```

(`EmailDelivery.hs`, `LoanApplication.hs`, `OrderCart.hs`, `UserRegistration.hs` are the canonical four; `EmailDelivery.hs` lines 162-232 show the builder-versus-AST equivalence if you need the AST form.)

**Step 4 — Milestone 3.** Rewrite `keiki/README.md`; append the five DocRefs to `mori.dhall` exactly as shown in Plan of Work. Then type-check:

```bash
dhall --file mori.dhall > /dev/null && echo "mori.dhall OK"
```

Expected output:

```text
mori.dhall OK
```

(The file's remote `mori-schema` import is content-addressed with a sha256, so this works offline once the import is cached; if the cache is cold it fetches once. Any Dhall type error prints a diagnostic and a non-zero exit instead.)

**Step 5 — Symbol audit (Milestone 4).** For each `keiki/*.md` file, extract the identifiers named in its code fences and confirm each exists in the keiki 0.2 source. Practical procedure: for every function, type, constructor, or field name a sample uses, grep the owning module's export list or definition site. The owning modules are:

```bash
# Core surface (step, stepEither, validateTransducer, replay functions, warnings)
grep -n "<symbol>" /Users/shinzui/Keikaku/bokuno/keiki/src/Keiki/Core.hs | head -5
# Builder verbs (onCmd, emit, noEmit, requireGuard, buildTransducerEither, ...)
grep -n "<symbol>" /Users/shinzui/Keikaku/bokuno/keiki/src/Keiki/Builder.hs | head -5
# Composition (compose, composeChecked, alternative, feedback1, poison types)
grep -n "<symbol>" /Users/shinzui/Keikaku/bokuno/keiki/src/Keiki/Composition.hs | head -5
# Solver-backed checks
grep -n "<symbol>" /Users/shinzui/Keikaku/bokuno/keiki/src/Keiki/Symbolic.hs | head -5
# Shape hashing
grep -n "<symbol>" /Users/shinzui/Keikaku/bokuno/keiki/src/Keiki/Shape.hs | head -5
# JSON event codec (options, FieldCodec, splices)
grep -n "<symbol>" /Users/shinzui/Keikaku/bokuno/keiki/keiki-codec-json/src/Keiki/Codec/JSON/Event.hs | head -5
# Mermaid / inspector / validation renderers
grep -n "<symbol>" /Users/shinzui/Keikaku/bokuno/keiki/src/Keiki/Render/Mermaid.hs | head -5
```

A symbol that greps to nothing in its claimed module is a doc bug: fix the doc (or the module attribution), never invent an alias. Record any discrepancy found in Surprises & Discoveries. The high-risk names to double-check explicitly: `reconstituteEither`, `replayEvents`, `applyEventsEither`, `applyEventStreamingEither`, `InFlight`, `ReplayFailure`, `ReplayStepFailure`, `ReplayFailureReason`, `noEmit`, `buildTransducerEither`, `BuilderDefect`, `renderBuilderErrors`, `composeChecked`, `checkComposeAlignment`, `PoisonedCompositionError`, `feedback1`, `satResultIsProvablyUnsat`, `checkHeadRecoverability`, `checkInversionAmbiguity`, `checkGuardImpliesInputRead`, `checkStateChangingEpsilon`, `HeadUnrecoverable`, `InversionAmbiguity`, `UnguardedInputRead`, `StateChangingEpsilon`, `kindOverrides`, `versionFieldName`, `currentVersion`, `upcasters`, `fcOnMissing`, `fieldCodec`, `regFileShapeHash`, `CanonicalTypeName`.

**Step 6 — Acceptance run.** Execute the four checks in Validation and Acceptance and record the transcripts. Then commit (if not already committed per milestone):

```bash
git add keiki/ mori.dhall
git commit -m "docs(keiki): rewrite keiki docs for keiki 0.2.0.0

Correct the stale 0.1-era guidance, add structured-replay,
event-schema-evolution, checked-composition, and 0.2 upgrade guides,
redirect process-manager framing to keiro, and register all docs in
mori.dhall.

ExecPlan: docs/plans/1-rewrite-the-keiki-transducer-docs-for-keiki-0-2.md"
```

Commit directly on the current branch (`master`); do not create a feature branch. If you commit per milestone instead of once, keep the Conventional Commits `docs(keiki):` type/scope and the `ExecPlan:` trailer on every commit.


## Validation and Acceptance

Acceptance is behavioral: a reader with only this repository must be able to discover and trust the corpus. Four checks, run from the repository root:

**1. No keiro API is presented as keiki API.**

```bash
git grep -n "ProcessManagerAction" keiki/ ; echo "exit=$?"
```

Expected: no matching lines, `exit=1` (grep's no-match exit). Additionally, `git grep -n "targetEventStream" keiki/` must return nothing, and any remaining occurrence of the phrase "process manager" in `keiki/` must appear only in sentences that attribute the hosted abstraction to keiro or describe orchestrator transducers.

**2. Every doc is reachable from the index.**

```bash
for f in $(grep -o '(\./[a-z0-9-]*\.md)' keiki/README.md | tr -d '()' ); do
  test -f "keiki/$f" && echo "OK $f" || echo "MISSING $f"
done
ls keiki/*.md | wc -l
```

Expected: eleven `OK ./<name>.md` lines (every non-README doc linked at least once, no `MISSING`), and the file count is `12`. Conversely, confirm every file in `keiki/` other than `README.md` appears among the `OK` lines — a doc that exists but is not linked fails this check.

**3. The registry is complete and well-typed.**

```bash
grep -c 'key = "keiki-' mori.dhall
dhall --file mori.dhall > /dev/null && echo "mori.dhall OK"
```

Expected: `12` keiki-prefixed keys (seven existing plus five new), then `mori.dhall OK`. The count is scoped to the `keiki-` prefix on purpose: sibling plans under the same MasterPlan append their own DocRef blocks (`kiroku-*`, `keiro-*`, `messaging-*`, …), so an absolute total would depend on execution order. A Dhall type error (for example a missing comma in an appended record) prints a diagnostic instead — fix and re-run; the command is safe to repeat.

**4. The corpus is faithful to keiki 0.2.** The Step-5 symbol audit found a definition site for every named symbol, and four spot-checks of load-bearing numbers hold: `ValidationOptions` has exactly 8 fields (`sed -n '1823,1852p' /Users/shinzui/Keikaku/bokuno/keiki/src/Keiki/Core.hs`), `TransducerValidationWarning` has exactly 8 constructors (`sed -n '1740,1821p'` of the same file), the codec splice haddock promises five bindings (`sed -n '19,27p' /Users/shinzui/Keikaku/bokuno/keiki/keiki-codec-json/src/Keiki/Codec/JSON/Event.hs`), and `EventCodecOptions` has exactly 8 fields (`sed -n '166,196p'` of the same file). The docs must state those same numbers.

Style acceptance: open any two rewritten files and confirm the contract shape — no frontmatter; H1, then a bold tagline line, then one scope paragraph; language-tagged fences; contrast pairs where behavior changed; a trailing "Related Patterns" section with relative links.


## Idempotence and Recovery

Every step is a plain-text edit to files tracked by git; all steps are safe to repeat. The `mori.dhall` change is append-only within the `docs` list, so re-applying it is detectable by check 3 (a count above 12 means a double-append — delete the duplicates). If an edit goes wrong, recover any single file with `git checkout -- <path>` (before commit) or `git revert <sha>` (after). The validation commands (`git grep`, `dhall`, the link loop) are read-only and repeatable. No step touches any repository other than this one, and no step runs code from the keiki repository — keiki is only read. If the symbol audit reveals that a claim in this plan itself is wrong (for example a source line moved after a keiki commit), fix the doc against the current source, record the discrepancy in Surprises & Discoveries, and update this plan's anchor in the same commit.


## Interfaces and Dependencies

This plan produces documentation and one registry edit; it introduces no code interfaces. Its "interfaces" are the claims the docs make about keiki 0.2, which must match these definition sites at completion:

- `Keiki.Core` (`/Users/shinzui/Keikaku/bokuno/keiki/src/Keiki/Core.hs`): `stepEither :: … -> Either (StepFailure s) (s, RegFile rs, [co])`; `validateTransducer :: (Bounded s, Enum s, Ord s, Show s) => ValidationOptions -> SymTransducer (HsPred rs ci) rs s ci co -> [TransducerValidationWarning s]`; `reconstituteEither`, `replayEvents`, `applyEventsEither`, `applyEventStreamingEither`; `InFlight`, `ReplayStepFailure`, `ReplayFailureReason`, `ReplayFailure`; the 8-field `ValidationOptions` and 8-constructor `TransducerValidationWarning`.
- `Keiki.Builder` (`src/Keiki/Builder.hs`): `buildTransducer`, `buildTransducerEither`, `noEmit`, `BuilderDefect`, `BuilderError`, `renderBuilderErrors`, and the `DistinctNames (Names rs)`/`Eq v` build constraints.
- `Keiki.Composition` (`src/Keiki/Composition.hs`): `compose`, `composeChecked`, `checkComposeAlignment`, `alternative`, `feedback1`, `PoisonedCompositionError`.
- `Keiki.Symbolic` (`src/Keiki/Symbolic.hs`): `checkTransitionDeterminismSym`, `checkDeadEdgesSym`, `satResultIsProvablyUnsat`; requires the external `z3` binary on `PATH` at run time (documented, not executed by this plan).
- `Keiki.Shape` (`src/Keiki/Shape.hs`): `regFileShapeHash`, `CanonicalTypeName`.
- `Keiki.Codec.JSON.Event` (`keiki-codec-json/src/Keiki/Codec/JSON/Event.hs`): `deriveEventCodecSkeleton`, `deriveEventCodecSkeletonAs`, the 8-field `EventCodecOptions`, `FieldCodec {fcEncode, fcDecode, fcOnMissing}`, `fieldCodec`, `OnMissingCodec`.
- Keiro (read-only context, never presented as keiki API): `Keiro.ProcessManager` at `/Users/shinzui/Keikaku/bokuno/keiro/keiro/src/Keiro/ProcessManager.hs` and `mkEventStream` at `/Users/shinzui/Keikaku/bokuno/keiro/keiro-core/src/Keiro/EventStream/Validate.hs`.

Tooling dependencies: `git` and `grep`/`sed` (already in use in this repository) and the `dhall` executable for the registry type-check. Cross-plan dependencies per the MasterPlan: none hard; this plan writes forward references to the messaging standards by the plan path `docs/plans/5-document-process-managers-integration-events-and-messaging-standards.md` (EP-5), and later plans (EP-2, EP-4, EP-5, EP-6, EP-8) copy this plan's realized doc style and its `mori.dhall` DocRef shape.
