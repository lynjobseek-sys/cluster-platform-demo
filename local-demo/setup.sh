#!/usr/bin/env bash
set -euo pipefail

# Verify host-side prerequisites. Fails fast with a useful message rather
# than letting later scripts produce a stack trace.

required=(docker kind kubectl helm jq)
missing=()
for bin in "${required[@]}"; do
  command -v "$bin" >/dev/null 2>&1 || missing+=("$bin")
done

if (( ${#missing[@]} > 0 )); then
  echo "[setup] missing required binaries: ${missing[*]}" >&2
  echo "[setup] install hints:" >&2
  echo "  brew install ${missing[*]}" >&2
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo "[setup] docker daemon not reachable. Start Docker Desktop / colima first." >&2
  exit 1
fi

echo "[setup] all prerequisites present"
