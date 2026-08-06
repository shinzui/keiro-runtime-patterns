let Schema =
      https://raw.githubusercontent.com/shinzui/mori-schema/b85081a0e935a976202fd7a1227f8b93e2cbeb23/package.dhall
        sha256:1501e5c3e55e78d2a58774e2f8aefda20e32b948fa7caf639473fce90929464b

in  Schema.Project::{
    , project = Schema.ProjectIdentity::{
      , name = "keiro-runtime-patterns"
      , namespace = "shinzui"
      , type = Schema.PackageType.Other "Documentation"
      , language = Schema.Language.Haskell
      , lifecycle = Schema.Lifecycle.Active
      , description = Some
          "Docs, patterns, and best practices for the Keiro runtime (keiki, keiro, kiroku, shibuya)"
      , domains = [ "EventSourcing", "Workflow" ]
      }
    , repos = [ Schema.Repo::{ name = "keiro-runtime-patterns" } ]
    , dependencies =
      [ "shinzui/keiki"
      , "shinzui/keiro"
      , "shinzui/kiroku"
      , "shinzui/settei"
      , "shinzui/shibuya"
      , "shinzui/pg-migrate"
      , "shinzui/pgmq-hs"
      , "shinzui/okf"
      ]
    , skills =
      [ Schema.Skill::{
        , name = "update-patterns"
        , description =
            "Reconcile the runtime-patterns catalog with upstream keiro-ecosystem source: report which upstream repositories moved since the catalog last tracked them, rewrite affected concepts from the real source, add concepts for uncovered capabilities, retire ones whose feature is gone, and advance per-project git watermarks"
        , path = Some "agents/skills/update-patterns"
        , compatibility = Some "Requires git, jq, and the mori CLI"
        }
      ]
    , okfBundles =
      [ Schema.OkfBundle::{
        , name = "runtime-patterns"
        , path = "runtime-patterns"
        , profile = Some "okf/runtime-patterns.dhall"
        , okfVersion = "0.1"
        , description = Some
            "Prescriptive Keiro runtime standards, patterns, guides, and runbooks"
        }
      ]
    , docs =
      [ Schema.DocRef::{
        , key = "keiki-overview"
        , kind = Schema.DocKind.Guide
        , audience = Schema.DocAudience.Module
        , description = Some
            "Index of Keiki transducer patterns for Keiro services; start here"
        , location = Schema.DocLocation.LocalFile "runtime-patterns/keiki/overview.md"
        }
      , Schema.DocRef::{
        , key = "keiki-transducer-best-practices"
        , kind = Schema.DocKind.BestPractice
        , audience = Schema.DocAudience.Module
        , description = Some
            "Core rules for authoring Keiki transducers with the builder DSL"
        , location =
            Schema.DocLocation.LocalFile "runtime-patterns/keiki/transducer-best-practices.md"
        }
      , Schema.DocRef::{
        , key = "keiki-constructor-evidence"
        , kind = Schema.DocKind.BestPractice
        , audience = Schema.DocAudience.Module
        , description = Some
            "Minting InCtor and WireCtor values through trusted producers so composition, replay, and symbolic exclusion keep their proofs"
        , location =
            Schema.DocLocation.LocalFile "runtime-patterns/keiki/constructor-evidence.md"
        }
      , Schema.DocRef::{
        , key = "keiki-build-time-validation"
        , kind = Schema.DocKind.Guide
        , audience = Schema.DocAudience.Module
        , description = Some
            "Asserting transducers are well-formed in CI with validateTransducer"
        , location =
            Schema.DocLocation.LocalFile "runtime-patterns/keiki/build-time-validation.md"
        }
      , Schema.DocRef::{
        , key = "keiki-diagnosing-rejected-commands"
        , kind = Schema.DocKind.Guide
        , audience = Schema.DocAudience.Module
        , description = Some
            "Using stepEither and StepFailure to learn why a command was rejected"
        , location =
            Schema.DocLocation.LocalFile "runtime-patterns/keiki/diagnosing-rejected-commands.md"
        }
      , Schema.DocRef::{
        , key = "keiki-collections-and-opaque-guards"
        , kind = Schema.DocKind.Pattern
        , audience = Schema.DocAudience.Module
        , description = Some
            "Modeling collections without losing solver verification through opaque guards"
        , location =
            Schema.DocLocation.LocalFile
              "runtime-patterns/keiki/collections-and-opaque-guards.md"
        }
      , Schema.DocRef::{
        , key = "keiki-typed-field-projections"
        , kind = Schema.DocKind.Pattern
        , audience = Schema.DocAudience.Module
        , description = Some
            "Guard-only field witnesses that expose a scalar of a consumer-owned record without an opaque guard or a flattened domain model"
        , location =
            Schema.DocLocation.LocalFile
              "runtime-patterns/keiki/typed-field-projections.md"
        }
      , Schema.DocRef::{
        , key = "keiki-exact-projection-domains"
        , kind = Schema.DocKind.BestPractice
        , audience = Schema.DocAudience.Module
        , description = Some
            "Declaring a projection's exact image and canonical inverse so symbolic verification can return a proof"
        , location =
            Schema.DocLocation.LocalFile
              "runtime-patterns/keiki/exact-projection-domains.md"
        }
      , Schema.DocRef::{
        , key = "keiki-operator-conflicts"
        , kind = Schema.DocKind.Guide
        , audience = Schema.DocAudience.Module
        , description = Some
            "Resolving the lens / generic-lens (.>) operator clash three ways"
        , location = Schema.DocLocation.LocalFile "runtime-patterns/keiki/operator-conflicts.md"
        }
      , Schema.DocRef::{
        , key = "keiki-json-event-codecs"
        , kind = Schema.DocKind.Guide
        , audience = Schema.DocAudience.Module
        , description = Some
            "Deriving kind-discriminated JSON codecs with keiki-codec-json"
        , location = Schema.DocLocation.LocalFile "runtime-patterns/keiki/json-event-codecs.md"
        }
      , Schema.DocRef::{
        , key = "keiki-diagram-docs"
        , kind = Schema.DocKind.Guide
        , audience = Schema.DocAudience.Module
        , description = Some
            "Generating Mermaid diagrams, atlas sections, and edge inspectors from transducers"
        , location = Schema.DocLocation.LocalFile "runtime-patterns/keiki/diagram-docs.md"
        }
      , Schema.DocRef::{
        , key = "keiki-structured-replay-and-hydration"
        , kind = Schema.DocKind.Guide
        , audience = Schema.DocAudience.Module
        , description = Some
            "Diagnosing hydration failures with reconstituteEither, replayEvents, and ReplayFailure"
        , location =
            Schema.DocLocation.LocalFile
              "runtime-patterns/keiki/structured-replay-and-hydration.md"
        }
      , Schema.DocRef::{
        , key = "keiki-event-schema-evolution"
        , kind = Schema.DocKind.Guide
        , audience = Schema.DocAudience.Module
        , description = Some
            "Evolving persisted event JSON with in-band versions, pinned kinds, and upcaster chains"
        , location =
            Schema.DocLocation.LocalFile "runtime-patterns/keiki/event-schema-evolution.md"
        }
      , Schema.DocRef::{
        , key = "keiki-checked-composition"
        , kind = Schema.DocKind.Pattern
        , audience = Schema.DocAudience.Module
        , description = Some
            "Wiring transducers with composeChecked, alternative, and the feedback1 stateless-only trap"
        , location = Schema.DocLocation.LocalFile "runtime-patterns/keiki/checked-composition.md"
        }
      , Schema.DocRef::{
        , key = "keiki-upgrading-to-keiki-0-2"
        , kind = Schema.DocKind.Guide
        , audience = Schema.DocAudience.Module
        , description = Some
            "Migration notes for keiki 0.2: noEmit, new validation warnings, snapshot-hash change, Decider removal"
        , location =
            Schema.DocLocation.LocalFile "runtime-patterns/keiki/upgrading-to-keiki-0-2.md"
        }
      , Schema.DocRef::{
        , key = "kiroku-overview"
        , kind = Schema.DocKind.Guide
        , audience = Schema.DocAudience.Module
        , description = Some
            "Index of kiroku event-store standards for keiro services; start here"
        , location = Schema.DocLocation.LocalFile "runtime-patterns/kiroku/overview.md"
        }
      , Schema.DocRef::{
        , key = "kiroku-append-and-read"
        , kind = Schema.DocKind.BestPractice
        , audience = Schema.DocAudience.Module
        , description = Some
            "ExpectedVersion semantics, idempotent retries via supplied event ids, and streaming reads"
        , location = Schema.DocLocation.LocalFile "runtime-patterns/kiroku/append-and-read.md"
        }
      , Schema.DocRef::{
        , key = "kiroku-transactions-and-projections"
        , kind = Schema.DocKind.BestPractice
        , audience = Schema.DocAudience.Module
        , description = Some
            "Atomic append plus projection with runTransactionAppendingResource, and why the other combinators are traps"
        , location =
            Schema.DocLocation.LocalFile "runtime-patterns/kiroku/transactions-and-projections.md"
        }
      , Schema.DocRef::{
        , key = "kiroku-connection-settings"
        , kind = Schema.DocKind.BestPractice
        , audience = Schema.DocAudience.Module
        , description = Some
            "Store schema and NOTIFY channel, extraSearchPath seam, timeouts, and synchronous handler discipline"
        , location = Schema.DocLocation.LocalFile "runtime-patterns/kiroku/connection-settings.md"
        }
      , Schema.DocRef::{
        , key = "kiroku-subscriptions"
        , kind = Schema.DocKind.BestPractice
        , audience = Schema.DocAudience.Module
        , description = Some
            "At-least-once subscriptions, per-batch checkpoints, overflow policies, and Serial consumer groups"
        , location = Schema.DocLocation.LocalFile "runtime-patterns/kiroku/subscriptions.md"
        }
      , Schema.DocRef::{
        , key = "kiroku-operational-invariants"
        , kind = Schema.DocKind.Runbook
        , audience = Schema.DocAudience.Module
        , description = Some
            "The ten invariants every kiroku-backed service must respect in production"
        , location =
            Schema.DocLocation.LocalFile "runtime-patterns/kiroku/operational-invariants.md"
        }
      , Schema.DocRef::{
        , key = "kiroku-observability"
        , kind = Schema.DocKind.Guide
        , audience = Schema.DocAudience.Module
        , description = Some
            "Wiring kiroku-metrics and kiroku-otel: collector composition, spans, Prometheus names, health probes"
        , location = Schema.DocLocation.LocalFile "runtime-patterns/kiroku/observability.md"
        }
      , Schema.DocRef::{
        , key = "kiroku-lifecycle-and-deletion"
        , kind = Schema.DocKind.Guide
        , audience = Schema.DocAudience.Module
        , description = Some
            "Soft and hard deletion, the advisory hard-delete GUC, truncateBefore compaction, and provisional linkToStream"
        , location =
            Schema.DocLocation.LocalFile "runtime-patterns/kiroku/lifecycle-and-deletion.md"
        }
      , Schema.DocRef::{
        , key = "migrations-overview"
        , kind = Schema.DocKind.Guide
        , audience = Schema.DocAudience.Module
        , description = Some
            "Index of pg-migrate migration standards for keiro services; start here"
        , location = Schema.DocLocation.LocalFile "runtime-patterns/migrations/overview.md"
        }
      , Schema.DocRef::{
        , key = "migrations-pg-migrate-model"
        , kind = Schema.DocKind.Guide
        , audience = Schema.DocAudience.Module
        , description = Some
            "The pg-migrate model: components, manifests, exact-byte embedding, the ledger, and the RecompilePlugin"
        , location = Schema.DocLocation.LocalFile "runtime-patterns/migrations/pg-migrate-model.md"
        }
      , Schema.DocRef::{
        , key = "migrations-authoring"
        , kind = Schema.DocKind.BestPractice
        , audience = Schema.DocAudience.Module
        , description = Some
            "Authoring rules: append-only migrations, the no-transaction directive, and manifest v1 strictness"
        , location = Schema.DocLocation.LocalFile "runtime-patterns/migrations/authoring.md"
        }
      , Schema.DocRef::{
        , key = "migrations-service-package"
        , kind = Schema.DocKind.BestPractice
        , audience = Schema.DocAudience.Module
        , description = Some
            "The <service>-migrations package pattern composing kiroku, keiro, pgmq, and service components into one plan"
        , location = Schema.DocLocation.LocalFile "runtime-patterns/migrations/service-package.md"
        }
      , Schema.DocRef::{
        , key = "migrations-operations"
        , kind = Schema.DocKind.Runbook
        , audience = Schema.DocAudience.Module
        , description = Some
            "Operating verify, status, and repair; verify is ledger-versus-plan; Running after a crash needs audited repair"
        , location = Schema.DocLocation.LocalFile "runtime-patterns/migrations/operations.md"
        }
      , Schema.DocRef::{
        , key = "migrations-testing"
        , kind = Schema.DocKind.Guide
        , audience = Schema.DocAudience.Module
        , description = Some
            "Ephemeral-database tests with withMigratedDatabase, the nested-Either gotcha, and per-service wrappers"
        , location = Schema.DocLocation.LocalFile "runtime-patterns/migrations/testing.md"
        }
      , Schema.DocRef::{
        , key = "migrations-codd-transition"
        , kind = Schema.DocKind.Guide
        , audience = Schema.DocAudience.Module
        , description = Some
            "Why the fleet moved from codd to pg-migrate and how persistent databases were imported ledger-only"
        , location = Schema.DocLocation.LocalFile "runtime-patterns/migrations/codd-transition.md"
        }
      , Schema.DocRef::{
        , key = "keiro-overview"
        , kind = Schema.DocKind.Guide
        , audience = Schema.DocAudience.Module
        , description = Some
            "Index of prescriptive Keiro runtime and DSL standards; start here"
        , location = Schema.DocLocation.LocalFile "runtime-patterns/keiro/overview.md"
        }
      , Schema.DocRef::{
        , key = "keiro-runtime-assembly"
        , kind = Schema.DocKind.BestPractice
        , audience = Schema.DocAudience.Module
        , description = Some
            "Store acquisition, validated event streams, resource effects, options, and startup order"
        , location = Schema.DocLocation.LocalFile "runtime-patterns/keiro/runtime-assembly.md"
        }
      , Schema.DocRef::{
        , key = "keiro-two-schema-arrangement"
        , kind = Schema.DocKind.Guide
        , audience = Schema.DocAudience.Module
        , description = Some
            "Separation of Kiroku store, Keiro framework, and application-owned PostgreSQL schemas"
        , location =
            Schema.DocLocation.LocalFile "runtime-patterns/keiro/two-schema-arrangement.md"
        }
      , Schema.DocRef::{
        , key = "keiro-command-cycle-and-errors"
        , kind = Schema.DocKind.BestPractice
        , audience = Schema.DocAudience.Module
        , description = Some
            "Command hydration, decision, append, projection, and prescriptive error handling"
        , location =
            Schema.DocLocation.LocalFile "runtime-patterns/keiro/command-cycle-and-errors.md"
        }
      , Schema.DocRef::{
        , key = "keiro-read-models-and-projections"
        , kind = Schema.DocKind.BestPractice
        , audience = Schema.DocAudience.Module
        , description = Some
            "Read-model registration, consistency, async fencing, rebuilds, and snapshot limits"
        , location =
            Schema.DocLocation.LocalFile "runtime-patterns/keiro/read-models-and-projections.md"
        }
      , Schema.DocRef::{
        , key = "keiro-durable-workflows"
        , kind = Schema.DocKind.Guide
        , audience = Schema.DocAudience.Module
        , description = Some
            "Durable workflow journals, capability-based workers, stable steps, and evolution"
        , location = Schema.DocLocation.LocalFile "runtime-patterns/keiro/durable-workflows.md"
        }
      , Schema.DocRef::{
        , key = "keiro-workflow-reliability"
        , kind = Schema.DocKind.BestPractice
        , audience = Schema.DocAudience.Module
        , description = Some
            "Lease sizing, the failure budget, terminal-failure resurrection, and the durable wake-source lifecycle"
        , location =
            Schema.DocLocation.LocalFile
              "runtime-patterns/keiro/workflow-reliability.md"
        }
      , Schema.DocRef::{
        , key = "keiro-telemetry"
        , kind = Schema.DocKind.BestPractice
        , audience = Schema.DocAudience.Module
        , description = Some
            "Keiro tracing, metrics, W3C propagation, Kiroku bridging, and logging seams"
        , location = Schema.DocLocation.LocalFile "runtime-patterns/keiro/telemetry.md"
        }
      , Schema.DocRef::{
        , key = "keiro-dsl-adoption"
        , kind = Schema.DocKind.Guide
        , audience = Schema.DocAudience.Module
        , description = Some
            "When to adopt keiro-dsl, its generated-code firewall, holes, CLI, and evolution gate"
        , location = Schema.DocLocation.LocalFile "runtime-patterns/keiro/dsl-adoption.md"
        }
      , Schema.DocRef::{
        , key = "keiro-language-versions"
        , kind = Schema.DocKind.BestPractice
        , audience = Schema.DocAudience.Module
        , description = Some
            "Declaring the language keiro-dsl preamble, choosing among versions 1 through 3, and carrying the checked contract through tooling"
        , location = Schema.DocLocation.LocalFile
            "runtime-patterns/keiro/language-versions.md"
        }
      , Schema.DocRef::{
        , key = "keiro-aggregate-expressions"
        , kind = Schema.DocKind.BestPractice
        , audience = Schema.DocAudience.Module
        , description = Some
            "Version-2 guards and writes that generate the Keiki transducer, implementation holes, and FoldVersion discipline"
        , location = Schema.DocLocation.LocalFile
            "runtime-patterns/keiro/aggregate-expressions.md"
        }
      , Schema.DocRef::{
        , key = "keiro-nominal-bindings"
        , kind = Schema.DocKind.BestPractice
        , audience = Schema.DocAudience.Module
        , description = Some
            "Binding consumer-owned IDs, enums, and scalar wrappers with total isomorphisms, fixtures, and a decoder-tightening audit"
        , location = Schema.DocLocation.LocalFile
            "runtime-patterns/keiro/nominal-bindings.md"
        }
      , Schema.DocRef::{
        , key = "keiro-identifier-domains"
        , kind = Schema.DocKind.BestPractice
        , audience = Schema.DocAudience.Module
        , description = Some
            "The frozen TypeID-v7 admission contract for version-3 prefix-bearing IDs and its producer-last rollout"
        , location = Schema.DocLocation.LocalFile
            "runtime-patterns/keiro/identifier-domains.md"
        }
      , Schema.DocRef::{
        , key = "keiro-behavior-conformance"
        , kind = Schema.DocKind.BestPractice
        , audience = Schema.DocAudience.Module
        , description = Some
            "Inventorying every aggregate behavior obligation and proving each one with an executed typed witness"
        , location = Schema.DocLocation.LocalFile
            "runtime-patterns/keiro/behavior-conformance.md"
        }
      , Schema.DocRef::{
        , key = "keiro-service-workspaces"
        , kind = Schema.DocKind.BestPractice
        , audience = Schema.DocAudience.Module
        , description = Some
            "Composing single-owner .keiro members into one service with whole-service checking, atomic scaffolding, and attributable history"
        , location =
            Schema.DocLocation.LocalFile
              "runtime-patterns/keiro/service-workspaces.md"
        }
      , Schema.DocRef::{
        , key = "keiro-brownfield-adoption"
        , kind = Schema.DocKind.Guide
        , audience = Schema.DocAudience.Module
        , description = Some
            "Adopting Keiro around existing domain types and stored JSON with codec evidence and a replay-safe cutover"
        , location =
            Schema.DocLocation.LocalFile
              "runtime-patterns/keiro/brownfield-adoption.md"
        }
      , Schema.DocRef::{
        , key = "keiro-evolution-and-rollout"
        , kind = Schema.DocKind.BestPractice
        , audience = Schema.DocAudience.Module
        , description = Some
            "The six-layer evolution gate ladder, compatibility surfaces, targeted replay audits, and durable-value rollout ordering"
        , location =
            Schema.DocLocation.LocalFile
              "runtime-patterns/keiro/evolution-and-rollout.md"
        }
      , Schema.DocRef::{
        , key = "keiro-gotchas"
        , kind = Schema.DocKind.Notes
        , audience = Schema.DocAudience.Module
        , description = Some
            "Shared-stream, global-lock, resource-effect, and bring-your-own Kafka traps"
        , location = Schema.DocLocation.LocalFile "runtime-patterns/keiro/gotchas.md"
        }
      , Schema.DocRef::{
        , key = "messaging-overview"
        , kind = Schema.DocKind.Guide
        , audience = Schema.DocAudience.Module
        , description = Some
            "Index of messaging standards for keiro services: process managers, integration events, transports; start here"
        , location = Schema.DocLocation.LocalFile "runtime-patterns/messaging/overview.md"
        }
      , Schema.DocRef::{
        , key = "messaging-glossary"
        , kind = Schema.DocKind.Reference
        , audience = Schema.DocAudience.Module
        , description = Some
            "Shared messaging vocabulary: domain vs integration events, outbox, inbox, ack decisions, at-least-once plus idempotency"
        , location = Schema.DocLocation.LocalFile "runtime-patterns/messaging/glossary.md"
        }
      , Schema.DocRef::{
        , key = "messaging-process-managers"
        , kind = Schema.DocKind.BestPractice
        , audience = Schema.DocAudience.Module
        , description = Some
            "The process manager standard: saga streams, deterministic ids, worker policies, durable timers, and the orchestration decision ladder"
        , location = Schema.DocLocation.LocalFile "runtime-patterns/messaging/process-managers.md"
        }
      , Schema.DocRef::{
        , key = "messaging-integration-events"
        , kind = Schema.DocKind.BestPractice
        , audience = Schema.DocAudience.Module
        , description = Some
            "The integration event contract: envelope, identity and dedupe rules, topic versioning, trace continuation"
        , location = Schema.DocLocation.LocalFile "runtime-patterns/messaging/integration-events.md"
        }
      , Schema.DocRef::{
        , key = "messaging-outbox"
        , kind = Schema.DocKind.BestPractice
        , audience = Schema.DocAudience.Module
        , description = Some
            "Publishing through the transactional outbox: IntegrationProducer, publisher worker, maintenance pass, deterministic ids"
        , location = Schema.DocLocation.LocalFile "runtime-patterns/messaging/outbox.md"
        }
      , Schema.DocRef::{
        , key = "messaging-inbox"
        , kind = Schema.DocKind.BestPractice
        , audience = Schema.DocAudience.Module
        , description = Some
            "Consuming integration events idempotently: runInboxTransaction variants and disposition completeness"
        , location = Schema.DocLocation.LocalFile "runtime-patterns/messaging/inbox.md"
        }
      , Schema.DocRef::{
        , key = "messaging-shibuya-processing"
        , kind = Schema.DocKind.Guide
        , audience = Schema.DocAudience.Module
        , description = Some
            "Shibuya processing semantics every worker inherits: ack decisions, retries, batching, supervision, shutdown"
        , location = Schema.DocLocation.LocalFile "runtime-patterns/messaging/shibuya-processing.md"
        }
      , Schema.DocRef::{
        , key = "messaging-transport-selection"
        , kind = Schema.DocKind.Pattern
        , audience = Schema.DocAudience.Module
        , description = Some
            "Choosing a transport: the pgmq vs Kafka vs kiroku-subscription matrix and rule of thumb"
        , location = Schema.DocLocation.LocalFile "runtime-patterns/messaging/transport-selection.md"
        }
      , Schema.DocRef::{
        , key = "messaging-pgmq-jobs"
        , kind = Schema.DocKind.BestPractice
        , audience = Schema.DocAudience.Module
        , description = Some
            "Typed background jobs on keiro-pgmq: Job, JobOutcome, RetryPolicy, VT rules, queue-name pitfalls"
        , location = Schema.DocLocation.LocalFile "runtime-patterns/messaging/pgmq-jobs.md"
        }
      , Schema.DocRef::{
        , key = "messaging-kiroku-subscriptions"
        , kind = Schema.DocKind.BestPractice
        , audience = Schema.DocAudience.Module
        , description = Some
            "Consuming the event log through the shibuya-kiroku bridge: ack-coupled checkpoints, guardKirokuHandler, consumer groups"
        , location = Schema.DocLocation.LocalFile "runtime-patterns/messaging/kiroku-subscriptions.md"
        }
      , Schema.DocRef::{
        , key = "messaging-gotchas"
        , kind = Schema.DocKind.Notes
        , audience = Schema.DocAudience.Module
        , description = Some
            "Consolidated messaging gotcha catalogue across shibuya, pgmq, Kafka, kiroku, and keiro"
        , location = Schema.DocLocation.LocalFile "runtime-patterns/messaging/gotchas.md"
        }
      , Schema.DocRef::{
        , key = "architecture-overview"
        , kind = Schema.DocKind.Guide
        , audience = Schema.DocAudience.Module
        , description = Some
            "Index of the keiro service architecture standard: packages, vertical slices, tests, scaffolding; start here"
        , location = Schema.DocLocation.LocalFile "runtime-patterns/architecture/overview.md"
        }
      , Schema.DocRef::{
        , key = "architecture-service-packages"
        , kind = Schema.DocKind.BestPractice
        , audience = Schema.DocAudience.Module
        , description = Some
            "The six-package split standard for deployed keiro services and its dependency rules"
        , location =
            Schema.DocLocation.LocalFile "runtime-patterns/architecture/service-packages.md"
        }
      , Schema.DocRef::{
        , key = "architecture-vertical-slice-modules"
        , kind = Schema.DocKind.BestPractice
        , audience = Schema.DocAudience.Module
        , description = Some
            "The authoritative Generated.* + Holes vertical-slice module convention per domain concept"
        , location =
            Schema.DocLocation.LocalFile
              "runtime-patterns/architecture/vertical-slice-modules.md"
        }
      , Schema.DocRef::{
        , key = "architecture-cross-cutting-modules"
        , kind = Schema.DocKind.BestPractice
        , audience = Schema.DocAudience.Module
        , description = Some
            "The closed allowlist of technical-layer modules and the domain-vs-technology division heuristic"
        , location =
            Schema.DocLocation.LocalFile
              "runtime-patterns/architecture/cross-cutting-modules.md"
        }
      , Schema.DocRef::{
        , key = "architecture-extended-node-verticals"
        , kind = Schema.DocKind.Pattern
        , audience = Schema.DocAudience.Module
        , description = Some
            "Where read models, process managers, workflows, routers, publishers, inboxes, queues, and contracts sit in the slice"
        , location =
            Schema.DocLocation.LocalFile
              "runtime-patterns/architecture/extended-node-verticals.md"
        }
      , Schema.DocRef::{
        , key = "architecture-spec-and-scaffolding"
        , kind = Schema.DocKind.BestPractice
        , audience = Schema.DocAudience.Module
        , description = Some
            "Placing the .keiro spec at domain/<service>.keiro and running keiro-dsl scaffold idempotently"
        , location =
            Schema.DocLocation.LocalFile
              "runtime-patterns/architecture/spec-and-scaffolding.md"
        }
      , Schema.DocRef::{
        , key = "architecture-test-layout"
        , kind = Schema.DocKind.BestPractice
        , audience = Schema.DocAudience.Module
        , description = Some
            "The per-package test-suite standard: four core suites, vertical Spec modules, migrations test-support"
        , location =
            Schema.DocLocation.LocalFile "runtime-patterns/architecture/test-layout.md"
        }
      , Schema.DocRef::{
        , key = "architecture-worked-example-conversation"
        , kind = Schema.DocKind.Pattern
        , audience = Schema.DocAudience.Module
        , description = Some
            "Complete file listing of danwa's Conversation slice across all six packages"
        , location =
            Schema.DocLocation.LocalFile
              "runtime-patterns/architecture/worked-example-conversation.md"
        }
      , Schema.DocRef::{
        , key = "config-overview"
        , kind = Schema.DocKind.Guide
        , audience = Schema.DocAudience.Module
        , description = Some
            "Index of settei configuration and Kubernetes operational standards; start here"
        , location = Schema.DocLocation.LocalFile "runtime-patterns/config/overview.md"
        }
      , Schema.DocRef::{
        , key = "config-settei-service-standard"
        , kind = Schema.DocKind.BestPractice
        , audience = Schema.DocAudience.Module
        , description = Some
            "Fleet standard for microservice configuration with settei: algebra, secrets, source order, check-config"
        , location =
            Schema.DocLocation.LocalFile "runtime-patterns/config/settei-service-standard.md"
        }
      , Schema.DocRef::{
        , key = "config-settei-cli-standard"
        , kind = Schema.DocKind.BestPractice
        , audience = Schema.DocAudience.Module
        , description = Some
            "Fleet standard for CLI configuration with settei: four-layer precedence, formats, diagnostics"
        , location =
            Schema.DocLocation.LocalFile "runtime-patterns/config/settei-cli-standard.md"
        }
      , Schema.DocRef::{
        , key = "config-kubernetes-deployment"
        , kind = Schema.DocKind.Runbook
        , audience = Schema.DocAudience.Module
        , description = Some
            "Kubernetes operational standard: overlays, mounted sources, check-config gate, no-reload rollouts, graceful shutdown"
        , location =
            Schema.DocLocation.LocalFile "runtime-patterns/config/kubernetes-deployment.md"
        }
      , Schema.DocRef::{
        , key = "config-settei-gotchas"
        , kind = Schema.DocKind.Notes
        , audience = Schema.DocAudience.Module
        , description = Some
            "Settei footgun catalogue: null presence, positional precedence, pinning, redaction edges"
        , location =
            Schema.DocLocation.LocalFile "runtime-patterns/config/settei-gotchas.md"
        }
      , Schema.DocRef::{
        , key = "runtime-patterns-getting-started"
        , kind = Schema.DocKind.Guide
        , audience = Schema.DocAudience.Module
        , description = Some
            "Task-oriented routes into the prescriptive Keiro runtime standards"
        , location =
            Schema.DocLocation.LocalFile "runtime-patterns/getting-started.md"
        }
      ]
    }
