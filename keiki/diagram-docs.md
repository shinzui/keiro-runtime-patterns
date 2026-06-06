# Keiki Diagram Documentation

Use generated Keiki diagrams as checked-in documentation for aggregate and process-manager
state streams. The runtime example renders both topology diagrams and edge-inspector notes
from the same transducer values, so diagrams stay coupled to executable rules.

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

This renders domain labels such as `RequestTransferReservation` and register comparisons
instead of structural tags like `PAnd`, `PEq`, and `PCmp`. Use `toMermaidWithLabels` when the
Haskell state constructor names are not suitable visible labels; keep the Mermaid state IDs
stable and ASCII.

## Include Process Managers

Do not limit the atlas to aggregates. A Keiki-backed process manager is still a durable
state stream and should appear beside aggregate diagrams. In the runtime example, Incident
Escalation and Hospital Surge are rendered into `docs/diagrams/keiki.md` along with Incident,
Field Resource, Triage, Hospital, Capacity, Reservation, and Supply.

For new documents, consider building `MermaidSection` values with `AggregateDiagram` and
`ProcessManagerDiagram` kinds and rendering them through `toMermaidAtlasWith`. For an
existing document with stable hand-authored prose, `replaceMarkdownDiagramBlock` is a good
low-risk choice: each service CLI replaces only its own marked Mermaid blocks and leaves
surrounding text untouched.

## Generate Edge Inspectors

Topology diagrams should stay compact. Generate edge-inspector Markdown for audits and
walkthroughs:

```haskell
renderEdgeInspector
  defaultEdgeInspectorOptions
    { includePrettyGuard = True
    , includeOutputFields = True
    }
  reservationTransducer
```

The inspector groups edges by source state and lists edge index, target, command, outputs,
structural guard, pretty guard, written slots, and output terms. This is the right place for
dense details that would make Mermaid labels unreadable.

## Validate Generated Diagrams

Use `validateMermaidAtlas` or `validateMermaidDiagram` in service tests. The default
validation options are intentionally conservative; when using `MermaidGuardPretty`, tune the
options to match Keiki's readable syntax:

```haskell
readableMermaidValidationOptions =
  defaultMermaidValidationOptions
    { maxLabelLength = Nothing
    , suspiciousChars = ['"', '{', '}']
    }
```

That keeps basic structure and malformed-label checks while allowing long multiline labels,
`<lit>` placeholders, and boolean operators such as `||`.

## Regeneration Pattern

Expose a service-owned CLI command such as `incident-command-cli diagrams keiki` or
`hospital-capacity-cli diagrams keiki`. The command should update checked-in Markdown
idempotently and print the file it wrote. Run it during documentation refreshes and before
committing changes to transducer logic.
