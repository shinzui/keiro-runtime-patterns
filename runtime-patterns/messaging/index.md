# Gotcha

- [Messaging Gotchas](gotchas.md) - Consolidated messaging gotcha catalogue across shibuya, pgmq, Kafka, kiroku, and keiro

# Guide

- [Shibuya Processing Semantics](shibuya-processing.md) - Shibuya processing semantics every worker inherits: ack decisions, retries, batching, supervision, shutdown

# Overview

- [Keiro Messaging Patterns](overview.md) - Index of messaging standards for keiro services: process managers, integration events, transports; start here

# Pattern

- [Transport Selection](transport-selection.md) - Choosing a transport: the pgmq vs Kafka vs kiroku-subscription matrix and rule of thumb

# Reference

- [Messaging Glossary](glossary.md) - Shared messaging vocabulary: domain vs integration events, outbox, inbox, ack decisions, at-least-once plus idempotency

# Standard

- [Idempotent Inbox](inbox.md) - Consuming integration events idempotently: runInboxTransaction variants and disposition completeness
- [Integration Event Contracts](integration-events.md) - The integration event contract: envelope, identity and dedupe rules, topic versioning, trace continuation
- [Kiroku Subscriptions Through Shibuya](kiroku-subscriptions.md) - Consuming the event log through the shibuya-kiroku bridge: ack-coupled checkpoints, guardKirokuHandler, consumer groups
- [Transactional Outbox](outbox.md) - Publishing through the transactional outbox: IntegrationProducer, publisher worker, maintenance pass, deterministic ids
- [Typed Background Jobs On PGMQ](pgmq-jobs.md) - Typed background jobs on keiro-pgmq: Job, JobOutcome, RetryPolicy, VT rules, queue-name pitfalls
- [Process Managers And Durable Timers](process-managers.md) - The process manager standard: saga streams, deterministic ids, worker policies, durable timers, and the orchestration decision ladder

