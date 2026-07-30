# keiro Update Log

## 2026-07-29
* **Update**: Overview now records the released 0.4.0.1/0.4.0.0 availability and scopes composable workspaces to the post-release source line; re-reviewed and approved
* **Update**: Command cycle now attributes dispatch rejections to keiro.keiro_dead_letters and terminal subscription failures to kiroku.dead_letters; re-reviewed and approved
* **Review**: Recorded a model technical-accuracy review for all thirteen concepts; approved eleven, changes requested for the overview (stale Hackage 0.3.0.0 caveat) and command-cycle-and-errors (subscription failures misattributed to keiro.keiro_dead_letters)
* **Update**: Evolution gates now reconstruct historical workspace membership and distinguish ownership and workspace-authority advisories from wire changes
* **Update**: Brownfield adoption now covers one-member manifests and attributable migration from independent same-context scaffolds
* **Update**: DSL adoption now treats a single file or composed workspace as the service input and includes workspace evolution advisories
* **Added**: Composable service workspaces standardizes manifest identity, single-owner composition, whole-service commands, atomic scaffolding, attributable adoption, and historical diffing

## 2026-07-28
* **Update**: Gotchas now cover partial structural bindings, dual event codec authority, and the snapshot boundary
* **Update**: Evolution guidance now uses the six-layer gate model and six-surface compatibility vectors
* **Update**: Runtime assembly now places structural binding evidence before validated stream construction
* **Update**: Overview now identifies the current Keiro 0.4 source contract and public release availability
* **Update**: DSL adoption now covers structural and opaque mappings, binding skeletons, coverage, and compatibility-vector gates
* **Added**: Brownfield adoption standardizes historical byte capture, structural bindings, codec comparison, replay audit, and cutover

## 2026-07-23
* **Added**: Workflow reliability and recovery — lease sizing, the failure budget, `resurrectFailedWorkflow`, and the durable wake-source lifecycle guarantees
* **Added**: Evolution gates and rollout ordering — the five-gate ladder, the replay-impact verdict and targeted audit, and durable-value rollout rules
* **Update**: Durable workflows gained the `Failed` outcome, the full `ResumeSummary` field set, snapshot/await-fallback safety, and atomic patch-set recording at rotation
* **Update**: Runtime assembly now validates event codecs at the stream boundary and requires a boot-time migration handshake
* **Update**: Read models and projections document the three-component snapshot discriminator and the seed-divergence backstop
* **Update**: Keiro-dsl adoption records the retirement/upcaster checks, goldens, and replay-impact CLI surface
* **Update**: Gotchas added silent terminal workflow failure and the widened `mkEventStreamUnchecked` bypass
* **Migration**: Adopted the OKF pattern-catalog profile for Keiro guidance
