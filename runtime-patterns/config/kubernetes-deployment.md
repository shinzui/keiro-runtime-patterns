---
type: Runbook
title: "Kubernetes Deployment Standard"
description: "Kubernetes operational standard: overlays, mounted sources, check-config gate, no-reload rollouts, graceful shutdown"
timestamp: 2026-07-29T18:11:55-07:00
resource: mori://shinzui/keiro-runtime-patterns/docs/config-kubernetes-deployment
tags: [config, kubernetes-deployment]
status: current
reviews:
  - kind: model
    reviewer: claude-code
    reviewed_at: 2026-07-30T00:43:08Z
    document_timestamp: 2026-07-22T12:43:58-07:00
    scope: technical-accuracy
    outcome: changes-requested
    provider: anthropic
    model: claude-fable-5
    effort: unspecified
    context: >-
      Model technical-accuracy review against the mori-resolved settei 0.2.0.0 checkout, its examples and deploy manifests, and Hackage release state; changes requested: the envFrom and configMapKeyRef snippets cannot both work against one ConfigMap, leaving HASKELL_ENV unresolved.
  - kind: model
    reviewer: claude-code
    reviewed_at: 2026-07-30T01:11:55Z
    document_timestamp: 2026-07-29T18:11:55-07:00
    scope: technical-accuracy
    outcome: approved
    provider: anthropic
    model: claude-fable-5
    effort: unspecified
    context: >-
      Model re-review of the correction against the settei reference deployment: both containers now bind HASKELL_ENV via configMapKeyRef, and the validator and kubeconform claims match their sources.
---

# Kubernetes Deployment Standard

**Promote one image through namespace overlays, gate startup with the real configuration path, and make SIGTERM a bounded drain.**

This runbook defines the deployment half of the fleet configuration standard. It assumes the binary follows the [Settei Service Configuration Standard](./settei-service-standard.md) and reserves exit codes 2, 3, and 4.

## Build One Image for Every Namespace

Build one immutable image and promote its digest through development, test, and production. Environment is configuration, never a compile-time flag and never inferred from the namespace name.

Use one kustomize base for the Deployment, Service, probes, volumes, and process arguments. Each namespace overlay supplies only environment-specific values, replicas, resource policy, and approved patches.

Keep the base namespace-agnostic and use the same ConfigMap and Secret object names in every namespace. The diff between two overlay directories must be the complete configuration diff between those environments.

```text
deploy/
  base/
    deployment.yaml
    service.yaml
    kustomization.yaml
  overlays/
    dev/
    test/
    production/
```

```yaml
# deploy/overlays/production/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: production
resources:
  - ../../base
configMapGenerator:
  - name: service-config
    files:
      - application.yaml
images:
  - name: service-image
    newName: registry.example/service
    newTag: sha256-<approved-digest>
```

Do not maintain copy-pasted Deployments per namespace.

## Record Namespace Identity, Choose Behavior Explicitly

The downward API may inject identity for provenance:

```yaml
env:
  - name: POD_NAMESPACE
    valueFrom:
      fieldRef:
        fieldPath: metadata.namespace
  - name: HASKELL_ENV
    valueFrom:
      configMapKeyRef:
        name: service-runtime
        key: HASKELL_ENV
```

`POD_NAMESPACE` answers where the pod runs. It must not silently decide database hosts, feature policy, credentials, or other behavior. Supply `HASKELL_ENV` and operational values explicitly through the overlay.

## Mount Structured Configuration and Secrets Separately

Mount general configuration from a ConfigMap and secret material from a Secret directory. Bind filenames to settei keys explicitly with `fileBindings`; unbound files are detectable through `unboundMountedFiles` and should fail validation in deployment tooling.

`readMountedDirectorySource` follows Kubernetes atomic-writer symlinks normally. A bound missing file is absent input, not an empty value. By default it strips exactly one trailing newline; use `keepTrailingNewline` only when a decoder needs byte-faithful content.

When a value is delivered through an environment variable backed by a Kubernetes object, use `Settei.Kubernetes.Bindings.bindingsFromSecret` or `bindingsFromConfigMap`. Each row derives the environment binding and its Kubernetes provenance annotation together so they cannot drift.

```yaml
volumeMounts:
  - name: configuration
    mountPath: /etc/service/config
    readOnly: true
  - name: database-secret
    mountPath: /etc/service/secrets/database
    readOnly: true
volumes:
  - name: configuration
    configMap:
      name: service-config
  - name: database-secret
    secret:
      secretName: service-database
```

Kubernetes provenance annotations are caller-supplied metadata. Settei does not contact the cluster and does not attest that a named object exists.

## Gate Every Pod with `--check-config`

Run the same image in an init container with the same arguments, environment, mounts, service account, and process-visible inputs as the main container. The only behavioral difference is `--check-config`.

```yaml
spec:
  terminationGracePeriodSeconds: 60
  initContainers:
    - name: check-config
      image: service-image
      args:
        - --check-config
        - --config
        - yaml:/etc/service/config/application.yaml
        - --secrets-dir
        - /etc/service/secrets/database
      env:
        - name: HASKELL_ENV
          valueFrom:
            configMapKeyRef:
              name: service-runtime
              key: HASKELL_ENV
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
      volumeMounts: &configuration-mounts
        - name: configuration
          mountPath: /etc/service/config
          readOnly: true
        - name: database-secret
          mountPath: /etc/service/secrets/database
          readOnly: true
  containers:
    - name: service
      image: service-image
      args:
        - --config
        - yaml:/etc/service/config/application.yaml
        - --secrets-dir
        - /etc/service/secrets/database
      env:
        - name: HASKELL_ENV
          valueFrom:
            configMapKeyRef:
              name: service-runtime
              key: HASKELL_ENV
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
      volumeMounts: *configuration-mounts
```

If maintaining duplicate `env` blocks becomes error-prone, generate both from one deployment template or use a strategic merge patch; do not accept configuration drift between the gate and the process.

The gate interprets code 2 as a manifest/argument defect, 3 as an unreadable or malformed source, and 4 as a typed configuration defect. A nonzero result blocks the pod before it opens a listener or consumes messages.

## Restart to Apply Configuration

The fleet does not hand-roll configuration reload. Settei resolves a startup snapshot; projected volume updates do not mutate the running typed configuration. Change the ConfigMap or Secret, validate the rendered overlay, then trigger a Deployment rollout.

```bash
kubectl rollout restart deployment/service -n production
kubectl rollout status deployment/service -n production
```

Prefer generated ConfigMap/Secret name hashes or an explicit pod-template checksum so a content change creates a rollout automatically. Secret rotation is complete only after every old pod has terminated.

## Validate Overlays Offline

Render every overlay in CI, scan the rendered output for the exact placeholder, and perform client-side schema validation before applying anything.

```bash
for overlay in deploy/overlays/dev deploy/overlays/test deploy/overlays/production; do
  kubectl kustomize "$overlay" > "$(basename "$overlay").rendered.yaml"
  kubectl apply --dry-run=client -f "$(basename "$overlay").rendered.yaml"
done

if rg -n 'PLACEHOLDER-REPLACE-VIA-YOUR-SECRET-PIPELINE' ./*.rendered.yaml; then
  echo 'placeholder secret remains in rendered manifests' >&2
  exit 1
fi
```

Never commit a real secret. The literal `PLACEHOLDER-REPLACE-VIA-YOUR-SECRET-PIPELINE` is permitted only as an unmistakable failure marker and must be rejected from rendered release manifests.

Also assert on the rendered structure: the `check-config` init container exists, its image equals the main container image, both containers receive the same environment and mounts, `POD_NAMESPACE` uses `fieldRef`, `HASKELL_ENV` comes from the ConfigMap, and `--secrets-dir` names the actual Secret mount. The `shinzui/settei` repo's `examples/settei-service/deploy/validate.sh` demonstrates the technique with a smaller grep-based assertion set (gate arguments, `fieldRef`, the secret mount, rendered `HASKELL_ENV` values); extend it with the structural assertions above. `kubeconform` can add client-side Kubernetes schema validation, but it downloads schemas by default, so treat it as a networked step or point it at vendored schemas.

## Drain HTTP Requests on SIGTERM

Kubernetes sends SIGTERM, waits `terminationGracePeriodSeconds` (30 seconds by default), and then sends SIGKILL. Warp does not install a shutdown handler by default. With released warp 3.4.14, install a SIGTERM handler through `setInstallShutdownHandler`; calling the supplied action closes the listening socket and enters graceful shutdown. Bound the wait with `setGracefulShutdownTimeout` because its default is `Nothing`, meaning indefinitely.

```haskell
warpSettings :: Settings
warpSettings =
  setGracefulShutdownTimeout (Just 25)
    $ setInstallShutdownHandler installTermHandler
    $ defaultSettings
  where
    installTermHandler closeListenSocket =
      void
        ( installHandler
            sigTERM
            (CatchOnce closeListenSocket)
            Nothing
        )
```

Set the pod grace period above the Warp timeout and any coordinated application cleanup. `CatchOnce` leaves a repeated signal available as an emergency hard stop.

## Drain Shibuya Workers on SIGTERM

Translate SIGTERM into `stopAppGracefully shutdownConfig appHandle`. Released `shibuya-core` 0.8.0.1 first signals adapter shutdown, waits up to `drainTimeout`, stops the supervisor, and returns whether the drain completed. Its default drain timeout is 30 seconds, and the timed wait requires the executable to be linked with `-threaded`.

Use at least `terminationGracePeriodSeconds: 60` for a worker using the default 30-second drain, leaving time for signal dispatch, adapter shutdown, telemetry flush, and process exit. Increase both budgets together for workloads whose valid handler duration exceeds 30 seconds.

PGMQ is at-least-once. With released `shibuya-pgmq-adapter` 0.12.0.0, the non-prefetch path releases a just-read undispatched batch by setting its visibility timeout to zero. Opt-in prefetch can leave up to `bufferSize * batchSize` already-read messages invisible until their configured visibility timeout expires. They are redelivered and are not lost, but failover is delayed. Keep prefetch disabled when prompt shutdown release matters, or budget its visibility timeout explicitly.

## Use the Fleet Probe Contract

Use the Kubernetes startup, readiness, and liveness contract in the `shinzui/haskell-jitsurei` repository's `api/health-endpoints.md`. Do not turn a transient dependency failure into a liveness restart loop, and make readiness false before a coordinated drain when the server architecture permits it.

## Related Patterns

- [Settei Service Configuration Standard](./settei-service-standard.md) defines the resolver and diagnostic contract.
- [Settei Gotchas](./settei-gotchas.md) covers mounted-file and provenance traps.
- In the `shinzui/settei` repo, `docs/guides/kubernetes-cookbook.md` and `examples/settei-service/deploy/` are the long-form reference deployment.
- In `shinzui/haskell-jitsurei`, `api/health-endpoints.md` is the normative probe guide.
