# Phase 8 integration: Vault + vault-secrets-operator

This file describes the wiring required outside the Phase 8 file scope:
edits to `pkg/common/config/managed.k`, `local-demo/bootstrap.sh`, and
`README.md`. Verification commands and chart versions live at the bottom.

## 1. Chart versions

| Component                  | Helm chart                                  | Chart version | App version |
| -------------------------- | ------------------------------------------- | ------------- | ----------- |
| Vault server (dev mode)    | `hashicorp/vault`                           | `0.29.1`      | `1.18.1`    |
| vault-secrets-operator     | `hashicorp/vault-secrets-operator`          | `0.9.1`       | `0.9.1`     |

Both pinned in their respective `local-demo/manifests/vault*-app.yaml`.

## 2. ManagedProjects

`pkg/common/config/managed.k`:

```kcl
ManagedProjects: [str] = ["argocd", "monitoring", "vault"]
```

After the change, regenerate `manifests/main.yaml` with `just build`. The
new `vault-onboarding` ApplicationSet will scan
`appsops/*/vault/*/*` and produce one Application per team per env
(currently 6: 3 teams x {local, staging}).

## 3. bootstrap.sh additions

Append the following block to `local-demo/bootstrap.sh` after step 4
(`kctl apply -f ../manifests/main.yaml`) and before the admin-password
echo. Order matters: VSO needs Vault's Service to exist when its CRDs
are reconciled, and `vault-bootstrap.sh` needs the `vault-0` Pod Ready
because it execs into it.

```bash
# 5. Vault server in dev mode + vault-secrets-operator. Hub-only.
kctl apply -f manifests/vault-app.yaml
kctl apply -f manifests/vault-secrets-operator-app.yaml

# Wait for the Vault Pod (managed by the ArgoCD Application above) to come
# up before we start writing config into it. The Application creates the
# vault namespace via CreateNamespace=true.
kctl wait --for=condition=Available --timeout=5m \
  -n argocd application/vault || true
kctl -n vault rollout status statefulset/vault --timeout 5m
kctl -n vault wait --for=condition=Ready pod/vault-0 --timeout 3m

# Wait for VSO CRDs and controller before the team Applications try to
# apply VaultConnection / VaultAuth / VaultStaticSecret CRs.
kctl wait --for=condition=Available --timeout=5m \
  -n argocd application/vault-secrets-operator || true
kctl -n vault-secrets-operator-system rollout status \
  deployment/vault-secrets-operator-controller-manager --timeout 5m

# 6. Imperative Vault seed: per-team policies, k8s auth roles, KV secrets.
HUB_CTX="$HUB_CTX" source manifests/vault-bootstrap.sh
```

The `vault.vault.svc.cluster.local:8200` address that team
VaultConnection CRs point at requires the Vault Pod to be running in the
`vault` namespace under the `vault` Service (the chart's default service
name). Both are created by `vault-app.yaml`.

## 4. README warning (paste as-is)

Add the following block under Quickstart, immediately before the
`just up` line:

```markdown
## Vault dev mode

> WARNING: Dev mode only. The hub runs Vault with an in-memory backend and
> a hardcoded root token of `root`. Everything is wiped on Pod restart and
> there is no TLS. Do not run this configuration outside a throwaway local
> cluster, and never expose port 8200 beyond the kind network.
```

Use a blockquote (not a callout) to match the existing `> Status:`
blockquote tone in the README.

## 5. Verification

After `just up` completes and the `vault-onboarding` ApplicationSet has
synced, the per-team Secrets should exist:

```bash
kubectl --context kind-hub -n frontend-local \
  get secret frontend-vault-config -o jsonpath='{.data.greeting}' | base64 -d
# expected: hello-from-frontend

kubectl --context kind-hub -n backend-local \
  get secret backend-vault-config -o jsonpath='{.data.greeting}' | base64 -d
# expected: hello-from-backend

kubectl --context kind-hub -n data-local \
  get secret data-vault-config -o jsonpath='{.data.greeting}' | base64 -d
# expected: hello-from-data
```

Note: only `local` env Secrets land on the hub. `staging` env Applications
target the `kind-dev` cluster, where Vault is not reachable through
`vault.vault.svc.cluster.local`. The staging VaultStaticSecret CRs will
sync as far as VSO can resolve them; cross-cluster Vault reach is out of
scope for Phase 8 (would require a NodePort or an Ingress in front of
Vault and a real CA).

## 6. Files created in this phase

```
local-demo/manifests/vault-app.yaml
local-demo/manifests/vault-secrets-operator-app.yaml
local-demo/manifests/vault-bootstrap.sh        (chmod +x)
appsops/<team>/vault/connection/<env>/Chart.yaml
appsops/<team>/vault/connection/<env>/values.yaml
appsops/<team>/vault/connection/<env>/delivery.yml
appsops/<team>/vault/connection/<env>/templates/vaultconnection.yaml
appsops/<team>/vault/connection/<env>/templates/vaultauth.yaml
appsops/<team>/vault/connection/<env>/templates/staticsecret.yaml
appsops/INTEGRATION-vault.md                   (this file)
```

`<team>` in `{frontend, backend, data}`, `<env>` in `{local, staging}`.
