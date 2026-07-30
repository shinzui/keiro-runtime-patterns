---
type: Guide
title: "Keiki Diagram Documentation"
description: "Generating Mermaid diagrams, atlas sections, and edge inspectors from transducers"
timestamp: 2026-07-22T09:35:21-07:00
resource: mori://shinzui/keiro-runtime-patterns/docs/keiki-diagram-docs
tags: [keiki, diagram-docs]
status: current
reviews:
  - kind: model
    reviewer: claude-code
    reviewed_at: 2026-07-30T00:43:08Z
    document_timestamp: 2026-07-22T09:35:21-07:00
    scope: technical-accuracy
    outcome: approved
    provider: anthropic
    model: claude-fable-5
    effort: unspecified
    context: >-
      Model technical-accuracy review against the mori-resolved keiki v0.4.0.0 checkout, its changelogs, and the keiro consumer source; verified exported symbols, signatures, version claims, and links.
---

# Keiki Diagram Documentation

**Generate diagrams from executable transducers so topology documentation cannot drift silently.**

Use Keiki's Mermaid and edge-inspector renderers for aggregates and orchestrator transducers. Check the generated Markdown into each service, regenerate it after state-machine changes, and validate the rendered structure in tests.

## Render Readable Mermaid

Prefer `toMermaidWith` with readable guards and multiline labels:

```haskell
annotatedMermaidOptions =
  defaultMermaidOptions
    { showWrittenSlots = True
    , guardMode = MermaidGuardPretty
    , labelLayout = MermaidLabelMultiline
    , maxInlineWrittenSlots = Just 6
    , maxInlineGuardWidth = Just 120
    , outputLayout = MermaidOutputMultiline
    }
```

This renders domain labels and register comparisons instead of structural tags such as `PAnd`, `PEq`, and `PCmp`. Use `toMermaidWithLabels` when Haskell state constructors are not suitable visible labels; keep the Mermaid state IDs stable and ASCII.

## Include Orchestrator Transducers

Do not limit an atlas to aggregates. In keiki, an orchestrator—a process manager, saga, or policy—is another transducer that maps events to commands, so its state machine belongs beside the command-to-event aggregate machines it coordinates.

Build `MermaidSection` values with `AggregateDiagram` and `ProcessManagerDiagram`, then render them through `toMermaidAtlasWith`. `ProcessManagerDiagram` is only a cosmetic `MermaidSectionKind` label for an atlas section; it is not a process-manager abstraction in keiki. The hosted, durable `ProcessManager` record with correlation, target dispatch, and timers belongs to keiro's `Keiro.ProcessManager`. The planned messaging standard is tracked by [EP-5](https://github.com/shinzui/keiro-runtime-patterns/blob/master/docs/plans/5-document-process-managers-integration-events-and-messaging-standards.md).

For an existing document with stable hand-authored prose, use `replaceMarkdownDiagramBlock`. A service CLI can then replace only its marked Mermaid blocks and leave surrounding text untouched.

## Generate Edge Inspectors

Keep topology diagrams compact and generate edge-inspector Markdown for audits:

```haskell
renderEdgeInspector
  defaultEdgeInspectorOptions
    { includePrettyGuard = True
    , includeOutputFields = True
    }
  reservationTransducer
```

The inspector groups edges by source state and lists edge index, target, command, outputs, structural and pretty guards, written slots, and output terms. Put dense transition detail here instead of making Mermaid labels unreadable.

## Validate Generated Diagrams

Use `validateMermaidAtlas` or `validateMermaidDiagram` in service tests. When rendering pretty guards, tune the conservative defaults to accept the readable syntax:

```haskell
readableMermaidValidationOptions =
  defaultMermaidValidationOptions
    { maxLabelLength = Nothing
    , suspiciousChars = ['"', '{', '}']
    }
```

This retains structural and malformed-label checks while allowing long multiline labels, `<lit>` placeholders, and Boolean operators such as `||`.

## Regenerate Idempotently

Expose a service-owned command such as `incident-command-cli diagrams keiki`. It should update checked-in Markdown idempotently and print the file it wrote. Run it during documentation refreshes and before committing changes to a transducer.

## Related Patterns

- [Keiki Transducer Best Practices](./transducer-best-practices.md) explains when diagrams provide useful regression evidence.
- [Checked Composition](./checked-composition.md) explains how aggregate and orchestrator machines are wired.
- [Build-Time Validation](./build-time-validation.md) covers the model checks that complement diagram validation.
