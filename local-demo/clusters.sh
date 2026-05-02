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

ensure_cluster hub kind/hub.yaml

# Phase 3 will add 'dev' and 'prod' here.

echo "[clusters] hub ready"
kubectl --context kind-hub cluster-info
