# Agent instructions

## Dependency lookup

Always use Mori to find dependency source code and documentation before guessing
at APIs or relying on memory.

- Run `mori registry list` to discover registered projects by qualified name.
- Run `mori registry search <package-name>` to find packages in a project.
- Run `mori registry show <project> --full` for source paths and metadata.
- Run `mori registry docs <project>` for curated local guidance.
- Run `mori registry dependents <project>` for reverse dependencies.
- Read dependency source and documentation directly at Mori's reported path.
- Verify released versions against the authoritative package registry and
  upstream release tags before choosing bounds, pins, or compatibility workarounds.

Never search, glob, grep, read, or otherwise traverse `/nix/store` or the
filesystem root `/`. Scope searches to this repository or another specific path
reported by Mori.

## Runtime pattern corpus

Before guessing which document contains a standard, discover the registered
bundle and concepts:

```bash
mori registry bundles shinzui/keiro-runtime-patterns
mori registry concepts shinzui/keiro-runtime-patterns --bundle runtime-patterns
```

Use `okf show runtime-patterns <concept-id>` for focused context. Concept IDs are
bundle-relative paths without `.md`, such as `messaging/process-managers`.

When changing a concept under `runtime-patterns/`:

1. Update its frontmatter `timestamp` to the material change time.
2. Add a concise entry to the nearest enclosing `log.md` with `okf log add`.
3. Regenerate indexes with `okf index runtime-patterns --write`.
4. Run `scripts/check-runtime-patterns [BASE_REF]`.

Generated `index.md` files are owned by OKF and must not be edited by hand.

## Git

Use Conventional Commits for every commit. Commit directly to the current
branch unless the user explicitly requests a feature branch.
