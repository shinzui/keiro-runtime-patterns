# ADR 0002: Adopt keiro-dsl for contracts and evolution

## Status

Accepted — 2026-07-22

## Context

Hand-written Keiro services can call every public runtime API directly. Once a service spans node families, integration boundaries, queues, or durable workflow evolution, however, it also owns cross-node identity, disposition, compatibility, and deployment contracts that are difficult to keep consistent through prose and code review alone.

Keiro-dsl checks these contracts and generates deterministic structural wiring, but deliberately excludes domain decisions through a generated-code firewall and typed holes.

## Decision

Adopt keiro-dsl when a service has more than one node family, any integration surface, or expected schema/workflow evolution. A trivial single-aggregate service with none of those concerns may use the public runtime API directly, but must revisit the decision when its shape changes.

Never edit a `Generated.*` module. Change the `.keiro` specification and scaffold again, or implement the create-once hand-owned hole. Run `keiro-dsl diff --since <git-ref>` in the specification's repository and block deployment on every `BREAKING` result.

## Consequences

- Cross-node references, disposition tables, persistence identities, and evolution rules become machine-checked contracts.
- Domain decision logic remains explicit hand-written Haskell on both adoption paths.
- Generated output is disposable and reproducible; hole modules require ordinary ownership and review.
- The build and deployment workflow must run `check`, scaffold conformance, and the diff gate.

## Related Guidance

- [Keiro-dsl adoption](../../keiro/dsl-adoption.md)
- [Runtime assembly](../../keiro/runtime-assembly.md)
- [Command cycle and errors](../../keiro/command-cycle-and-errors.md)
