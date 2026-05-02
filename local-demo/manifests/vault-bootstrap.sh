#!/usr/bin/env bash
# Sourced from local-demo/bootstrap.sh after the vault Pod is Ready and
# vault-secrets-operator CRDs are installed. Imperative on purpose: Vault
# config (auth methods, policies, KV seed) is the seam that GitOps cannot
# reasonably own without a circular dependency on Vault itself.
set -euo pipefail

HUB_CTX="${HUB_CTX:-kind-hub}"
VAULT_NS="${VAULT_NS:-vault}"
VAULT_POD="${VAULT_POD:-vault-0}"
TEAMS=(frontend backend data)
ENVS=(local staging)

vex() { kubectl --context "$HUB_CTX" -n "$VAULT_NS" exec "$VAULT_POD" -- /bin/sh -c "VAULT_TOKEN=root VAULT_ADDR=http://127.0.0.1:8200 $*"; }

# 1. Enable kv-v2 at secret/ (dev mode auto-mounts it, but the call is
#    idempotent and survives a restart with persistent storage later).
vex "vault secrets list -format=json | grep -q '\"secret/\"' || vault secrets enable -path=secret -version=2 kv"

# 2. Enable kubernetes auth and point it at the in-cluster API server.
vex "vault auth list -format=json | grep -q '\"kubernetes/\"' || vault auth enable kubernetes"
vex 'vault write auth/kubernetes/config kubernetes_host="https://kubernetes.default.svc.cluster.local:443"'

# 3. Per-team policy + k8s auth role (one role per env) + seed secret.
for team in "${TEAMS[@]}"; do
  vex "echo 'path \"secret/data/${team}/*\" { capabilities = [\"read\", \"list\"] }' | vault policy write ${team}-readonly -"

  for env in "${ENVS[@]}"; do
    vex "vault write auth/kubernetes/role/${team}-${env} \
      bound_service_account_names=default \
      bound_service_account_namespaces=${team}-${env} \
      policies=${team}-readonly \
      ttl=1h"
  done

  vex "vault kv put secret/${team}/config greeting=hello-from-${team}"
done

echo "[vault-bootstrap] policies, k8s auth roles, and seed secrets in place"
