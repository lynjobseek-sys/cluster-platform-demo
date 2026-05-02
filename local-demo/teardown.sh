#!/usr/bin/env bash
set -euo pipefail

for c in hub dev prod; do
  if kind get clusters 2>/dev/null | grep -qx "$c"; then
    echo "[teardown] deleting kind cluster '$c'"
    kind delete cluster --name "$c"
  fi
done

echo "[teardown] done"
