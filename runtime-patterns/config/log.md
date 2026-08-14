# config Update Log

## 2026-08-14
* **Update**: Move Shibuya core and PGMQ adapter shutdown claims to the released 0.9.0.0 and 0.14.0.0 versions

## 2026-08-06
* **Migration**: Move the bundle to OKF v0.2: every concept gains a generated provenance mapping and restates its timestamp in UTC

## 2026-07-29
* **Update**: Kubernetes deployment now binds HASKELL\_ENV via configMapKeyRef in both containers and corrects the validator and kubeconform claims; re-reviewed and approved
* **Review**: Recorded a model technical-accuracy review for all five concepts; approved four, changes requested for kubernetes-deployment (envFrom and configMapKeyRef snippets cannot both bind HASKELL\_ENV from one ConfigMap)

## 2026-07-23
* **Migration**: Adopted the OKF pattern-catalog profile for configuration guidance
