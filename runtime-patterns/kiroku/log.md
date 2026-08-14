# kiroku Update Log

## 2026-08-14
* **Update**: Route the frozen checkpoint relation and replay-history retention
* **Update**: Record retention-lease refusal of hard delete and direct destructive SQL, and the ascending stream lock order
* **Update**: Publish the frozen subscription\_checkpoints\_v1 relation for out-of-process readers and subtract from the visible head
* **Update**: Separate the authoritative append frontier from the visible global head
* **Update**: Target the Kiroku Store 0.7 line and route replay-history retention
* **Added**: Add the replay-history retention lease standard and its destructive-statement refusals

## 2026-08-11
* **Update**: Replace provisional missing-checkpoint guidance with Kiroku Store 0.5's explicit atomic initialization policies, existing-row precedence, and transaction-composable reset boundary

## 2026-08-10
* **Added**: Add the member-aware durable checkpoint snapshot and global-position-distance standard.
* **Update**: Add read-only member-aware checkpoint inventory without weakening explicit first-run intent.
* **Update**: Route the Kiroku 0.4 durable checkpoint inventory.

## 2026-08-09
* **Update**: Subscription guidance now requires explicit first-run checkpoint intent and blocks future-only side-effect workers until from-head behavior is provided atomically.

## 2026-08-06
* **Update**: Kiroku observability documents the shared eventHandler slot: metricsEventHandler, subscriptionTraceHandler, and Keiro's kirokuEventBridge compose into one field, and every handle they close over must exist before withStore.
* **Migration**: Move the bundle to OKF v0.2: every concept gains a generated provenance mapping and restates its timestamp in UTC

## 2026-07-29
* **Update**: Connection settings now append the application projection schema, keep the keiro schema out of the search path, and note runKirokuStoreWith; re-reviewed and approved
* **Update**: Operational invariants now state the qualified-keiro-SQL search-path rule; re-reviewed and approved
* **Review**: Recorded a model technical-accuracy review for all eight concepts; approved six, changes requested for connection-settings and operational-invariants (both prescribe the keiro schema in extraSearchPath, which keiro's Connection API refuses)

## 2026-07-23
* **Migration**: Adopted the OKF pattern-catalog profile for Kiroku guidance
