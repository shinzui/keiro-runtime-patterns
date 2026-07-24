# keiro Update Log

## 2026-07-23
* **Added**: Workflow reliability and recovery — lease sizing, the failure budget, `resurrectFailedWorkflow`, and the durable wake-source lifecycle guarantees
* **Added**: Evolution gates and rollout ordering — the five-gate ladder, the replay-impact verdict and targeted audit, and durable-value rollout rules
* **Update**: Durable workflows gained the `Failed` outcome, the full `ResumeSummary` field set, snapshot/await-fallback safety, and atomic patch-set recording at rotation
* **Update**: Runtime assembly now validates event codecs at the stream boundary and requires a boot-time migration handshake
* **Update**: Read models and projections document the three-component snapshot discriminator and the seed-divergence backstop
* **Update**: Keiro-dsl adoption records the retirement/upcaster checks, goldens, and replay-impact CLI surface
* **Update**: Gotchas added silent terminal workflow failure and the widened `mkEventStreamUnchecked` bypass
* **Migration**: Adopted the OKF pattern-catalog profile for Keiro guidance
