# keiro Update Log

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
