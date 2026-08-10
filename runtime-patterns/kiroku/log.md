# kiroku Update Log

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
