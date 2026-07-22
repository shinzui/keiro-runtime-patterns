# ADR 0005: Adopt settei for fleet configuration

## Status

Accepted — 2026-07-22

## Context

Fleet services and CLIs need typed configuration from files, environment variables, command-line overrides, and Kubernetes-mounted secrets. Existing applications use raw `FromDhall` loading or ad hoc layered Dhall. Those approaches do not share a source-precedence contract, retain shadowed provenance, structurally redact diagnostics, reject unknown keys consistently, or expose a deployment validation gate.

Settei 0.2.0.0 provides an inspectable `Config` algebra, typed and sensitivity-tagged settings, ordered sources, success-and-failure reports, validated environment and mounted-file bindings, tagged YAML/KDL/Dhall loaders, and reusable CLI diagnostic modes.

## Decision

Use the released settei package family as the configuration standard for all new and materially refactored keiro services and CLIs. Resolve fleet services in the low-to-high order general files, mounted Secret directories, then explicit environment bindings. Resolve fleet CLIs in the order built-ins, ordered tagged files, environment, then ordered command-line overrides.

Fleet services reject unknown keys and expose `--describe-config`, `--explain-config`, and `--check-config` modes. Kubernetes deployments run `--check-config` in an init container with the main process's image and inputs. Configuration changes take effect through a rollout, not in-process reload.

Raw or layered Dhall remains supported for existing applications during migration, but it is not the pattern for new work. Dhall can remain an input format through `settei-dhall` under an explicit import policy.

## Consequences

- Configuration declarations become statically inspectable and testable without reading sources.
- Secret sensitivity follows a logical setting across every delivery path, and settei diagnostics redact structurally.
- Operators get a stable provenance report and reserved exit codes for usage, source, and resolution failures.
- Environment variables and mounted files must be explicitly bound and validated.
- Every settei package must be upgraded in lockstep while the family uses exact internal pins.
- Existing raw-Dhall applications require an intentional migration; adoption does not happen merely by changing manifests.

## Alternatives Considered

**Continue raw `FromDhall` loading.** Rejected for new work because it provides typed decoding but not the fleet's precedence, provenance, redaction, unknown-key, and rollout-gate contract.

**Keep a separate layered-Dhall CLI pattern.** Rejected because it creates a second configuration model and omits consistent environment, command-line, and diagnostic semantics.

**Infer configuration from Kubernetes namespace identity.** Rejected because identity is not behavioral policy and makes deployment intent implicit.

**Reload projected files in process.** Rejected because a startup snapshot plus Kubernetes rollout is simpler to reason about and keeps source validation and process state aligned.

## Related Guidance

- [Settei service configuration standard](../../config/settei-service-standard.md)
- [Settei CLI configuration standard](../../config/settei-cli-standard.md)
- [Kubernetes deployment standard](../../config/kubernetes-deployment.md)
- [Settei gotchas](../../config/settei-gotchas.md)
