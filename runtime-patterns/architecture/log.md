# architecture Update Log

## 2026-09-18
* **Update**: Record changes-requested review: domain-driver assertions and dependencies have grown in the reference service.
* **Update**: Record changes-requested review: legacy underscore module paths and missing typed QueryContract module.
* **Update**: Require Language 6 from Keiro 0.17.0.0 onward; align authoring guidance with the adopted baseline and retain accurate tooling behavior.
* **Update**: Require Language 6 from Keiro 0.17.0.0 onward; align authoring guidance with the adopted baseline and retain accurate tooling behavior.
* **Update**: Require Language 6 from Keiro 0.17.0.0 onward; align authoring guidance with the adopted baseline and retain accurate tooling behavior.
* **Update**: Require Language 6 from Keiro 0.17.0.0 onward; align authoring guidance with the adopted baseline and retain accurate tooling behavior.
* **Update**: Require Language 6 from Keiro 0.17.0.0 onward; align authoring guidance with the adopted baseline and retain accurate tooling behavior.
* **Update**: Correct symbolic firewall exceptions and generated module inventory against the current scaffolder.
* **Update**: Remove the unconditional single-Holes rule in favor of declared generated and hand-owned responsibilities.
* **Update**: Derive tests from domain invariants, workflow outcomes, concurrent commands, and request retry semantics.
* **Update**: Align the runtime-package example with the core package that compiles generated code.
* **Update**: Require domain modeling before scaffolding and align the runtime-package example with ticket-core.
* **Update**: Replace legacy replication instructions with an explicitly illustrative domain-first Conversation vertical using current workspace and ownership conventions.
* **Update**: Align stable-language generated transition ownership with conditional create-once hooks and behavior witnesses.
* **Update**: Keep six application packages; explicitly exclude generated conformance tooling and name core as the runtime package.
* **Update**: Start architecture adoption with business scenarios and invariant ownership before DSL and package layout.
* **Added**: Domain-first platform standard: bounded contexts, invariants, aggregates, commands, domain events, workflows, and consistency before implementation choices.
* **Update**: Place the candidate reaction process's generated input module and decoder-only hole.
* **Update**: Add candidate Language 6 guidance, the HoleContractDrift refusal, the process-reaction ledger row, and comment-only QueuePolicy.hs churn.
* **Update**: Add withFreshResourceStore and withFreshResourceStorePrepared for privileged role or grant preparation.
* **Update**: Exempt Keiro's deterministic producer outbox identity (UUIDv8 OutboxId, opaque message ID) from TypeID wrapping.

## 2026-09-06
* **Update**: Reuse the published cohort test fixture through complete service migration wrappers.
* **Update**: Require combined legacy name/edition migration and refuse corrupt or pre-v2 ledgers.
* **Update**: Route generated Haskell adoption and rollback through the edition guide.
* **Update**: Adopt idiomatic-v2 shared extensions, concise record projections, and the explicit edition gate.

## 2026-09-01
* **Update**: Place domain newtypes and TypeIDs in the core package
* **Update**: Keep generated domain wrappers intact across the hand-owned module boundary
* **Update**: Require consumer-owned mapped types to be nominal and service-owned identifiers to be TypeID-backed
* **Update**: Route service architecture through the domain newtype and TypeID standard
* **Added**: Make TypeID-backed newtypes the default for service-owned identifiers and require nominal types for every key domain scalar
* **Update**: Make the workspace manifest the standard service input and document the trivial single-aggregate exception

## 2026-08-14
* **Update**: Declare stable language version 5 in the preamble contract

## 2026-08-10
* **Update**: Adopt candidate Language 5 mapped consumers and separate semantic from generated-artifact impact.
* **Update**: Include semantic-local context evidence modules in the generated compilation contract.

## 2026-08-06
* **Migration**: Move the bundle to OKF v0.2: every concept gains a generated provenance mapping and restates its timestamp in UTC
* **Update**: Test layout separates hand-owned dsl-test from the generated conformance package
* **Update**: Architecture route reaches the generated compilation contract
* **Update**: Scaffolding covers the 0.11 sidecar ledger names, the refusal on legacy names, and --apply-name-migrations
* **Added**: The generated compilation contract states the GHC2024 baseline, the closed module-local extension set, the runtime-package authority, and the generated conformance package
* **Update**: Service contract example declares the stable language version instead of version 1

## 2026-07-31
* **Update**: Spec placement requires the language preamble and covers nominal and version-2 generated modules

## 2026-07-29
* **Review**: Recorded a model technical-accuracy review for all eight concepts; every concept approved against the danwa and jitsurei reference applications and the scaffolder at HEAD
* **Update**: Architecture guidance now supports single-file and multi-file service inputs with whole-workspace records and regeneration

## 2026-07-28
* **Update**: Allowlist now places concept bindings vertically and permits DomainBindings only for shared mapped types
* **Update**: Test layout now requires structural conformance and isolates brownfield codec comparison from production modules
* **Update**: Scaffolding guidance now covers mapped declarations, binding explanations, coverage, and comparison evidence
* **Update**: Vertical layout now places shared structural shape, projection, binding, and comparison modules
* **Update**: Core package ownership now includes structural shapes, witnesses, bindings, and fixtures
* **Update**: Architecture overview now includes generated structural modules and hand-owned bindings

## 2026-07-23
* **Migration**: Adopted the OKF pattern-catalog profile for architecture guidance
