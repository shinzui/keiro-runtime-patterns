---
type: Gotcha
title: "Keiro gotchas"
description: "Shared-stream, global-lock, structural-mapping, codec-authority, silent-workflow-failure, and bring-your-own Kafka traps"
timestamp: 2026-07-29T02:53:40Z
generated:
  by: human:nadeem
  at: "2026-07-29T02:53:40Z"
resource: mori://shinzui/keiro-runtime-patterns/docs/keiro-gotchas
tags: [keiro, gotchas]
status: current
reviews:
  - kind: model
    reviewer: claude-code
    reviewed_at: 2026-07-30T00:43:08Z
    document_timestamp: 2026-07-29T02:53:40Z
    scope: technical-accuracy
    outcome: approved
    provider: anthropic
    model: claude-fable-5
    effort: unspecified
    context: >-
      Model technical-accuracy review against the mori-resolved keiro checkout (0.4.0.1 tags plus post-release workspace commits), keiki 0.4.0.0, kiroku-store source, and Hackage release state; verified exported symbols, signatures, version claims, and links.
---

# Keiro gotchas

**Eight traps that cost real debugging time.**

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

## A terminally failed workflow stops retrying and stays silent

Once a workflow exhausts `maxAttempts`, the runtime appends `WorkflowFailed`, marks the instance `failed`, and removes it from resume discovery. No worker will ever touch it again. There is no log line at the moment it *stops* being retried, only the crash that pushed it over the ceiling.

Alert on `ResumeSummary.failed` and recover with `resurrectFailedWorkflow`, never with hand-written SQL against the instance and step-index tables. See [workflow reliability and recovery](workflow-reliability.md).

## Unvalidated stream construction now skips more than transducer checks

`mkEventStream` validates the event *codec* as well as the transducer: a bad schema version, duplicate event tags, or a broken upcaster chain now fails construction. That makes `mkEventStreamUnchecked` a bigger hole than it used to be — it bypasses the codec gate too.

Restore the missing rung or deduplicate the conflicting sources instead. `mkEventStreamUnchecked` is for tests and emergency forensics, never for getting a deployment out the door.

## Structural Does Not Mean Fallible Validation

A `StructuralBinding domain shape` must convert every valid generated shape to the consumer type and back. If construction can reject, normalize away information, or depend on an invariant absent from the shape, the declaration is not structural. Model the invariant in the checked shape or declare the boundary `mapped opaque`.

Finite fixture laws are evidence against mistakes, not a way to bless a partial conversion. See [brownfield Keiro adoption](brownfield-adoption.md).

## Generated Event Codecs Do Not Own Snapshot JSON

For a structural mapping, the `.keiro` declaration and generated codec are the only authority for current private-event JSON. Do not retain the consumer codec as a runtime fallback. Mapped register snapshots are different: they remain a consumer-JSON cache boundary whose mapping and fold fingerprints decide reuse.

Conflating the two either creates dual event interpretations or overstates what the generated mapping proves. Event history is durable truth; a snapshot miss should fall back to replay.

## Kafka is bring-your-own

Keiro deliberately has no `hw-kafka-client` dependency. `outboxRowToKafkaRecord` and `integrationEventToKafkaRecord` in `Keiro.Outbox.Kafka` produce a transport-neutral `KafkaProducerRecord`; the application owns the actual producer, consumer, and broker/group configuration.

Keep transport configuration in keiro-dsl hole kind 8. The [messaging standards](../messaging/overview.md) define the publication and consumption topology.

## Related Patterns

- [Runtime assembly](runtime-assembly.md)
- [Keiro-dsl adoption](dsl-adoption.md)
- [Command cycle and errors](command-cycle-and-errors.md)
- [Workflow reliability and recovery](workflow-reliability.md)
- [Brownfield Keiro adoption](brownfield-adoption.md)
