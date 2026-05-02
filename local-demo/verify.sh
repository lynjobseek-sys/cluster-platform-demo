#!/usr/bin/env bash
set -euo pipefail

HUB_CTX="kind-hub"
kctl() { kubectl --context "$HUB_CTX" "$@"; }

# Wait for the demo Application to converge.
deadline=$((SECONDS + 300))
while (( SECONDS < deadline )); do
  sync=$(kctl -n argocd get application demo-podinfo -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "Unknown")
  health=$(kctl -n argocd get application demo-podinfo -o jsonpath='{.status.health.status}' 2>/dev/null || echo "Unknown")
  echo "[verify] demo-podinfo sync=$sync health=$health"
  if [[ "$sync" == "Synced" && "$health" == "Healthy" ]]; then
    echo "[verify] demo-podinfo converged"
    kctl -n demo get pods
    exit 0
  fi
  sleep 5
done

echo "[verify] demo-podinfo did not converge within 5m" >&2
kctl -n argocd describe application demo-podinfo | tail -40 >&2
exit 1
