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
      ]
    }
