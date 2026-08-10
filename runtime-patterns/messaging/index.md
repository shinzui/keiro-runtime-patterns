# Gotcha

- [Messaging Gotchas](gotchas.md) - Consolidated messaging gotcha catalogue across Shibuya, pgmq-hs 0.5, Kafka, Kiroku, and Keiro

# Guide

- [Shibuya Processing Semantics](shibuya-processing.md) - Shibuya processing semantics every worker inherits: ack decisions, retries, batching, supervision, shutdown

# Overview

- [Keiro Messaging Patterns](overview.md) - Index of messaging standards for Keiro services, including pgmq-hs 0.5 queue lifecycle and reconciliation

# Pattern

- [Transport Selection](transport-selection.md) - Choosing a transport: the pgmq vs Kafka vs kiroku-subscription matrix and rule of thumb

# Reference

- [Messaging Glossary](glossary.md) - Shared messaging vocabulary: domain vs integration events, outbox, inbox, ack decisions, at-least-once plus idempotency

# Standard

- [Idempotent Inbox](inbox.md) - Consuming integration events idempotently: runInboxTransaction variants and disposition completeness
- [Integration Event Contracts](integration-events.md) - The integration event contract: envelope, identity and dedupe rules, topic versioning, trace continuation
- [Kiroku Subscriptions Through Shibuya](kiroku-subscriptions.md) - Consuming the event log through the shibuya-kiroku bridge: ack-coupled checkpoints, guardKirokuHandler, consumer groups
- [Transactional Outbox](outbox.md) - Publishing through the transactional outbox: IntegrationProducer, publisher worker, maintenance pass, deterministic ids
- [Typed Background Jobs On PGMQ](pgmq-jobs.md) - Typed background jobs on keiro-pgmq: job outcomes, retry and VT rules, and pgmq-hs 0.5 queue reconciliation
- [PGMQ queue lifecycle and reconciliation](pgmq-queue-reconciliation.md) - Validated durable queue names, additive startup reconciliation, truthful drift reports, notification recovery, and retry classification in pgmq-hs 0.5
- [Process Managers And Durable Timers](process-managers.md) - The process manager standard: UTF-8-stable deterministic ids, worker policies, batched durable timers, and the orchestration decision ladder

