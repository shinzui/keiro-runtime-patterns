# Kiroku Append and Read Patterns

**Choose the strictest `ExpectedVersion` you can, supply event ids for retries, and never trust the version inside `WrongExpectedVersion`.**

Use this guide when appending to or reading from a Kiroku stream. It covers optimistic concurrency, idempotent retry, cursor semantics, and bounded-memory reads.

## Declare the strongest honest expectation

Every append declares an `ExpectedVersion`. Prefer the strongest constructor the caller can prove:

- `NoStream`: the stream must not exist. Use it to create an aggregate.
- `StreamExists`: the stream must exist, but its current version is irrelevant.
- `ExactVersion version`: the stream must be at exactly the version that was read.
- `AnyVersion`: create or append without checking the current version. Reserve it for deliberately unordered writers.

Stream versions are local to one stream and one-based: the first event is version 1, and a stream containing N events is at version N. `StreamVersion 0` represents the empty or absent starting point.

## Make retries idempotent

Set `EventData.eventId = Just eventId` before any append that may be retried. `Nothing` asks Kiroku to mint a UUIDv7; `Just` gives every attempt the same identity. If the first attempt committed but its response was lost, the retry returns `DuplicateEvent`. Treat that duplicate as successful completion of the intended write after confirming it is the supplied id.

Kiroku automatically retries SQLSTATE `40001` and `40P01` once. This is safe because event ids are prepared before retrying. Application-level retries must preserve those same ids too.

```haskell
-- WRONG: each retry can become a distinct persisted event.
event = EventData { eventId = Nothing, eventType, payload, metadata, causationId, correlationId }

-- CORRECT: generate once and retain it across every attempt.
event = EventData { eventId = Just commandEventId, eventType, payload, metadata, causationId, correlationId }
```

## Re-read after a version conflict

Never use the third field of `WrongExpectedVersion` as the live stream version. It is always the placeholder `StreamVersion 0`; Kiroku deliberately avoids an extra read on the rejected append. Call `getStream` to learn the current version, then reload or reject the command according to the domain policy.

```haskell
-- WRONG: "actual" is a placeholder, not the database value.
Left (WrongExpectedVersion stream expected actual) -> retryFrom actual

-- CORRECT: perform an explicit read before deciding what to do.
Left (WrongExpectedVersion stream _ _) -> do
  current <- getStream stream
  reloadOrReject current
```

## Treat cursors as exclusive

Kiroku read cursors are exclusive. `readStreamForward name (StreamVersion 0) limit` starts at the first event; subsequent pages pass the last returned version. The same rule applies to forward and backward reads and to `$all` cursors.

Use `readStreamForward` when the caller wants one bounded page. Use `readStreamForwardStream name cursor 256` for an unbounded replay: it pages through Streamly in constant memory. Adjust the recommended page size of 256 only when event width or measured round-trip cost justifies it.

Treat `GlobalPosition` as an opaque `$all` cursor. Kiroku promises only a strictly increasing, total order. Positions need not be contiguous, so never add one or infer event counts from position differences.

Use `eventExistsInStream` for a cheap event-id membership check. For fan-in reads, batch the distinct `RecordedEvent.originalStreamId` values and resolve them with `lookupStreamNames`; do not query Kiroku’s internal tables or add a stream-name lookup per event.

## Related Patterns

- [Transactions and Projections](./transactions-and-projections.md)
- [Subscriptions](./subscriptions.md)
- [Operational Invariants](./operational-invariants.md)

