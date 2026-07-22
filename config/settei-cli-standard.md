# Settei CLI Configuration Standard

**Build every configurable CLI from four visible layers whose occurrence order is its precedence order.**

This standard applies to new and materially refactored keiro command-line applications. It replaces the fleet's earlier layered-Dhall convention with settei 0.2.0.0 provenance, structural redaction, multi-format input, and reusable diagnostics.

## Use Four Layers

The canonical low-to-high order is:

1. built-in defaults;
2. `--config FORMAT:PATH` files, in command-line occurrence order;
3. explicitly bound environment variables;
4. `--set KEY=VALUE` overrides, in command-line occurrence order.

Later sources win. Repeated files and repeated keys are not merged out of existence: each becomes a separate source so the report retains its shadow trace.

```haskell
-- CORRECT: each layer remains a distinct source in the report.
resolveCliOptions
  :: EnvSnapshot
  -> [ConfigInput]
  -> [CliOverride]
  -> IO (Either (NonEmpty FormatLoadError) (ResolveResult CliConfig))
resolveCliOptions snapshot inputs overrides = do
  loaded <- traverse (loadConfigInput defaultLoadOptions) inputs
  pure $ do
    fileSources <- sequence loaded
    pure
      ( resolve
          defaultResolveOptions
          ( [builtInSource]
              <> fileSources
              <> [environmentSource environmentBindings snapshot]
              <> cliSources "arguments" overrides
          )
          cliConfig
      )
```

Keep this source assembly in one function. Do not assign imaginary priority numbers to sources; the list is the whole precedence model.

## Require an Explicit File Format

Use `configInputOptions` from `Settei.Formats.Optparse`. Every file argument is tagged `yaml:PATH`, `kdl:PATH`, or `dhall:PATH`; `parseConfigInput` rejects an absent or unknown tag. Explicit tags avoid extension guessing and allow a controlled migration between formats.

```console
tool --config yaml:config/base.yaml \
     --config kdl:config/local.kdl \
     --set service.timeout=10
```

`loadConfigInput defaultLoadOptions` dispatches to the selected adapter. Dhall uses `NoImports` by default; opt into `LocalImportsWithin` only for a named trusted root.

A single-format CLI should depend directly on that format adapter and accept `--config PATH`; use the `settei-formats` umbrella only when the explicit format tag is part of the CLI contract.

## Compose the Parser from Public Modules

Use `configInputOptions`, `overrideOptions`, and `diagnosticModeOptions` together. `setteiOptions` is convenient for untagged `--config PATH`; a fleet CLI accepting multiple formats must use `configInputOptions` instead.

```haskell
-- CORRECT: use the tagged parser when multiple formats are supported.
cliOptionsParser :: Parser CliOptions
cliOptionsParser =
  CliOptions
    <$> Options.parserOptionGroup "Configuration" configInputOptions
    <*> Options.parserOptionGroup "Configuration" overrideOptions
    <*> Options.parserOptionGroup "Diagnostics" diagnosticModeOptions
```

`cliSources` creates one source per `--set` occurrence and records only a secret-safe spelling containing the option and key. `CliOverride` retains raw text so the declared `Setting` decoder runs during resolution. Never reconstruct or log the raw `KEY=VALUE` token.

## Expose the Standard Diagnostic Modes

Every configurable CLI must support:

- `--describe-config` and `--describe-config-json` for the static schema;
- `--explain-config` and `--explain-config-json` for the resolved provenance report;
- `--check-config` to validate inputs and exit without performing the command's action.

The actual option is `--explain-config`, not `--explain`. Wire schema modes through `schemaDiagnostic` before loading files; wire resolution modes through `resolutionDiagnostic` after resolution.

Use the service-standard exit-code contract: 2 for usage errors, 3 for source load/parse errors, and 4 for resolution errors. Diagnostics go to standard output on success and standard error on failure.

## Redact at Declaration Time

Declare a token or password with `secretSetting` even when its most common source is `--set`. Settei's report then renders the winning and shadowed candidates as redacted. The `CliOverride` constructor is private, and `cliOverrideSpelling` omits the raw value; preserve that boundary.

```haskell
tokenSetting :: Setting SecretText
tokenSetting =
  secretSetting
    (validKey "credentials.token")
    "Authentication token"
    (SecretText <$> textDecoder)
```

Do not derive `Show` for a secret-bearing resolved configuration. Render normal command output from an explicit allowlist.

The layered-Dhall pattern in the `shinzui/haskell-jitsurei` repository's `cli/hierarchical-config.md` is superseded for new work. It remains valid history for tools already built on that model.

## Bind Environment Variables, Do Not Discover Them

Use the same validated `Bindings` posture as services: explicit `binding` rows, a top-level CAF, and a test that forces it. Environment is one layer, not a source-discovery mechanism. An unbound process variable cannot affect resolution.

## Built-ins Are a Source, Defaults Are Rules

Use a built-in `Source` for ordinary CLI defaults that operators may override and whose origin should read “built in.” Use `withDefault` and named `Default` rules when the value is derived from other settings or its derivation belongs in the report. Do not hide operational defaults in the action code after resolution.

## Related Patterns

- [Settei Service Configuration Standard](./settei-service-standard.md) defines settings, bindings, redaction, and exit codes.
- [Settei Gotchas](./settei-gotchas.md) covers malformed winners, null, and positional precedence.
- In the `shinzui/settei` repo, `examples/settei-cli` and `docs/guides/cli-application.md` are the complete public-API references.
