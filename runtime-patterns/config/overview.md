---
type: Overview
title: "Configuration and Kubernetes Standards"
description: "Index of settei configuration and Kubernetes operational standards; start here"
timestamp: 2026-07-22T19:43:58Z
generated:
  by: human:nadeem
  at: "2026-07-22T19:43:58Z"
resource: mori://shinzui/keiro-runtime-patterns/docs/config-overview
tags: [config, overview]
status: current
reviews:
  - kind: model
    reviewer: claude-code
    reviewed_at: 2026-07-30T00:43:08Z
    document_timestamp: 2026-07-22T19:43:58Z
    scope: technical-accuracy
    outcome: approved
    provider: anthropic
    model: claude-fable-5
    effort: unspecified
    context: >-
      Model technical-accuracy review against the mori-resolved settei 0.2.0.0 checkout, its examples and deploy manifests, and Hackage release state; verified exported symbols, signatures, version claims, and links.
---

# Configuration and Kubernetes Standards

**Start here for the fleet's settei configuration model and Kubernetes startup, rollout, and shutdown contract.**

Settei is the standard for new and materially refactored keiro services and CLIs. Adoption is in progress, so these documents define the target even where existing applications still use raw or layered Dhall wiring.

## Start Here

- **[Settei Service Configuration Standard](./settei-service-standard.md):** fleet standard for microservice configuration with settei—algebra, secrets, source order, and `--check-config`.
- **[Settei CLI Configuration Standard](./settei-cli-standard.md):** fleet standard for CLI configuration with settei—four-layer precedence, formats, and diagnostics.
- **[Kubernetes Deployment Standard](./kubernetes-deployment.md):** Kubernetes operational standard—overlays, mounted sources, the `--check-config` gate, no-reload rollouts, and graceful shutdown.
- **[Settei Gotchas](./settei-gotchas.md):** settei footgun catalogue—null presence, positional precedence, pinning, and redaction edges.

## Upstream Reference

These are terse fleet rules. Use `mori registry docs shinzui/settei` to find the settei repository's long-form guides, compatibility statement, examples, and adapter references. The standards here were verified against the Hackage-published, annotated-tagged 0.2.0.0 package family.

## Related Patterns

- [Settei Service Configuration Standard](./settei-service-standard.md) is the primary application authoring standard.
- [Kubernetes Deployment Standard](./kubernetes-deployment.md) is the primary operator runbook.
- In `shinzui/haskell-jitsurei`, `api/health-endpoints.md` defines Kubernetes probe behavior.
