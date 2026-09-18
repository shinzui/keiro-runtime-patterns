# Keiro runtime patterns

This repository is the terse, prescriptive source for Keiro runtime
implementation standards. It is optimized for engineers and coding agents;
product-oriented explanations belong in `keiro-runtime-docs`, and generally
applicable Haskell guidance belongs in `haskell-jitsurei`, as recorded in
[ADR 0006](docs/adr/0006-separate-pattern-product-and-general-haskell-docs.md).

These standards serve one microservice platform with isolated DDD bounded
contexts. Start with [domain design](runtime-patterns/architecture/domain-design.md):
business invariants, aggregates, commands, domain events, and workflows come
before package layout, generation, and transport choices.

Use [Getting started](runtime-patterns/getting-started.md) for
task-oriented routes. Use the [generated catalog index](runtime-patterns/index.md)
when you need the complete subject and concept listing.

## Discover with OKF and Mori

The Open Knowledge Format bundle is named `runtime-patterns`. After registering
this checkout with `mori register --local`, discover it without guessing paths:

```bash
mori registry bundles shinzui/keiro-runtime-patterns
mori registry concepts shinzui/keiro-runtime-patterns --bundle runtime-patterns
mori registry docs shinzui/keiro-runtime-patterns
okf show runtime-patterns messaging/process-managers
okf graph runtime-patterns --json
```

## Update contract

When changing a concept, update its frontmatter `timestamp` and add an entry to
the nearest `log.md`. Regenerate indexes rather than editing them by hand, then
run:

```bash
scripts/check-runtime-patterns
```

Pass a Git base ref to enforce that changed concepts and their nearest logs
appear together in the diff:

```bash
scripts/check-runtime-patterns origin/master
```

## Architecture decisions

`docs/adr/` is a second, separate OKF bundle (`adrs`) governed by the shared
`documentation.architectureDecisions` profile pinned in `docs/adr/profile.dhall`.
Each record carries a stable `docId` such as `ADR-7`; cite decisions by that
handle rather than by filename. `scripts/check-runtime-patterns` also validates
this bundle, enforcing the profile and log freshness, and can be queried the
same way:

```bash
mori registry concepts shinzui/keiro-runtime-patterns --bundle adrs
okf id list docs/adr --profile docs/adr/profile.dhall
```
