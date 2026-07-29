# ADR 0002: Adopt keiro-dsl for contracts and evolution

## Status

Accepted — 2026-07-22; broadened for structural consumer mappings — 2026-07-28

## Context

Hand-written Keiro services can call every public runtime API directly. Once a service spans node families, integration boundaries, queues, or durable workflow evolution, however, it also owns cross-node identity, disposition, compatibility, and deployment contracts that are difficult to keep consistent through prose and code review alone.

Keiro-dsl checks these contracts and generates deterministic structural wiring, but deliberately excludes domain decisions through a generated-code firewall and typed holes. Keiro 0.4 structural consumer mappings remove the former need to choose between checked private-event schemas and retaining existing application types: total hand-owned bindings now connect consumer types to generated wire shapes, and Keiki field witnesses expose eligible decision scalars without opaque guards.

## Decision

Adopt keiro-dsl when a service has more than one node family, any integration surface, expected schema/workflow evolution, existing private-event history, or consumer-owned persisted values whose wire shape and decision fields need checked evolution. A trivial single-aggregate service with none of those concerns may use the public runtime API directly, but must revisit the decision when its shape changes.

Never edit a `Generated.*` module. Change the `.keiro` specification and scaffold again, or implement the create-once hand-owned hole or structural binding. Run `keiro-dsl diff --since <git-ref>` in the specification's repository and block deployment on findings that break the configured compatibility gate.

## Consequences

- Cross-node references, disposition tables, persistence identities, and evolution rules become machine-checked contracts.
- Domain decision logic remains explicit hand-written Haskell on both adoption paths.
- Existing consumer-owned types may remain the domain model; structural mappings make the checked declaration and generated codec the sole private-event wire authority.
- Brownfield adoption requires genuine historical payload evidence, binding/harness conformance, validated streams, and a full pre-cutover replay audit.
- Generated output is disposable and reproducible; hole modules require ordinary ownership and review.
- The build and deployment workflow must run `check`, scaffold conformance, and the diff gate.

## Related Guidance

- [Keiro-dsl adoption](../../runtime-patterns/keiro/dsl-adoption.md)
- [Runtime assembly](../../runtime-patterns/keiro/runtime-assembly.md)
- [Command cycle and errors](../../runtime-patterns/keiro/command-cycle-and-errors.md)
- [Brownfield Keiro adoption](../../runtime-patterns/keiro/brownfield-adoption.md)
- [Typed field projections](../../runtime-patterns/keiki/typed-field-projections.md)
