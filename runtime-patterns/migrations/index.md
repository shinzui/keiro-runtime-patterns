# Guide

- [Codd to pg-migrate Transition](codd-transition.md) - Why the fleet moved from codd to pg-migrate and how persistent databases were imported ledger-only
- [The pg-migrate Model](pg-migrate-model.md) - The pg-migrate model: components, manifests, exact-byte embedding, the ledger, the RecompilePlugin, and its layered integrity gates
- [Migration Testing](testing.md) - Integrity gates in the default suite, ephemeral-database tests with withMigratedDatabase, the nested-Either gotcha, and per-service wrappers

# Overview

- [Migration Standards](overview.md) - Index of pg-migrate migration standards for keiro services; start here

# Runbook

- [Migration Operations](operations.md) - Operating verify, verify-schema, status, and repair; the codd preflight; Running after a crash needs audited repair

# Standard

- [Migration Authoring](authoring.md) - Authoring rules: append-only migrations, the three-file review diff, the no-transaction directive, and manifest v1 strictness
- [Service Migration Packages](service-package.md) - The <service>-migrations package pattern composing kiroku, keiro, pgmq, and service components into one plan, plus the startup handshake

