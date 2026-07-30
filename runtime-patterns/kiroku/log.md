# kiroku Update Log

## 2026-07-29
* **Update**: Connection settings now append the application projection schema, keep the keiro schema out of the search path, and note runKirokuStoreWith; re-reviewed and approved
* **Update**: Operational invariants now state the qualified-keiro-SQL search-path rule; re-reviewed and approved
* **Review**: Recorded a model technical-accuracy review for all eight concepts; approved six, changes requested for connection-settings and operational-invariants (both prescribe the keiro schema in extraSearchPath, which keiro's Connection API refuses)

## 2026-07-23
* **Migration**: Adopted the OKF pattern-catalog profile for Kiroku guidance
