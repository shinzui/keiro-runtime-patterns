# Gotcha

- [Messaging Gotchas](gotchas.md) - Consolidated messaging gotcha catalogue across Shibuya, pgmq-hs 0.6, Kafka, Kiroku, and Keiro

# Guide

- [Shibuya Processing Semantics](shibuya-processing.md) - Shibuya processing semantics every worker inherits: ack decisions, application dead-letter codes, retries, batching, supervision, shutdown

# Overview

- [Keiro Messaging Patterns](overview.md) - Index of messaging standards for Keiro services, including pgmq-hs 0.6 queue lifecycle and reconciliation

# Pattern

- [Transport Selection](transport-selection.md) - Choosing a transport: the pgmq vs Kafka vs kiroku-subscription matrix and rule of thumb

# Reference

- [Messaging Glossary](glossary.md) - Shared messaging vocabulary: domain vs integration events, outbox, inbox, ack decisions, at-least-once plus idempotency

# Standard

- [Idempotent Inbox](inbox.md) - Consuming integration events idempotently: runInboxTransaction variants, delegated downstream receipts, and disposition completeness
- [Integration Event Contracts](integration-events.md) - The integration event contract: envelope, identity and dedupe rules, topic versioning, trace continuation
- [Kiroku Subscriptions Through Shibuya](kiroku-subscriptions.md) - Consuming the event log through the shibuya-kiroku bridge: ack-coupled checkpoints, guardKirokuHandler, consumer groups
- [Transactional Outbox](outbox.md) - Transactional enqueue, publication failure and terminal rejection, atomic finalization, maintenance, and deterministic identity
- [Typed Background Jobs On PGMQ](pgmq-jobs.md) - Typed background jobs on keiro-pgmq 0.17: required job ordering, FIFO-heads, retry and VT rules, guarded DLQ retention, and partitioned provisioning
- [PGMQ queue lifecycle and reconciliation](pgmq-queue-reconciliation.md) - Validated durable queue names, additive startup reconciliation, truthful drift reports, notification recovery, and PGMQ 1.13 schema, partition premake, and retry classification in pgmq-hs 0.6
- [Process Managers And Durable Timers](process-managers.md) - The process manager standard: UTF-8-stable deterministic ids, the typed reaction runner, worker policies, batched durable timers, and the orchestration decision ladder

