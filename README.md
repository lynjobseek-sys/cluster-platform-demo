# cluster-platform-demo

Reference implementation of a hub-and-spoke ArgoCD platform with KCL-driven manifest generation, OPA policy gates, kube-prometheus-stack monitoring, and a Vault-backed per-team secret flow. Designed to be cloned and run locally on kind in under 10 minutes.

> Status: scaffolding. See [Phases](#phases) for what works today.

## Quickstart

```bash
# Prereqs: docker, kind, kubectl, helm, jq. macOS: `brew install ...`
# Get a GitHub PAT with `repo` scope (used by ArgoCD to read this repo from Phase 4 onward).
export GITHUB_TOKEN=<your-pat>

just up      # setup -> clusters -> bootstrap -> verify
# ArgoCD UI: kubectl --context kind-hub port-forward -n argocd svc/argocd-server 8080:443
# Username admin, password printed by bootstrap.sh

just down    # tears down all kind clusters
```

## Architecture

_(diagram in Phase 9)_

## Layout

```
appsops/                team-owned input YAMLs
.policy/                OPA conftest rules
local-demo/             setup -> clusters -> bootstrap -> verify -> teardown
manifests/              committed KCL output
models/stacks/          KCL schemas + entry point
pkg/                    KCL packages (apps, common, gitops, managed, resources, util)
justfile                build / lint / clean / up / down
conftest.toml           OPA conftest config
kcl.mod                 KCL package manifest
```

## Phases

- [x] 1 — scaffolding
- [x] 2 — hub-only ArgoCD
- [ ] 3 — spokes (dev + prod)
- [ ] 4 — simpleOnboarding (KCL ApplicationSet)
- [ ] 5 — full team rollout (frontend / backend / data)
- [ ] 6 — OPA policies (conftest + just lint)
- [ ] 7 — monitoring (kube-prometheus-stack + per-team rules)
- [ ] 8 — Vault (server + operator + per-team KV)
- [ ] 9 — README + architecture diagram + demo gif

## License

MIT.
