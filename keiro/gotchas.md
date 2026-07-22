# Keiro gotchas

**Four traps that cost real debugging time.**

This checklist captures cross-cutting runtime constraints that are easy to miss when reading one subsystem at a time.

## `alternative` shares stream identity

Mounting a keiki `alternative` composite as one `EventStream` gives both machines one stream identity, version counter, ordered log, and snapshot. That is almost never correct for sibling aggregates with separate identities and lifecycles.

The dividing rule is: compose in keiki inside one consistency boundary; across streams, coordinate with a projection, router, process manager, or workflow. See [transducer best practices](../keiki/transducer-best-practices.md) and the keiro repo's `docs/guides/choosing-a-primitive.md`.

## `$all` is a throughput ceiling

Every append participates in kiroku's single-row `$all` global-position lock. This deliberate serialization gives a simple deterministic global order but caps write throughput across otherwise unrelated streams.

Capacity-plan for the ceiling. In particular, keep `runCommandWithSql`, `runCommandWithSqlEvents`, and inline projection callbacks minimal because every extra round trip extends the store-wide lock window.

## Transactional runners require the resource effect

`runCommandWithSql`, `runCommandWithSqlEvents`, and `runCommandWithProjections` require `KirokuStoreResource`; plain `runCommand` does not. Acquire it with `withKirokuStore` and interpret it with `runStoreResource`. An unexpected missing-effect compiler error on a transactional runner usually points to this assembly boundary.

See [runtime assembly](runtime-assembly.md).

## Kafka is bring-your-own

Keiro deliberately has no `hw-kafka-client` dependency. `outboxRowToKafkaRecord` and `integrationEventToKafkaRecord` in `Keiro.Outbox.Kafka` produce a transport-neutral `KafkaProducerRecord`; the application owns the actual producer, consumer, and broker/group configuration.

Keep transport configuration in keiro-dsl hole kind 8. The forthcoming messaging standards define the publication and consumption topology.

## Related Patterns

- [Runtime assembly](runtime-assembly.md)
- [Keiro-dsl adoption](dsl-adoption.md)
- [Command cycle and errors](command-cycle-and-errors.md)
