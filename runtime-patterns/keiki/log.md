# keiki Update Log

## 2026-07-28
* **Update**: Historical upgrade guidance now links to the current validation vocabulary
* **Update**: Collection guidance distinguishes scalar field projections from unsupported collection operations
* **Update**: Checked composition now treats projection lowering as a non-structural boundary
* **Update**: Validation documents the three unconditional typed-projection warning families
* **Update**: Transducer authoring now covers whole-value models with generated scalar projection witnesses
* **Update**: Overview now targets Keiki 0.4 and routes readers to projection and replay-only guidance
* **Added**: Typed field projections define the Keiki 0.4 direct-base, guard-only contract for consumer-owned values

## 2026-07-23
* **Update**: Event schema evolution documents the two-stage event retirement protocol, same-version rung dispatch, and the runtime codec gate
* **Update**: Structured replay and hydration explains replay-only edges and two-phase inversion when reading a replay failure
* **Migration**: Adopted the OKF pattern-catalog profile for Keiki guidance
