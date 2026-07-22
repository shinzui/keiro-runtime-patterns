# Keiro runtime patterns

**Prescriptive defaults for assembling reliable services on the keiro 0.3 runtime.**

Use this area as the fleet standard for application wiring and operating boundaries; use the keiro repo's `docs/user/README.md` as the long-form API reference. The runtime behavior documented here was established in keiro 0.2.0.0 and remains the contract in the verified 0.3.0.0 release.

## Start here

- [Runtime assembly](runtime-assembly.md) — acquire resources, validate event streams, and configure options.
- [Two-schema arrangement](two-schema-arrangement.md) — keep the kiroku store, keiro framework, and application schemas distinct.
- [Command cycle and errors](command-cycle-and-errors.md) — classify command failures and reject ambiguity as a definition bug.

The remaining projection, workflow, telemetry, DSL, and gotcha guides will be added as this documentation plan advances.

## Related Patterns

- [Kiroku event-store patterns](../kiroku/README.md)
- [Keiki transducer patterns](../keiki/README.md)
