let Schema =
      https://raw.githubusercontent.com/shinzui/mori-schema/026ae74331e5c516542af1dd96f041c658ed4621/package.dhall
        sha256:18258ef583580a897f4af3e7c86db0342afb42fb40efc535b217ba1089230141

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
      , "shinzui/shibuya"
      , "shinzui/pg-migrate"
      , "shinzui/pgmq-hs"
      ]
    , docs =
      [ Schema.DocRef::{
        , key = "keiki-overview"
        , kind = Schema.DocKind.Guide
        , audience = Schema.DocAudience.Module
        , description = Some
            "Index of Keiki transducer patterns for Keiro services; start here"
        , location = Schema.DocLocation.LocalFile "keiki/README.md"
        }
      , Schema.DocRef::{
        , key = "keiki-transducer-best-practices"
        , kind = Schema.DocKind.BestPractice
        , audience = Schema.DocAudience.Module
        , description = Some
            "Core rules for authoring Keiki transducers with the builder DSL"
        , location =
            Schema.DocLocation.LocalFile "keiki/transducer-best-practices.md"
        }
      , Schema.DocRef::{
        , key = "keiki-build-time-validation"
        , kind = Schema.DocKind.Guide
        , audience = Schema.DocAudience.Module
        , description = Some
            "Asserting transducers are well-formed in CI with validateTransducer"
        , location =
            Schema.DocLocation.LocalFile "keiki/build-time-validation.md"
        }
      , Schema.DocRef::{
        , key = "keiki-diagnosing-rejected-commands"
        , kind = Schema.DocKind.Guide
        , audience = Schema.DocAudience.Module
        , description = Some
            "Using stepEither and StepFailure to learn why a command was rejected"
        , location =
            Schema.DocLocation.LocalFile "keiki/diagnosing-rejected-commands.md"
        }
      , Schema.DocRef::{
        , key = "keiki-collections-and-opaque-guards"
        , kind = Schema.DocKind.Pattern
        , audience = Schema.DocAudience.Module
        , description = Some
            "Modeling collections without losing solver verification through opaque guards"
        , location =
            Schema.DocLocation.LocalFile
              "keiki/collections-and-opaque-guards.md"
        }
      , Schema.DocRef::{
        , key = "keiki-operator-conflicts"
        , kind = Schema.DocKind.Guide
        , audience = Schema.DocAudience.Module
        , description = Some
            "Resolving the lens / generic-lens (.>) operator clash three ways"
        , location = Schema.DocLocation.LocalFile "keiki/operator-conflicts.md"
        }
      , Schema.DocRef::{
        , key = "keiki-json-event-codecs"
        , kind = Schema.DocKind.Guide
        , audience = Schema.DocAudience.Module
        , description = Some
            "Deriving kind-discriminated JSON codecs with keiki-codec-json"
        , location = Schema.DocLocation.LocalFile "keiki/json-event-codecs.md"
        }
      , Schema.DocRef::{
        , key = "keiki-diagram-docs"
        , kind = Schema.DocKind.Guide
        , audience = Schema.DocAudience.Module
        , description = Some
            "Generating Mermaid diagrams, atlas sections, and edge inspectors from transducers"
        , location = Schema.DocLocation.LocalFile "keiki/diagram-docs.md"
        }
      , Schema.DocRef::{
        , key = "keiki-structured-replay-and-hydration"
        , kind = Schema.DocKind.Guide
        , audience = Schema.DocAudience.Module
        , description = Some
            "Diagnosing hydration failures with reconstituteEither, replayEvents, and ReplayFailure"
        , location =
            Schema.DocLocation.LocalFile
              "keiki/structured-replay-and-hydration.md"
        }
      , Schema.DocRef::{
        , key = "keiki-event-schema-evolution"
        , kind = Schema.DocKind.Guide
        , audience = Schema.DocAudience.Module
        , description = Some
            "Evolving persisted event JSON with in-band versions, pinned kinds, and upcaster chains"
        , location =
            Schema.DocLocation.LocalFile "keiki/event-schema-evolution.md"
        }
      , Schema.DocRef::{
        , key = "keiki-checked-composition"
        , kind = Schema.DocKind.Pattern
        , audience = Schema.DocAudience.Module
        , description = Some
            "Wiring transducers with composeChecked, alternative, and the feedback1 stateless-only trap"
        , location = Schema.DocLocation.LocalFile "keiki/checked-composition.md"
        }
      , Schema.DocRef::{
        , key = "keiki-upgrading-to-keiki-0-2"
        , kind = Schema.DocKind.Guide
        , audience = Schema.DocAudience.Module
        , description = Some
            "Migration notes for keiki 0.2: noEmit, new validation warnings, snapshot-hash change, Decider removal"
        , location =
            Schema.DocLocation.LocalFile "keiki/upgrading-to-keiki-0-2.md"
        }
      , Schema.DocRef::{
        , key = "kiroku-overview"
        , kind = Schema.DocKind.Guide
        , audience = Schema.DocAudience.Module
        , description = Some
            "Index of kiroku event-store standards for keiro services; start here"
        , location = Schema.DocLocation.LocalFile "kiroku/README.md"
        }
      , Schema.DocRef::{
        , key = "kiroku-append-and-read"
        , kind = Schema.DocKind.BestPractice
        , audience = Schema.DocAudience.Module
        , description = Some
            "ExpectedVersion semantics, idempotent retries via supplied event ids, and streaming reads"
        , location = Schema.DocLocation.LocalFile "kiroku/append-and-read.md"
        }
      , Schema.DocRef::{
        , key = "kiroku-transactions-and-projections"
        , kind = Schema.DocKind.BestPractice
        , audience = Schema.DocAudience.Module
        , description = Some
            "Atomic append plus projection with runTransactionAppendingResource, and why the other combinators are traps"
        , location =
            Schema.DocLocation.LocalFile "kiroku/transactions-and-projections.md"
        }
      , Schema.DocRef::{
        , key = "kiroku-connection-settings"
        , kind = Schema.DocKind.BestPractice
        , audience = Schema.DocAudience.Module
        , description = Some
            "Store schema and NOTIFY channel, extraSearchPath seam, timeouts, and synchronous handler discipline"
        , location = Schema.DocLocation.LocalFile "kiroku/connection-settings.md"
        }
      , Schema.DocRef::{
        , key = "kiroku-subscriptions"
        , kind = Schema.DocKind.BestPractice
        , audience = Schema.DocAudience.Module
        , description = Some
            "At-least-once subscriptions, per-batch checkpoints, overflow policies, and Serial consumer groups"
        , location = Schema.DocLocation.LocalFile "kiroku/subscriptions.md"
        }
      , Schema.DocRef::{
        , key = "kiroku-operational-invariants"
        , kind = Schema.DocKind.Runbook
        , audience = Schema.DocAudience.Module
        , description = Some
            "The ten invariants every kiroku-backed service must respect in production"
        , location =
            Schema.DocLocation.LocalFile "kiroku/operational-invariants.md"
        }
      , Schema.DocRef::{
        , key = "kiroku-observability"
        , kind = Schema.DocKind.Guide
        , audience = Schema.DocAudience.Module
        , description = Some
            "Wiring kiroku-metrics and kiroku-otel: collector composition, spans, Prometheus names, health probes"
        , location = Schema.DocLocation.LocalFile "kiroku/observability.md"
        }
      , Schema.DocRef::{
        , key = "kiroku-lifecycle-and-deletion"
        , kind = Schema.DocKind.Guide
        , audience = Schema.DocAudience.Module
        , description = Some
            "Soft and hard deletion, the advisory hard-delete GUC, truncateBefore compaction, and provisional linkToStream"
        , location =
            Schema.DocLocation.LocalFile "kiroku/lifecycle-and-deletion.md"
        }
      , Schema.DocRef::{
        , key = "migrations-overview"
        , kind = Schema.DocKind.Guide
        , audience = Schema.DocAudience.Module
        , description = Some
            "Index of pg-migrate migration standards for keiro services; start here"
        , location = Schema.DocLocation.LocalFile "migrations/README.md"
        }
      , Schema.DocRef::{
        , key = "migrations-pg-migrate-model"
        , kind = Schema.DocKind.Guide
        , audience = Schema.DocAudience.Module
        , description = Some
            "The pg-migrate model: components, manifests, exact-byte embedding, the ledger, and the RecompilePlugin"
        , location = Schema.DocLocation.LocalFile "migrations/pg-migrate-model.md"
        }
      , Schema.DocRef::{
        , key = "migrations-authoring"
        , kind = Schema.DocKind.BestPractice
        , audience = Schema.DocAudience.Module
        , description = Some
            "Authoring rules: append-only migrations, the no-transaction directive, and manifest v1 strictness"
        , location = Schema.DocLocation.LocalFile "migrations/authoring.md"
        }
      , Schema.DocRef::{
        , key = "migrations-service-package"
        , kind = Schema.DocKind.BestPractice
        , audience = Schema.DocAudience.Module
        , description = Some
            "The <service>-migrations package pattern composing kiroku, keiro, pgmq, and service components into one plan"
        , location = Schema.DocLocation.LocalFile "migrations/service-package.md"
        }
      , Schema.DocRef::{
        , key = "migrations-operations"
        , kind = Schema.DocKind.Runbook
        , audience = Schema.DocAudience.Module
        , description = Some
            "Operating verify, status, and repair; verify is ledger-versus-plan; Running after a crash needs audited repair"
        , location = Schema.DocLocation.LocalFile "migrations/operations.md"
        }
      , Schema.DocRef::{
        , key = "migrations-testing"
        , kind = Schema.DocKind.Guide
        , audience = Schema.DocAudience.Module
        , description = Some
            "Ephemeral-database tests with withMigratedDatabase, the nested-Either gotcha, and per-service wrappers"
        , location = Schema.DocLocation.LocalFile "migrations/testing.md"
        }
      , Schema.DocRef::{
        , key = "migrations-codd-transition"
        , kind = Schema.DocKind.Guide
        , audience = Schema.DocAudience.Module
        , description = Some
            "Why the fleet moved from codd to pg-migrate and how persistent databases were imported ledger-only"
        , location = Schema.DocLocation.LocalFile "migrations/codd-transition.md"
        }
      , Schema.DocRef::{
        , key = "keiro-overview"
        , kind = Schema.DocKind.Guide
        , audience = Schema.DocAudience.Module
        , description = Some
            "Index of prescriptive Keiro runtime and DSL standards; start here"
        , location = Schema.DocLocation.LocalFile "keiro/README.md"
        }
      , Schema.DocRef::{
        , key = "keiro-runtime-assembly"
        , kind = Schema.DocKind.BestPractice
        , audience = Schema.DocAudience.Module
        , description = Some
            "Store acquisition, validated event streams, resource effects, options, and startup order"
        , location = Schema.DocLocation.LocalFile "keiro/runtime-assembly.md"
        }
      , Schema.DocRef::{
        , key = "keiro-two-schema-arrangement"
        , kind = Schema.DocKind.Guide
        , audience = Schema.DocAudience.Module
        , description = Some
            "Separation of Kiroku store, Keiro framework, and application-owned PostgreSQL schemas"
        , location =
            Schema.DocLocation.LocalFile "keiro/two-schema-arrangement.md"
        }
      , Schema.DocRef::{
        , key = "keiro-command-cycle-and-errors"
        , kind = Schema.DocKind.BestPractice
        , audience = Schema.DocAudience.Module
        , description = Some
            "Command hydration, decision, append, projection, and prescriptive error handling"
        , location =
            Schema.DocLocation.LocalFile "keiro/command-cycle-and-errors.md"
        }
      , Schema.DocRef::{
        , key = "keiro-read-models-and-projections"
        , kind = Schema.DocKind.BestPractice
        , audience = Schema.DocAudience.Module
        , description = Some
            "Read-model registration, consistency, async fencing, rebuilds, and snapshot limits"
        , location =
            Schema.DocLocation.LocalFile "keiro/read-models-and-projections.md"
        }
      , Schema.DocRef::{
        , key = "keiro-durable-workflows"
        , kind = Schema.DocKind.Guide
        , audience = Schema.DocAudience.Module
        , description = Some
            "Durable workflow journals, capability-based workers, stable steps, and evolution"
        , location = Schema.DocLocation.LocalFile "keiro/durable-workflows.md"
        }
      , Schema.DocRef::{
        , key = "keiro-telemetry"
        , kind = Schema.DocKind.BestPractice
        , audience = Schema.DocAudience.Module
        , description = Some
            "Keiro tracing, metrics, W3C propagation, Kiroku bridging, and logging seams"
        , location = Schema.DocLocation.LocalFile "keiro/telemetry.md"
        }
      , Schema.DocRef::{
        , key = "keiro-dsl-adoption"
        , kind = Schema.DocKind.Guide
        , audience = Schema.DocAudience.Module
        , description = Some
            "When to adopt keiro-dsl, its generated-code firewall, holes, CLI, and evolution gate"
        , location = Schema.DocLocation.LocalFile "keiro/dsl-adoption.md"
        }
      , Schema.DocRef::{
        , key = "keiro-gotchas"
        , kind = Schema.DocKind.BestPractice
        , audience = Schema.DocAudience.Module
        , description = Some
            "Shared-stream, global-lock, resource-effect, and bring-your-own Kafka traps"
        , location = Schema.DocLocation.LocalFile "keiro/gotchas.md"
        }
      ]
    }
