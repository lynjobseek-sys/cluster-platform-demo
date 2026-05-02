#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

ensure_cluster() {
  local name="$1"
  local config="$2"
  if kind get clusters 2>/dev/null | grep -qx "$name"; then
    echo "[clusters] kind cluster '$name' already exists, skipping"
  else
    echo "[clusters] creating kind cluster '$name'"
    kind create cluster --name "$name" --config "$config" --wait 5m
  fi
}

ensure_cluster hub  kind/hub.yaml
ensure_cluster dev  kind/dev.yaml
ensure_cluster prod kind/prod.yaml

echo "[clusters] all 3 clusters ready"
for ctx in kind-hub kind-dev kind-prod; do
  kubectl --context "$ctx" cluster-info | head -1
done
