#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

: "${GITHUB_TOKEN:?GITHUB_TOKEN must be set so ArgoCD can read this repo (Phase 4+ uses it)}"

HUB_CTX="kind-hub"
ARGOCD_NS="argocd"
ARGOCD_VERSION="${ARGOCD_VERSION:-7.6.12}"   # Helm chart version that ships ArgoCD 2.12.x

kctl() { kubectl --context "$HUB_CTX" "$@"; }

# 1. Install ArgoCD via Helm. Idempotent: helm upgrade --install.
helm repo add argo https://argoproj.github.io/argo-helm >/dev/null 2>&1 || true
helm repo update argo >/dev/null

helm upgrade --install argocd argo/argo-cd \
  --kube-context "$HUB_CTX" \
  --namespace "$ARGOCD_NS" \
  --create-namespace \
  --version "$ARGOCD_VERSION" \
  --set configs.params."server\.insecure"=true \
  --set applicationSet.enabled=true \
  --wait --timeout 5m

# 2. Patch the ApplicationSet controller ClusterRole (appprojects list/watch).
kctl apply -f manifests/applicationset-clusterrole-patch.yaml

# 3. Patch argocd-cmd-params-cm: server-side diff + enable git generators.
kctl apply -f manifests/argocd-cmd-params-cm.yaml

# 4. Restart the controllers so they pick up the patched ConfigMap.
kctl -n "$ARGOCD_NS" rollout restart \
  statefulset/argocd-application-controller \
  deployment/argocd-applicationset-controller

kctl -n "$ARGOCD_NS" rollout status statefulset/argocd-application-controller --timeout 3m
kctl -n "$ARGOCD_NS" rollout status deployment/argocd-applicationset-controller --timeout 3m

# 5. Apply the single demo Application (Phase 2 sanity check).
kctl apply -f manifests/demo-app.yaml

echo "[bootstrap] hub ArgoCD ready. Initial admin password:"
kctl -n "$ARGOCD_NS" get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d
echo
echo "[bootstrap] port-forward to view UI:"
echo "  kubectl --context $HUB_CTX port-forward -n $ARGOCD_NS svc/argocd-server 8080:443"
