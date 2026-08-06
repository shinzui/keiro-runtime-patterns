---
type: Guide
title: "Keiki Diagram Documentation"
description: "Generating Mermaid diagrams, atlas sections, and edge inspectors from transducers"
timestamp: 2026-08-03T02:56:33Z
generated:
  by: human:nadeem
  at: "2026-08-03T02:56:33Z"
resource: mori://shinzui/keiro-runtime-patterns/docs/keiki-diagram-docs
tags: [keiki, diagram-docs]
status: current
reviews:
  - kind: model
    reviewer: claude-code
    reviewed_at: 2026-07-30T00:43:08Z
    document_timestamp: 2026-07-22T16:35:21Z
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

## Take The Readable Default

From Keiki 0.8 readable output is the default, not an opt-in. `toMermaid` and every no-options shape renderer use `defaultMermaidOptions`: pretty guards, complete register assignments, multiline labels, and no truncation. Render with the plain entry point unless a diagram has a specific reason to say less.

```haskell
toMermaid reservationTransducer
```

This renders domain labels and register comparisons instead of structural tags such as `PAnd`, `PEq`, and `PCmp`. Use `toMermaidWithLabels` when Haskell state constructors are not suitable visible labels; keep the Mermaid state IDs stable and ASCII.

Reach for `toMermaidWith` only to narrow the default — for example to bound label width on a dense machine:

```haskell
boundedMermaidOptions =
  defaultMermaidOptions
    { maxInlineWrittenSlots = Just 6
    , maxInlineGuardWidth = Just 120
    , outputLayout = MermaidOutputMultiline
    }
```

`MermaidOptions` no longer has `showWrittenSlots` or `showGuardSummary`. Their replacements are the two mode fields: `updateMode = MermaidUpdateWrittenSlots` for slot names without right-hand terms, and `guardMode = MermaidGuardStructuralSummary` for a structural guard summary. `MermaidUpdateHidden` and `MermaidGuardHidden` drop each segment entirely.

## Make Topology-Only Output Explicit

When a diagram is deliberately about shape rather than business semantics, ask for that by name:

```haskell
toTopologyMermaid reservationTransducer
```

`toTopologyMermaid` applies `topologyMermaidOptions` — hidden guards, hidden updates, inline labels — and reproduces Keiki 0.7's compact bytes exactly. Upgrading to 0.8 changes checked-in diagrams that relied on the old implicit compact default; regenerate them, and switch to `toTopologyMermaid` for the ones whose committed bytes should not move. Options-aware entry points cover the composite, nested, three-way, alternative, feedback, and labeled renderers too, so a whole atlas can hold one policy.

## Include Orchestrator Transducers

Do not limit an atlas to aggregates. In keiki, an orchestrator—a process manager, saga, or policy—is another transducer that maps events to commands, so its state machine belongs beside the command-to-event aggregate machines it coordinates.

Build `MermaidSection` values with `AggregateDiagram` and `ProcessManagerDiagram`, then render them through `toMermaidAtlasWith`. `ProcessManagerDiagram` is only a cosmetic `MermaidSectionKind` label for an atlas section; it is not a process-manager abstraction in keiki. The hosted, durable `ProcessManager` record with correlation, target dispatch, and timers belongs to keiro's `Keiro.ProcessManager`. The planned messaging standard is tracked by [EP-5](https://github.com/shinzui/keiro-runtime-patterns/blob/master/docs/plans/5-document-process-managers-integration-events-and-messaging-standards.md).

For an existing document with stable hand-authored prose, use `replaceMarkdownDiagramBlock`. A service CLI can then replace only its marked Mermaid blocks and leave surrounding text untouched.

## Generate Edge Inspectors

Generate edge-inspector Markdown for audits and for detail too dense to sit in a diagram label:

```haskell
renderEdgeInspector
  defaultEdgeInspectorOptions
    { includePrettyGuard = True
    , includeOutputFields = True
    }
  reservationTransducer
```

The inspector groups edges by source state and lists edge index, target, command, outputs, structural and pretty guards, written slots, and output terms. Put dense transition detail here instead of making Mermaid labels unreadable.

## Read `<lit>` As A Deliberate Redaction

Pretty rendering shows an ordinary `lit` value through its `Show` instance. `<lit>` appears only where the model used `opaqueLit`, which is the authoring signal that a value is a secret, a redaction, or a type with no `Show`. A `<lit>` in a generated diagram is therefore never a renderer limitation to work around — see [Keiki Transducer Best Practices](./transducer-best-practices.md).

## Validate Generated Diagrams

Use `validateMermaidAtlas` or `validateMermaidDiagram` in service tests. The readable default produces long multiline labels, so tune the conservative validation defaults to accept them:

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
