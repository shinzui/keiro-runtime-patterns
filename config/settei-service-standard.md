# Settei Service Configuration Standard

**Declare configuration once, resolve it from an explicit source order, and keep provenance safe enough to use during incidents.**

This is the fleet standard for new and materially refactored keiro microservices. It targets the released settei 0.2.0.0 package family; upgrade every settei package together because mixed family versions are unsupported.

## Declare an Inspectable Configuration

The rule is one sentence: model the complete process configuration as a `Config a`, using `Applicative` and selective combinators rather than runtime-dependent declaration code.

`describe :: Config a -> Schema` must be able to discover every possible key before a source is read. `Config` therefore deliberately has no `Monad` instance. Use `whenConfig` or `whenEq` for conditional requirements, `fallbackTo` for key migration, and `withDefault` for a named default.

```haskell
-- CORRECT: the declaration is statically inspectable.
serviceConfig :: Config ServiceConfig
serviceConfig =
  ServiceConfig
    <$> required environmentSetting
    <*> required databaseHostSetting
    <*> whenEq
          (required environmentSetting)
          Production
          (required databasePasswordSetting)

databaseHost :: Config Text
databaseHost =
  optional newDatabaseHostSetting
    `fallbackTo` required legacyDatabaseHostSetting
```

Only the selected branch is evaluated. Independent applicative errors accumulate, so an operator sees the complete actionable failure rather than one missing key per restart.

```haskell
-- WRONG: the required key set would depend on a resolved value.
-- Config has no Monad instance, so this cannot compile.
dynamicConfig = do
  environment <- required environmentSetting
  required (settingChosenAtRuntime environment)
```

## Put Sensitivity on the Setting

Every `Setting a` needs a stable hierarchical key, a useful operator-facing description, a decoder, and the correct sensitivity. Use `publicSetting`, `publicSettingWithRenderer`, or `publicShowSetting` only when a resolved value may appear in diagnostics. Use `secretSetting` for credentials, tokens, private keys, and any other value that must not appear.

```haskell
-- CORRECT: sensitivity follows the key through every source.
databasePasswordSetting :: Setting SecretText
databasePasswordSetting =
  secretSetting
    (validKey "database.password")
    "Password used by the service database role"
    (SecretText <$> textDecoder)
```

Sensitivity belongs to the logical setting, not its delivery path. A database password is secret in a Kubernetes Secret, an environment variable, and a developer's local file. Declaring the same key as both public and secret is a `SensitivityConflict`; resolution fails, and report construction treats the key as secret.

Keep secret-bearing constructors private and do not derive a revealing `Show`. Settei protects its own reports; application logging still needs an allowlist.

## Fix the Service Source Order

The canonical low-to-high order is:

1. general configuration files;
2. mounted Kubernetes Secret directories;
3. explicitly bound environment variables.

`resolve` chooses the rightmost candidate. A pod-spec environment override therefore wins during an incident while the report retains the mounted and file candidates as shadowed provenance.

```haskell
-- CORRECT: construct one explicit low-to-high list.
fleetResolveOptions :: ResolveOptions
fleetResolveOptions =
  defaultResolveOptions {unknownKeyPolicy = RejectUnknownKeys}

resolveServiceSources
  :: [Source]      -- general files, in occurrence order
  -> [Source]      -- mounted Secret directories
  -> EnvSnapshot
  -> ResolveResult ServiceConfig
resolveServiceSources files mountedSecrets snapshot =
  resolve
    fleetResolveOptions
    ( files
        <> mountedSecrets
        <> [environmentSource environmentBindings snapshot]
    )
    serviceConfig
```

Precedence is positional only. Keep this assembly in one function per binary and test the order. Never silently fall back when the winning value is malformed: fix or remove that value.

Set `RejectUnknownKeys` for fleet services. The library default, `WarnUnknownKeys`, is suitable for exploratory tools but lets misspelled production configuration pass startup.

The complete reference is the `shinzui/settei` repository's `examples/settei-service/src/Settei/Example/Service.hs`, discoverable with `mori registry show shinzui/settei --full`.

## Bind Environment Variables Explicitly

There is no runtime prefix scan. Map every accepted environment variable to a key with `binding`, validate the collection with `bindings`, and build the source with `environmentSource` or `readEnvironmentSource`. Use `prefixedBindings` only as a construction convention; it detects generated-name collisions. Use `mergeBindings` to combine independently validated groups.

Declare bindings as a top-level CAF and force it in a unit test. Construction errors are programming errors and belong in CI.

```haskell
-- CORRECT: validate once and force the exact production CAF in CI.
environmentBindings :: Bindings
environmentBindings =
  either
    (error . Text.unpack . renderEnvErrorsText)
    id
    ( bindings
        [ binding (EnvName "HASKELL_ENV") (validKey "runtime.environment")
        , binding (EnvName "HTTP_PORT") (validKey "http.port")
        , binding (EnvName "DATABASE_PASSWORD") (validKey "database.password")
        ]
    )

bindingsTest :: TestTree
bindingsTest = testCase "environment bindings construct" $ do
  _ <- evaluate environmentBindings
  pure ()
```

The test imports `evaluate` from `Control.Exception`. It deliberately forces the CAF rather than rebuilding an alternate binding list.

## Reserve Configuration Diagnostics

Every service binary must expose the reusable `diagnosticModeOptions` modes:

- `--describe-config` and `--describe-config-json` print the static schema without loading sources;
- `--explain-config` and `--explain-config-json` load and resolve sources, then print provenance;
- `--check-config` loads and resolves exactly as normal startup would, prints only redacted diagnostics, and exits without opening a listener or starting workers.

Reserve these exit codes across the fleet:

| Code | Meaning |
|---:|---|
| 2 | command-line usage or flag error |
| 3 | source IO or parsing failure |
| 4 | typed resolution failure |

Do not collapse these into exit code 1. Kubernetes init-container rollout gates and incident automation use the distinction.

## Treat the Report as the Diagnostic Boundary

`ResolveResult` always contains `report` and `warnings`; its `answer` contains the typed value or accumulated `ConfigError`s. Reports exist on success and failure. `ReportedValue` constructors keep secret rendering structural: public values can be visible, secret values are redacted, and derived values name their rule.

Never recover raw values from a report, interpolate a whole resolved record into a log line, or print a `--set` spelling containing its value. Render settei reports and log a separate allowlisted startup summary. Keep a conformance test with a planted secret sentinel and assert that it appears in neither standard output, standard error, errors, nor rendered reports while the redaction marker does.

## Migrate Raw Dhall Deliberately

Raw `FromDhall` plus `inputFile auto` wiring is superseded for new work. Migrate without changing deployment values in the same step:

1. declare the stable keys and `Setting`s;
2. express the typed target as `Config a`;
3. load the existing document through `settei-dhall`;
4. choose an explicit import policy—`NoImports` by default, or `LocalImportsWithin` a named root;
5. add environment and mounted-secret sources in the canonical order;
6. add describe, explain, and check modes before changing manifests.

Dhall import normalization cannot preserve leaf-level file attribution across an import closure. Treat the loaded document as one source and keep secret sensitivity on the `Setting`.

## Dependency Posture

Pin the released 0.2.0.0 settei family together while the family remains experimental. A typical service uses `settei`, `settei-env`, `settei-formats`, `settei-optparse-applicative`, and `settei-kubernetes`, all at `==0.2.0.0`. Import documented modules such as `Settei`, `Settei.Env`, and `Settei.Kubernetes`; see the gotcha catalogue for the excluded family-internal surface.

## Related Patterns

- [Settei CLI Configuration Standard](./settei-cli-standard.md) defines the four-layer CLI order.
- [Kubernetes Deployment Standard](./kubernetes-deployment.md) turns `--check-config` into a rollout gate.
- [Settei Gotchas](./settei-gotchas.md) lists resolution and adapter traps.
- In the `shinzui/settei` repo, `docs/guides/kubernetes-service.md` is the long-form reference.
