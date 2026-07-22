---
id: 8
slug: document-settei-configuration-and-kubernetes-operational-standards
title: "Document settei configuration and Kubernetes operational standards"
kind: exec-plan
created_at: 2026-07-22T14:55:29Z
master_plan: "docs/masterplans/1-keiro-runtime-standards-docs-and-seihou-blueprints.md"
---

# Document settei configuration and Kubernetes operational standards

This ExecPlan is a living document. The sections Progress, Surprises & Discoveries,
Decision Log, and Outcomes & Retrospective must be kept up to date as work proceeds.
If durable project context changes, update or create ADRs in docs/adr/ in the same change.


## Purpose / Big Picture

About twenty Haskell microservices (ten new, ten refactored) and a family of CLI tools are about to be built or rebuilt on the keiro runtime. Every one of them needs configuration: which database to talk to, which port to serve, which secrets to load, and how all of that changes between the dev, test, and production Kubernetes namespaces. Today there is no fleet standard. The one shipped reference service (danwa, at `/Users/shinzui/Keikaku/bokuno/danwa`) wires configuration with raw Dhall `FromDhall` decoding, the CLI guidance in `/Users/shinzui/Keikaku/bokuno/haskell-jitsurei/cli/hierarchical-config.md` describes a layered-Dhall pattern, and neither gives provenance, secret redaction, precedence tracing, or a deployment-gate story. The settei library family (at `/Users/shinzui/Keikaku/bokuno/settei`, version 0.2.0.0) was built precisely to solve this, but nothing in the ecosystem consumes it yet.

After this plan is implemented, this repository (`/Users/shinzui/Keikaku/bokuno/keiro-runtime-patterns`) has a new `config/` documentation area holding four prescriptive documents plus an index: the settei microservice configuration standard, the settei CLI configuration standard, the Kubernetes deployment and operations standard for the fleet (including graceful shutdown), and a gotcha catalogue. All five files are registered as DocRefs in `mori.dhall` (keys `config-<slug>`), `shinzui/settei` is added to the project's dependency list, and the superseded layered-Dhall CLI doc in haskell-jitsurei carries a clearly marked supersession note pointing here. A developer or agent asking "how do I configure a new keiro service?" or "how do I deploy it to Kubernetes?" finds one authoritative, terse answer discoverable through `mori registry docs shinzui/keiro-runtime-patterns`.

You can see it working by listing `config/` (five markdown files exist), running `dhall type --file mori.dhall` from the repository root (type-checks with the five new DocRefs), and opening `/Users/shinzui/Keikaku/bokuno/haskell-jitsurei/cli/hierarchical-config.md` (a supersession note sits directly under the title).


## Progress

Use a checklist to summarize granular steps. Every stopping point must be documented here,
even if it requires splitting a partially completed task into two ("done" vs. "remaining").
This section must always reflect the actual current state of the work.

- [ ] Milestone 1: `config/settei-service-standard.md` written (Config algebra rules, Setting declarations, canonical service source order, env bindings, `--check-config` + exit codes, provenance/redaction, migration posture from raw Dhall).
- [ ] Milestone 1: every symbol named in the service standard verified against the settei source tree.
- [ ] Milestone 2: `config/settei-cli-standard.md` written (four-layer order, `--config FORMAT:PATH`, `--set`, diagnostic modes, redaction in CLI output).
- [ ] Milestone 2: every symbol named in the CLI standard verified against the settei source tree.
- [ ] Milestone 3: `config/kubernetes-deployment.md` written (one image many namespaces, kustomize overlays, downward API posture, mounted directories, check-config initContainer gate, no-reload rollouts, offline validation, placeholder secrets, graceful shutdown).
- [ ] Milestone 3: shibuya `stopAppGracefully` and warp shutdown facts re-verified against their sources via mori before the shutdown section is finalized.
- [ ] Milestone 4: `config/settei-gotchas.md` written (the six-plus footgun catalogue).
- [ ] Milestone 4: `config/README.md` index written; every `config/*.md` file listed with a one-line description.
- [ ] Milestone 5: `mori.dhall` updated — five `config-*` DocRefs appended, `shinzui/settei` added to dependencies; `dhall type --file mori.dhall` passes.
- [ ] Milestone 5: supersession note added to `/Users/shinzui/Keikaku/bokuno/haskell-jitsurei/cli/hierarchical-config.md` (the only edit outside this repository).
- [ ] Final: cross-links between the config docs verified; validation transcript captured in this plan; Outcomes & Retrospective written; ADR distillation pass done (see Context and Orientation on `docs/adr/`).


## Surprises & Discoveries

Document unexpected behaviors, bugs, optimizations, or insights discovered during
implementation. Provide concise evidence.

(None yet. Planning-stage observations that shaped this plan: settei has zero ecosystem consumers — even danwa uses raw Dhall — so these docs define an intended adoption surface, not a description of current practice; and settei's own `README.md` still claims version 0.1.0.0 while every package ships 0.2.0.0, a stale-doc fix owned by EP-3, not this plan.)


## Decision Log

Record every decision made while working on the plan.

- Decision: The gotcha catalogue gets its own file, `config/settei-gotchas.md`, rather than being folded into the service standard.
  Rationale: the gotchas apply equally to services and CLIs (null-is-present, positional precedence, exact-version pinning); duplicating them in two standards invites drift, and a single terse catalogue matches this corpus's agent-facing style.
  Date: 2026-07-22

- Decision: DocRef kinds — the two standards are `BestPractice`, `kubernetes-deployment` is `Runbook`, the gotcha catalogue is `Notes`, the README index is `Guide`. All audience `Module`.
  Rationale: matches the DocKind vocabulary already used in this repo (Guide/BestPractice/Pattern for keiki docs) while marking the Kubernetes doc as operational material; `Module` is the audience used throughout this repo's registry.
  Date: 2026-07-22

- Decision: Cross-repo references (to settei's guides and to haskell-jitsurei) are written as mori project name plus repository-relative path (for example "`shinzui/settei` repo, `docs/guides/kubernetes-cookbook.md`"), never as filesystem-absolute links or relative links.
  Rationale: relative links cannot resolve across repositories, absolute paths are machine-specific, and mori is the fleet's discovery mechanism (`mori registry show shinzui/settei --full` yields the checkout path).
  Date: 2026-07-22

- Decision: Graceful shutdown lives in `config/kubernetes-deployment.md`, not in a separate doc, and probe guidance is deferred to EP-7's haskell-jitsurei doc by reference.
  Rationale: shutdown is only meaningful in the deployment context (SIGTERM comes from the kubelet; grace periods are pod-spec fields), and the MasterPlan places probe guidance in the servant API stream (EP-7, soft dependency of this plan).
  Date: 2026-07-22

- Decision: This plan edits nothing in the settei repository, even though its README version claim is stale.
  Rationale: MasterPlan EP-3 owns stale-doc remediation in the settei repo; duplicating the fix would collide.
  Date: 2026-07-22


## Outcomes & Retrospective

Summarize outcomes, gaps, and lessons learned at major milestones or at completion.
Compare the result against the original purpose. Before marking the plan complete,
distill durable project context from the Decision Log, Surprises & Discoveries, and
this section into docs/adr/. Keep task-local execution details here.

(To be filled during and after implementation.)


## Context and Orientation

This repository, `/Users/shinzui/Keikaku/bokuno/keiro-runtime-patterns`, is a terse, agent-facing corpus of best-practice docs for the keiro runtime. Today it contains one doc area, `keiki/` (eight files on typed state-machine transducers), a `mori.dhall` registry at the root that makes each doc discoverable by tooling, and `docs/` holding the MasterPlan and ExecPlans. This plan (EP-8 of the MasterPlan at `docs/masterplans/1-keiro-runtime-standards-docs-and-seihou-blueprints.md`) creates the second doc area, `config/`, owned exclusively by this plan per the MasterPlan's integration points.

`docs/adr/` does not exist in this repository yet — there are no ADRs to consult. The MasterPlan explicitly names "settei as the fleet configuration standard (superseding raw Dhall `FromDhall` wiring as used in danwa)" as an ADR candidate; the final ADR-distillation pass of this plan should seed it if no earlier plan has.

**What settei is.** Settei is a provenance-aware configuration library family at `/Users/shinzui/Keikaku/bokuno/settei` — eleven packages, all version 0.2.0.0 in lockstep, GHC 9.12 / GHC2024. "Provenance-aware" means every resolved configuration value carries a record of which source supplied it, which sources were shadowed, and whether the value is secret. The packages that matter for this plan:

- `settei` (core): the `Config a` description algebra, `Setting` declarations, sources, precedence, resolution, provenance reports, redaction. Source under `settei/settei/src/Settei/`.
- `settei-env`: explicit, validated environment-variable bindings. Source under `settei/settei-env/src/Settei/Env.hs`.
- `settei-yaml`, `settei-kdl`, `settei-dhall`: strict file-format adapters (structure only; decoding and sensitivity stay in core). `settei-dhall` enforces a `DhallImportPolicy` (`NoImports` default).
- `settei-formats`: the umbrella `FORMAT:PATH` dispatcher over the three file adapters (`settei/settei-formats/src/Settei/Formats.hs` and `Settei/Formats/Optparse.hs`).
- `settei-optparse-applicative`: CLI glue — `--set`, `--config`, diagnostic mode flags (`settei/settei-optparse-applicative/src/Settei/Optparse.hs`).
- `settei-kubernetes`: mounted ConfigMap/Secret directory reading with explicit file-to-key bindings (`settei/settei-kubernetes/src/Settei/Kubernetes.hs` and `Settei/Kubernetes/Bindings.hs`).

**The canonical upstream material.** Settei ships its own long-form guides: `docs/guides/kubernetes-service.md` (the application half: model process-visible inputs, typed config, bindings, mounted files, resolve once, safe diagnostics), `docs/guides/kubernetes-cookbook.md` (the deployment half: ten numbered sections plus FAQ — one image many namespaces, record namespace identity, choose environment explicitly, deliver per-namespace values, walk the manifests, gate rollouts with `--check-config`, incident runbook, rotate by restarting, reject unknown keys), and `docs/guides/cli-application.md`. Its `examples/settei-service` is the canonical Kubernetes-shaped service configuration reference (with a full `deploy/` tree: `base/deployment.yaml`, `overlays/{dev,test,production}`, `validate.sh`), and `examples/settei-cli` is the canonical four-layer CLI. **Our docs are the terse prescriptive fleet layer**: they state the rules, show the minimal correct shape, and cross-reference the settei guides for the long walk-throughs. They must not duplicate the guides wholesale.

**Adoption status (critical framing).** Nothing in the ecosystem consumes settei today. danwa configures its server via raw Dhall — `danwa-server/src/Danwa/Server/Config.hs` (deriving `FromDhall`, loading with `inputFile auto`) and `danwa-workers/src/Danwa/Workers/Config.hs` do plain Dhall decoding with no provenance, no redaction, no precedence, no diagnostics. The MasterPlan Decision Log rules that settei is the fleet-wide adoption target for both microservices and CLIs, superseding that raw-Dhall wiring and the layered-Dhall CLI pattern in haskell-jitsurei. The docs this plan writes therefore define an intended surface. Write them in the imperative present ("declare settings with `secretSetting`"), never as descriptions of what existing services already do.

**Repositories this plan touches.** All new files land in `/Users/shinzui/Keikaku/bokuno/keiro-runtime-patterns` (the `config/` directory, plus one edit to `mori.dhall`). Exactly one file outside this repo is edited: `/Users/shinzui/Keikaku/bokuno/haskell-jitsurei/cli/hierarchical-config.md` receives a supersession note (MasterPlan Integration Point 5 reserves that file for this plan; EP-3 and EP-7 touch other haskell-jitsurei files, so there is no collision). Nothing in the settei or danwa repos is edited.

**Style contract (MasterPlan Integration Point 2).** Every new doc follows the established corpus style: no YAML frontmatter; a single `#` H1 title; a **bold one-line tagline** directly under the H1; a one-paragraph scope statement; prescriptive, rule-first prose ("The rule is one sentence: …"); code samples with language tags using `-- CORRECT` / `-- WRONG` contrast pairs; relative Markdown cross-links between docs in this repository; a trailing `## Related Patterns` section. Look at `keiki/transducer-best-practices.md` in this repo for the realized shape.

**Terms used throughout this plan.** A *source* is one origin of raw configuration values (a file, the environment, CLI flags, a mounted directory); settei resolves a list of sources where position is precedence — later entries win. A *setting* is one typed, described, sensitivity-tagged key declaration. A *CAF* (constant applicative form) is a top-level Haskell constant evaluated lazily on first use; "force the CAF in tests" means evaluate it in a test so construction-time validation errors surface in CI instead of production. *kustomize* is the Kubernetes-native tool that renders a base manifest plus per-environment overlay directories into final YAML (`kubectl kustomize <dir>`). An *initContainer* is a container Kubernetes runs to completion before the main container starts; a failing initContainer blocks the pod. The *downward API* is the Kubernetes mechanism injecting pod metadata (like the namespace) into env vars.


## Plan of Work

The work is five milestones: three content docs, then the gotcha catalogue plus index, then registration and the cross-repo supersession note. Each milestone ends with a verifiable artifact. Author docs in this order because the CLI and Kubernetes docs cross-link into the service standard.

### Milestone 1 — `config/settei-service-standard.md`, the microservice configuration standard

Scope: create `config/settei-service-standard.md` in this repository. At the end, a complete, self-contained statement of how every keiro-fleet microservice declares, layers, resolves, and diagnoses its configuration exists and every Haskell symbol it names has been verified against the settei source. Acceptance: the file exists, follows the style contract, and the symbol-verification greps in Concrete Steps all hit.

The doc must cover, in prescriptive rule-first prose, the following content (all facts below were verified against settei 0.2.0.0 source during planning; re-verify during implementation per Concrete Steps):

*Config algebra rules.* Configuration is declared as a `Config a` value — an applicative/selective description that can be statically inspected (`describe :: Config a -> Schema` in `Settei.Config`) before any source is read. `Config` deliberately has **no Monad instance**: a Monad would let an already-resolved value compute new keys at runtime, destroying static inspectability (`--describe-config` and unknown-key checking depend on knowing the full key set up front). The rule: never reach for do-notation over `Config`; branch with the selective combinators. From `settei/src/Settei/Config.hs`: `required`/`optional` lift a `Setting` into `Config`; `whenConfig :: Config Bool -> Config a -> Config (Maybe a)` and `whenEq :: (Eq d) => Config d -> d -> Config a -> Config (Maybe a)` gate a branch on another setting (the canonical use: `whenEq (required environmentSetting) Production (required databasePasswordSetting)` — the password is demanded only in production); `fallbackTo` is the key-migration idiom (``optional newSetting `fallbackTo` required oldSetting``); `withDefault` attaches a named `Default` rule. Only the taken selective branch is evaluated; applicative errors accumulate rather than short-circuit.

*Setting declaration standards.* From `settei/src/Settei/Setting.hs`: a `Setting a` bundles key, human description, `Sensitivity` (`Public | Secret`), decoder, and optional renderer; smart constructors `publicSetting`, `publicSettingWithRenderer`, `publicShowSetting`, `secretSetting`. The fleet rule: **anything sensitive is declared with `secretSetting` — sensitivity lives on the setting, never on the delivery path.** A database password is a secret whether it arrives via a mounted Secret file, an env var, or a config file during local dev. Declaring the same key both public and secret is a `SensitivityConflict` error and Secret wins. Every setting gets a real description (the descriptions are the `--describe-config` output).

*Canonical source order for services.* Precedence in settei is purely positional: `resolve :: ResolveOptions -> [Source] -> Config a -> ResolveResult a` (`settei/src/Settei/Resolve.hs`) takes the source list ordered low to high; last wins; shadowed candidates are retained in the report. The fleet's canonical order for services is **configuration files < mounted Kubernetes secrets < environment variables** — environment highest so that an explicit pod-spec env override wins during an incident while the mounted candidate remains visible in the shadow trace. This is exactly `resolveServiceSources` in settei's `examples/settei-service/src/Settei/Example/Service.hs` (its Haddock says so verbatim); cite that example as the canonical reference implementation.

*Explicit validated environment bindings.* From `settei-env/src/Settei/Env.hs`: there is no prefix auto-discovery at runtime; every env var is an explicit `EnvBinding` (one environment name to one key), validated in aggregate by `bindings :: [EnvBinding] -> Either (NonEmpty EnvError) Bindings` (the `Bindings` constructor is private), merged with `mergeBindings`, turned into a source with `environmentSource`/`readEnvironmentSource`. The convention generator `prefixedBindings` derives `PREFIX_KEY_SEGMENTS` names and reports collisions rather than guessing. The fleet rule: declare the service's `Bindings` as a top-level CAF and **force it in a test** (settei ADR 0010's posture) so an invalid binding list fails CI, not production startup. Show a minimal tasty/HUnit test that evaluates the CAF.

*The `--check-config` diagnostic and reserved exit codes.* Every service binary must support a mode that loads and resolves configuration exactly as the real startup would, prints the (redacted) resolution report, and exits without serving. Reserved exit codes, from `examples/settei-service/src/Settei/Example/Service.hs` (`usageExitCode = 2`, `sourceExitCode = 3`, `resolutionExitCode = 4`): **2** usage/flag errors, **3** a source could not be read or parsed (mounted-file IO, adapter parse failure), **4** resolution failed (missing required, decode error, conflict). These codes are load-bearing: the Kubernetes rollout gate (Milestone 3) distinguishes them. `DiagnosticMode` in `settei-optparse-applicative` already has a `CheckConfig` constructor; services wire it via `diagnosticModeOptions`/`setteiOptions`.

*Provenance and redaction guarantees.* `ResolveResult` carries `answer` (`Either (NonEmpty ConfigError) a`), `report`, and `warnings`; **the report is present on success and on failure**, so diagnostics never lose provenance. Redaction is structural: `ReportedValue` is `VisibleValue | RedactedValue | DerivedValue` and sensitivity is applied before any display form of a secret exists — settei's conformance suite (`examples/settei-conformance`) asserts a planted secret sentinel never appears in stdout, stderr, report, or error text while `<redacted>` does. The fleet rule: print the report (or a curated summary of it) on startup failure; never hand-roll config logging.

*Migration posture.* Services currently wired with raw Dhall `FromDhall` (the danwa pattern — `danwa-server/src/Danwa/Server/Config.hs` and `danwa-workers/src/Danwa/Workers/Config.hs` in the danwa repo use `FromDhall` records loaded with `inputFile auto`) migrate to settei: the standard is not optional for refactored services. Existing `.dhall` config files do not have to be rewritten on day one — `settei-dhall` reads them as a settei source with `DhallImportPolicy` defaulting to `NoImports` (no env, remote, or missing imports ever; `LocalImportsWithin` is the only relaxation). The bridge posture: keep the `.dhall` file, load it through `settei-dhall`, gain provenance/redaction/precedence immediately, and migrate the file format (or not) at leisure. Note the caveat that leaf-level import attribution is unavailable after Dhall normalization.

The doc closes with Related Patterns linking `./settei-cli-standard.md`, `./kubernetes-deployment.md`, `./settei-gotchas.md`, and naming the settei guides by mori project + path.

### Milestone 2 — `config/settei-cli-standard.md`, the CLI configuration standard

Scope: create `config/settei-cli-standard.md`. At the end, the standard for command-line tools exists, matching settei's `examples/settei-cli` reference. Acceptance: file exists, style contract followed, symbols verified.

Content to cover:

*The four-layer canonical order for CLIs*: **built-in defaults < config files (in command-line order) < environment variables < `--set` overrides (in occurrence order)**. This is the order `settei-optparse-applicative` documents and `examples/settei-cli/src/Settei/Example/Cli.hs` implements (`[builtInSource] <> fileSources <> [environment] <> cliSources "arguments" overrides`). Built-in defaults are a real `Source` of kind `BuiltInSource` (the example constructs it with `source`; `sourceFromPairs` is the validated alternative) so they appear in provenance like everything else, not silent fallbacks buried in code.

*CLI flag surface* from `settei-optparse-applicative/src/Settei/Optparse.hs`: `overrideOptions` parses repeatable `--set KEY=VALUE` (the key is validated at parse time; the value stays text so decoding stays in `resolve` — a `CliOverride` never holds a decoded value); `configPathOptions` parses repeatable `--config PATH`; `cliSources` turns the override list into **one `Source` per occurrence** so the shadow trace shows every occurrence and the last wins; `setteiOptions` bundles the option groups into a `SetteiOptions` record.

*Multiple formats*: when a CLI deliberately offers YAML, KDL, and Dhall config files, use `settei-formats` — `--config FORMAT:PATH` (`yaml:app.yaml`, `kdl:app.kdl`, `dhall:app.dhall`) via `Settei.Formats.Optparse.configInputOption`/`configInputOptions`, `parseConfigInput`, and `loadConfigInput` with shared `LoadOptions`. A single-format tool depends on that one adapter directly and skips the umbrella.

*Diagnostic modes*: `DiagnosticMode` = `NoDiagnostic | ExplainText | ExplainJson | CheckConfig | DescribeConfigText | DescribeConfigJson`. The fleet rule: every CLI exposes at least `--explain` (redacted provenance for the resolved config), `--describe-config` (the static schema from `describe`, listing every key, description, necessity, sensitivity — possible only because `Config` is inspectable), and `--check-config` (resolve and exit). Secret redaction applies to all CLI output exactly as in services: the same `ReportedValue` machinery, so `--explain` never prints a secret.

*Supersession statement*: name the layered-Dhall pattern (haskell-jitsurei `cli/hierarchical-config.md`) as superseded for new work, one sentence, matter-of-fact; the layered-Dhall doc remains valid history for tools already built on it (mori itself).

### Milestone 3 — `config/kubernetes-deployment.md`, the fleet Kubernetes operational standard

Scope: create `config/kubernetes-deployment.md`. This is the deployment half: how a keiro service's configuration and lifecycle behave in the cluster. It condenses settei's `docs/guides/kubernetes-cookbook.md` (ten sections) into fleet rules and adds the keiro-specific graceful-shutdown expectations that settei's cookbook does not cover. Acceptance: file exists, style contract followed, the shibuya/warp shutdown claims re-verified against source via mori, EP-7 referenced.

Content to cover:

*One image, many namespaces.* One container image is built once and promoted unchanged through dev, test, and production namespaces. If two environments need different behavior, that difference must be a configuration value delivered by the namespace, never a rebuilt image. Identically named ConfigMap/Secret objects exist in each namespace; the base Deployment manifest is namespace-agnostic.

*Kustomize overlays own namespace and data.* The repo layout is settei's `examples/settei-service/deploy/`: `base/` (namespace-agnostic Deployment) plus `overlays/dev`, `overlays/test`, `overlays/production`, each stamping the namespace and the ConfigMap/Secret data. The operational property to state as a rule: **the diff between two overlay directories is the entire configuration diff between two environments** — reviewing an environment promotion is reviewing that diff.

*Downward API posture.* The pod records its namespace by injecting `POD_NAMESPACE` via `fieldRef: metadata.namespace` and binding it as an ordinary public setting (key `kubernetes.namespace`) — recorded in provenance for forensics, **never used to derive behavior**. The runtime environment (`HASKELL_ENV`) is an explicit ConfigMap value, because namespace names churn (team renames, ephemeral preview namespaces) and `if namespace == "production"` logic rots. State this as: record identity, choose behavior explicitly.

*Mounted ConfigMap/Secret directories.* Mounted directories are read with `Settei.Kubernetes` (`settei-kubernetes` package): explicit file-to-key bindings are required — `fileBindings :: [FileBinding] -> Either (NonEmpty KubernetesSourceError) FileBindings`, then `readMountedDirectorySource` — because Kubernetes data keys routinely contain dots (`application.yaml`) that would collide with settei's structural dotted keys if auto-mapped. The adapter follows the kubelet's atomic-writer symlinks (`..data`), treats an absent bound file as an absent leaf, and **strips exactly one trailing newline by default** (`keepTrailingNewline` opts out) — flag this newline behavior explicitly since "why doesn't my secret match" is the classic symptom. `unboundMountedFiles` is the startup diagnostic for files present but unbound. `Settei.Kubernetes.Bindings.bindingsFromSecret`/`bindingsFromConfigMap` derive env `Bindings` where the binding and its Kubernetes provenance annotation come from the same row, so they cannot drift.

*The check-config rollout gate.* Every Deployment carries an initContainer (conventionally named `check-config`) that runs **the same image** as the main container with **identical env and volume mounts**, invoking the binary with `--check-config`. Exit 3 (source unreadable/unparseable) or exit 4 (resolution failure) fails the pod before traffic shifts, so a bad ConfigMap edit halts the rollout instead of crash-looping the service. State the invariant as the cookbook does: "a gate that checks different inputs is a false gate" — any drift between the initContainer's inputs and the main container's inputs makes the gate worthless. The exit codes are the ones the service standard reserves (cross-link Milestone 1's doc).

*No reload — config change means rollout restart.* Settei resolves once at startup by design; there is no file-watch and running processes never adopt changed mounts. Rotating a secret or editing a ConfigMap is completed by `kubectl rollout restart deployment/<name>`; the restart passes back through the check-config gate. Forbid hand-rolled reload loops.

*Offline manifest validation.* Before anything reaches a cluster: render every overlay with `kubectl kustomize <overlay-dir>` and grep the rendered output for fleet invariants (the initContainer is present and uses the same image reference as the main container; `POD_NAMESPACE` uses `fieldRef`; `HASKELL_ENV` comes from the ConfigMap; the Secret is mounted where `--secrets-dir` expects it). Optionally run kubeconform for schema validation. Settei's `examples/settei-service/deploy/validate.sh` is the reference script to cite.

*Placeholder-secret convention.* Checked-in overlay Secret manifests carry an unmistakable placeholder marker value (never a real credential, never an empty string that could pass validation); real values are injected by the delivery pipeline. The offline validation greps for the marker to ensure placeholders never render into a production apply. Follow the marker convention used in settei's overlay files (read them during implementation and quote the exact marker).

*Graceful shutdown under Kubernetes.* Kubernetes stops a pod by sending SIGTERM, waiting `terminationGracePeriodSeconds` (default 30s), then SIGKILL. Fleet expectations: an API pod installs warp's shutdown hooks — verify the exact warp setter names against the warp version the fleet pins (expected: `setInstallShutdownHandler` and `setGracefulShutdownTimeout` in `Network.Wai.Handler.Warp`; locate the source with `mori registry search warp` / `mori registry show <project> --full`) — so in-flight requests drain before the process exits. A worker pod translates SIGTERM into shibuya's `stopAppGracefully` (in shibuya's `Shibuya.App` module, `App.hs`): it signals adapter shutdown, drains in-flight messages with a drain timeout (default 30 seconds), stops the supervisor, and returns `False` if it had to force. Two derived rules: `terminationGracePeriodSeconds` must exceed the drain timeout (plus startup-of-shutdown slack — prescribe 60s for workers with the default 30s drain), and pgmq prefetch buffers are *released, not lost* on shutdown (unacked messages redeliver after visibility timeout), so shutdown never loses work but sloppy grace periods delay it. Re-verify both the shibuya and warp claims against source via mori before finalizing; record findings in Surprises & Discoveries if they differ from the above. For liveness/readiness/startup probes, do not restate rules here: reference the Kubernetes health-probe guidance EP-7 produces in haskell-jitsurei's `api/` area (EP-7 is `docs/plans/7-complete-the-servant-api-standards-in-haskell-jitsurei.md` in this repo). If EP-7's doc exists at implementation time, name its actual path (repo haskell-jitsurei + relative path); if not, write the reference as "the keiro API standards' Kubernetes probe guidance in haskell-jitsurei (`api/`, forthcoming under EP-7)" so the sentence stays true either way.

### Milestone 4 — `config/settei-gotchas.md` and `config/README.md`

Scope: create the gotcha catalogue and the area index. Acceptance: both files exist; the README lists all four content docs (and itself makes five files total in `config/`); each entry has a one-line description matching its DocRef description.

`config/settei-gotchas.md` is a terse catalogue — one `##` section per footgun, each stating the trap, the symptom, and the rule, a few sentences each. The catalogue (verified against settei source and ADRs during planning):

1. **Null is present input, not absence.** A higher-precedence source supplying `null` for a key *wins* and is handed to the decoder (usually a decode error); it does not fall through to a lower source. Deleting a key is done by deleting the key.
2. **A malformed high-precedence value never silently falls back.** If the environment supplies an unparseable value shadowing a valid file value, resolution fails with a decode error; settei never downgrades to the shadowed candidate. Fix the winning source.
3. **Precedence is positional only.** There is no per-source priority field; the `[Source]` list order is the entire model. A refactor that reorders the list silently changes precedence — keep source-list construction in one place per binary and state the order in a comment.
4. **Kubernetes annotations are metadata, not attestation.** The `kubernetes.*` provenance annotations (`object-kind`, `object-name`, `namespace`, `file-modified`) record what the caller *claimed* when constructing the source; settei has no cluster access and does not verify them. Never treat the report as proof a value came from a real Secret object.
5. **`Settei.Prelude` is internal.** It is not part of the adoption surface; import from the documented public modules only.
6. **Exact-version family pinning.** Adapter packages pin the core exactly (for example `settei ==0.2.0.0` in `settei-kubernetes.cabal`); mixed-version installs across the family are unsupported. Upgrade all settei packages in lockstep.
7. **Trailing-newline strip on mounted files.** (Cross-reference the Kubernetes doc's mounted-directory section rather than restating: exactly one trailing `\n` stripped by default; `keepTrailingNewline` for byte-faithful reads.)

`config/README.md` mirrors the shape of `keiki/README.md` (read it first): H1, one-paragraph orientation ("start here" framing, the adoption-target framing — settei is the standard for new and refactored fleet services even though adoption is in progress), then a short annotated list linking the four docs in reading order (service standard, CLI standard, Kubernetes deployment, gotchas), and a pointer to the settei repo's own guides via mori (`mori registry docs shinzui/settei`).

### Milestone 5 — registration and the supersession note

Scope: register everything in `mori.dhall` and mark the superseded haskell-jitsurei doc. Acceptance: `dhall type --file mori.dhall` succeeds; `git -C /Users/shinzui/Keikaku/bokuno/haskell-jitsurei diff --stat` shows exactly one changed file.

Edit `/Users/shinzui/Keikaku/bokuno/keiro-runtime-patterns/mori.dhall` in two places. First, add `"shinzui/settei"` to the `dependencies` list, keeping alphabetical order (between `"shinzui/kiroku"` and `"shinzui/shibuya"`). Second, append five `Schema.DocRef` entries at the end of the `docs` list — append only, never reorder existing entries (MasterPlan Integration Point 1; other plans append their own blocks concurrently). The five entries, following the existing record shape exactly:

- key `config-overview`, kind `Guide`, audience `Module`, location `LocalFile "config/README.md"`, description "Index of settei configuration and Kubernetes operational standards; start here".
- key `config-settei-service-standard`, kind `BestPractice`, audience `Module`, location `LocalFile "config/settei-service-standard.md"`, description "Fleet standard for microservice configuration with settei: algebra, secrets, source order, check-config".
- key `config-settei-cli-standard`, kind `BestPractice`, audience `Module`, location `LocalFile "config/settei-cli-standard.md"`, description "Fleet standard for CLI configuration with settei: four-layer precedence, formats, diagnostics".
- key `config-kubernetes-deployment`, kind `Runbook`, audience `Module`, location `LocalFile "config/kubernetes-deployment.md"`, description "Kubernetes operational standard: overlays, mounted sources, check-config gate, no-reload rollouts, graceful shutdown".
- key `config-settei-gotchas`, kind `Notes`, audience `Module`, location `LocalFile "config/settei-gotchas.md"`, description "Settei footgun catalogue: null presence, positional precedence, pinning, redaction edges".

Then edit `/Users/shinzui/Keikaku/bokuno/haskell-jitsurei/cli/hierarchical-config.md` — this plan's only edit outside this repository. Insert a clearly marked note directly after the H1 title and its existing tagline paragraph (the file currently opens with `# Hierarchical Config with Dhall` followed by a one-paragraph description ending "…keeps each file focused and independently valid."). The note is a blockquote so it is visually unmistakable:

```markdown
> **Superseded for new work.** The layered-Dhall pattern below is superseded by the
> settei configuration standard for all new keiro-fleet CLIs and services. See the
> `keiro-runtime-patterns` repo (mori project `shinzui/keiro-runtime-patterns`):
> `config/settei-cli-standard.md` (DocRef `config-settei-cli-standard`) and
> `config/settei-service-standard.md` (DocRef `config-settei-service-standard`).
> This document remains valid for tools already built on layered Dhall.
```

Change nothing else in that file. Do not commit in either repository (this plan's instructions exclude committing; the implementer runs the validation and stops).


## Concrete Steps

All commands run from `/Users/shinzui/Keikaku/bokuno/keiro-runtime-patterns` unless stated otherwise. Never search `/nix/store` or the filesystem root.

**Step 0 — orient.** Read, in this order: `keiki/README.md` and `keiki/transducer-best-practices.md` (style exemplars in this repo), then in `/Users/shinzui/Keikaku/bokuno/settei`: `docs/guides/kubernetes-service.md`, `docs/guides/kubernetes-cookbook.md`, `docs/guides/cli-application.md`, `examples/settei-service/src/Settei/Example/Service.hs`, `examples/settei-cli/src/Settei/Example/Cli.hs`, and `examples/settei-service/deploy/` (base, one overlay, `validate.sh`). If the settei checkout has moved, locate it with `mori registry show shinzui/settei --full`.

**Step 1 — create the doc area and write Milestone 1.**

```bash
mkdir -p /Users/shinzui/Keikaku/bokuno/keiro-runtime-patterns/config
```

Write `config/settei-service-standard.md` per Milestone 1. Then verify every symbol the doc names against source (adjust the list to what you actually named):

```bash
cd /Users/shinzui/Keikaku/bokuno/settei
grep -n "whenEq\|fallbackTo\|withDefault\|whenConfig" settei/src/Settei/Config.hs
grep -n "secretSetting\|publicSetting\|data Sensitivity" settei/src/Settei/Setting.hs
grep -n "resolve ::\|data ResolveResult\|data UnknownKeyPolicy" settei/src/Settei/Resolve.hs
grep -n "bindings ::\|mergeBindings\|prefixedBindings\|environmentSource" settei-env/src/Settei/Env.hs
grep -n "usageExitCode\|sourceExitCode\|resolutionExitCode" examples/settei-service/src/Settei/Example/Service.hs
grep -n "data DhallImportPolicy" settei-dhall/src/Settei/Dhall.hs
```

Expected: every grep prints at least one definition line (planning-time verification found, for example, `resolve :: ResolveOptions -> [Source] -> Config a -> ResolveResult a` at `settei/src/Settei/Resolve.hs:93` and `usageExitCode = 2` / `sourceExitCode = 3` / `resolutionExitCode = 4` near lines 98–104 of the example service). A grep with no output means the doc names a symbol that does not exist — fix the doc, not the grep.

**Step 2 — write Milestone 2.** Write `config/settei-cli-standard.md`. Verify:

```bash
cd /Users/shinzui/Keikaku/bokuno/settei
grep -n "cliSources\|setteiOptions\|overrideOptions\|configPathOptions\|data DiagnosticMode\|data CliOverride" settei-optparse-applicative/src/Settei/Optparse.hs
grep -n "data ConfigFormat\|parseConfigInput\|loadConfigInput" settei-formats/src/Settei/Formats.hs
grep -n "configInputOption" settei-formats/src/Settei/Formats/Optparse.hs
grep -n "builtInSource" examples/settei-cli/src/Settei/Example/Cli.hs
```

**Step 3 — write Milestone 3.** Before writing the shutdown section, re-verify the shibuya and warp facts:

```bash
mori registry show shinzui/shibuya --full   # locate the shibuya checkout
grep -n "stopAppGracefully\|drainTimeout" <shibuya-checkout>/shibuya-core/src/Shibuya/App.hs
mori registry search warp                    # locate warp source; then confirm
grep -rn "setInstallShutdownHandler\|setGracefulShutdownTimeout" <warp-checkout>/warp/Network/Wai/Handler/Warp/Settings.hs
```

(Planning-time evidence: `stopAppGracefully` lives at `App.hs:284` in shibuya-core with a 30-second default drain. If module paths differ, follow the checkout's actual layout.) Also check whether EP-7's probe doc already exists: look under `/Users/shinzui/Keikaku/bokuno/haskell-jitsurei/api/` for a health/probe doc; word the cross-reference per Milestone 3. Read the exact placeholder-secret marker from a checked-in overlay Secret manifest under `examples/settei-service/deploy/overlays/` and quote it. Then write `config/kubernetes-deployment.md`, and verify the settei-kubernetes symbols:

```bash
cd /Users/shinzui/Keikaku/bokuno/settei
grep -n "fileBindings ::\|readMountedDirectorySource\|unboundMountedFiles\|keepTrailingNewline" settei-kubernetes/src/Settei/Kubernetes.hs
grep -n "bindingsFromSecret\|bindingsFromConfigMap" settei-kubernetes/src/Settei/Kubernetes/Bindings.hs
```

**Step 4 — write Milestone 4.** Write `config/settei-gotchas.md` and `config/README.md`. Confirm the exact-pinning gotcha's evidence:

```bash
grep -n "settei *==" /Users/shinzui/Keikaku/bokuno/settei/settei-kubernetes/settei-kubernetes.cabal
```

Expected output includes `settei        ==0.2.0.0`.

**Step 5 — registration and supersession.** Edit `mori.dhall` per Milestone 5, then:

```bash
cd /Users/shinzui/Keikaku/bokuno/keiro-runtime-patterns
dhall type --file mori.dhall > /dev/null && echo OK
```

Expected output: `OK` (an ill-typed record or a misspelled `DocKind` constructor fails loudly instead). Then add the supersession blockquote to `/Users/shinzui/Keikaku/bokuno/haskell-jitsurei/cli/hierarchical-config.md` and confirm the blast radius:

```bash
git -C /Users/shinzui/Keikaku/bokuno/haskell-jitsurei diff --stat
```

Expected: exactly one file changed, `cli/hierarchical-config.md`, insertions only.

**Step 6 — final checks.** Run the link/index sweep in Validation and Acceptance, update Progress, write the Outcomes & Retrospective entry, and perform the ADR distillation pass: `docs/adr/` does not exist yet — create it with an ADR recording "settei is the fleet configuration standard" (context: raw-Dhall and layered-Dhall predecessors; decision: settei for all new and refactored services and CLIs; consequences: migration posture, supersession note) unless an earlier-running plan has already seeded an equivalent ADR, in which case update that one. Do not commit.


## Validation and Acceptance

Acceptance is behavioral, checked from a clean shell:

1. `ls /Users/shinzui/Keikaku/bokuno/keiro-runtime-patterns/config` lists exactly five files: `README.md`, `settei-service-standard.md`, `settei-cli-standard.md`, `kubernetes-deployment.md`, `settei-gotchas.md`.
2. `dhall type --file mori.dhall` (from the repo root) exits 0, and `grep -c "config-" mori.dhall` reports at least 5 (five DocRef keys); `grep -n "shinzui/settei" mori.dhall` hits the dependencies list.
3. Every config doc passes the style contract by inspection: no YAML frontmatter, H1 + bold tagline + scope paragraph, language tags on every fence, a trailing Related Patterns section.
4. Symbol truthfulness: the grep battery in Concrete Steps steps 1–4 — every symbol named in the docs exists in the settei 0.2.0.0 source (or shibuya/warp source for the shutdown section). Any miss is a doc bug.
5. Index completeness: for each of the four content docs, `grep -l <filename> config/README.md` hits — the README links all of them; and each README one-liner agrees with the corresponding DocRef description in `mori.dhall`.
6. Cross-links resolve: from `config/`, every relative link target named in the docs exists on disk (`settei-service-standard.md` ↔ `settei-cli-standard.md` ↔ `kubernetes-deployment.md` ↔ `settei-gotchas.md`). A quick check: `grep -oh "](\./[a-z-]*\.md)" config/*.md | sort -u` and confirm each named file exists.
7. Supersession: `head -15 /Users/shinzui/Keikaku/bokuno/haskell-jitsurei/cli/hierarchical-config.md` shows the blockquote note containing "Superseded for new work" and both DocRef keys; `git -C /Users/shinzui/Keikaku/bokuno/haskell-jitsurei diff --stat` shows only that file.
8. Discoverability end-to-end (if the mori CLI is available): `mori registry docs shinzui/keiro-runtime-patterns` lists the five new config docs alongside the keiki ones.

The docs are prose artifacts; there is no compile step beyond the Dhall type-check. "Effective beyond compilation" here means checks 4–8: the docs name only real symbols, the registry round-trips, and the superseded doc visibly redirects.


## Idempotence and Recovery

Every step is safe to repeat. Rewriting a markdown file under `config/` is idempotent by construction. The `mori.dhall` edit is append-only for `docs` and a single insertion in `dependencies`; if a retry finds the entries already present, do nothing — duplicate DocRef keys are the failure mode to avoid, so before appending, `grep -n "config-" mori.dhall` and only add what is missing. If `dhall type` fails after an edit, `git diff mori.dhall` isolates the change; `git checkout -- mori.dhall` restores the last good state and the append can be redone (existing keiki entries must never be reordered or reformatted). The haskell-jitsurei edit is a single blockquote insertion: before inserting, `grep -n "Superseded for new work" cli/hierarchical-config.md` — if it already hits, the note exists and the step is done; to back out, `git -C /Users/shinzui/Keikaku/bokuno/haskell-jitsurei checkout -- cli/hierarchical-config.md`. Nothing in this plan touches databases, clusters, or generated code, and nothing is committed, so the full recovery path for any misstep is `git checkout --` on the affected file(s) in the affected repo.

Concurrency note: other ExecPlans (EP-1 through EP-7) may be appending their own DocRef blocks to this repo's `mori.dhall` in parallel. Only append the `config-*` block and the one dependency line; if the file has grown since you last read it, re-read and re-append rather than pasting a stale whole-file copy.


## Interfaces and Dependencies

This plan produces documentation, so its "interfaces" are the doc surface and the registry entries; no Haskell code is written. The dependencies are the source trees the docs must stay truthful to:

- **settei 0.2.0.0** at `/Users/shinzui/Keikaku/bokuno/settei` (mori: `shinzui/settei`). Modules the docs may name, with the signatures that must hold as written in the docs: `Settei.Config` (`required :: Setting a -> Config a`, `optional :: Setting a -> Config (Maybe a)`, `whenConfig :: Config Bool -> Config a -> Config (Maybe a)`, `whenEq :: (Eq d) => Config d -> d -> Config a -> Config (Maybe a)`, `fallbackTo :: Config (Maybe a) -> Config a -> Config a`, `withDefault :: Setting a -> Default a -> Config a`, `describe :: Config a -> Schema`); `Settei.Setting` (`publicSetting`, `publicSettingWithRenderer`, `publicShowSetting`, `secretSetting :: Key -> Text -> Decoder a -> Setting a`, `data Sensitivity = Public | Secret`); `Settei.Resolve` (`resolve :: ResolveOptions -> [Source] -> Config a -> ResolveResult a`, `data UnknownKeyPolicy = WarnUnknownKeys | RejectUnknownKeys`); `Settei.Env` (`bindings :: [EnvBinding] -> Either (NonEmpty EnvError) Bindings`, `mergeBindings`, `prefixedBindings`, `environmentSource`, `readEnvironmentSource`); `Settei.Optparse` (`data DiagnosticMode = NoDiagnostic | ExplainText | ExplainJson | CheckConfig | DescribeConfigText | DescribeConfigJson`, `overrideOptions`, `configPathOptions`, `diagnosticModeOptions`, `setteiOptions`, `cliSources`); `Settei.Formats` (`data ConfigFormat = YamlFormat | KdlFormat | DhallFormat`, `parseConfigInput`, `loadConfigInput`, `fromKubernetesMountedFile`) and `Settei.Formats.Optparse` (`configInputOption`, `configInputOptions`); `Settei.Dhall` (`data DhallImportPolicy` with `NoImports` and `LocalImportsWithin`); `Settei.Kubernetes` (`fileBindings`, `readMountedDirectorySource`, `unboundMountedFiles`, `keepTrailingNewline`) and `Settei.Kubernetes.Bindings` (`bindingsFromSecret`, `bindingsFromConfigMap`). `Settei.Prelude` is internal and must not appear in any doc except the gotcha that says so.
- **shibuya** (mori: `shinzui/shibuya`) for `stopAppGracefully` in `Shibuya.App` (drain-with-timeout semantics, 30s default) — cited by the graceful-shutdown section; verify via mori during Milestone 3.
- **warp** (locate via `mori registry search warp`) for the graceful-shutdown settings in `Network.Wai.Handler.Warp` — verify names during Milestone 3.
- **danwa** at `/Users/shinzui/Keikaku/bokuno/danwa` — read-only citation target for the superseded raw-Dhall pattern (`danwa-server/src/Danwa/Server/Config.hs`, `danwa-workers/src/Danwa/Workers/Config.hs`).
- **haskell-jitsurei** at `/Users/shinzui/Keikaku/bokuno/haskell-jitsurei` — receives the one supersession edit (`cli/hierarchical-config.md`); EP-7's forthcoming probe doc under `api/` is referenced, not created, by this plan.
- **mori-schema** — `mori.dhall` already pins it by URL + sha256 (commit `026ae74331e5c516542af1dd96f041c658ed4621`); the new DocRefs use only existing constructors (`DocKind.Guide`, `DocKind.BestPractice`, `DocKind.Runbook`, `DocKind.Notes`, `DocAudience.Module`, `DocLocation.LocalFile`), so no pin change is needed or permitted here.
- **dhall CLI** — used only for `dhall type --file mori.dhall`.

At the end of each milestone the interface that "must exist" is the named markdown file, truthful to the signatures above; at the end of Milestone 5, the five DocRefs and the dependency entry in `mori.dhall`, and the supersession note in haskell-jitsurei.
