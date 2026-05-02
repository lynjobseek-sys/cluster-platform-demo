# cluster-platform-demo

Reference implementation of a hub-and-spoke ArgoCD platform with KCL-driven manifest generation, OPA policy gates, kube-prometheus-stack monitoring, and a Vault-backed per-team secret flow. Designed to be cloned and run locally on kind in under 10 minutes.

The platform stays opinionated about four invariants:

1. **Hub-spoke**, not mesh. ArgoCD lives on one cluster (`hub`); workloads land on `dev` and `prod` spokes via cluster Secrets.
2. **GitOps from day one**. The only reason a workload exists in any cluster is that a directory in this repo describes it. Teams never `kubectl apply` and never write ArgoCD YAML.
3. **Per-team boundaries are real**. Each team has its own AppProject, namespace prefix, Vault policy, AlertManager route, and Grafana dashboard. None of these leak across teams.
4. **Runs on kind**. Three local clusters, no cloud account, ~10 minutes from `git clone` to a working multi-tenant platform.

## Vault dev mode

> WARNING: Dev mode only. The hub runs Vault with an in-memory backend and a hardcoded root token of `root`. Everything is wiped on Pod restart and there is no TLS. Do not run this configuration outside a throwaway local cluster, and never expose port 8200 beyond the kind network.

## Quickstart

```bash
# Prereqs: docker, kind, kubectl, helm, jq, just.
#   macOS: brew install kind kubectl helm jq just

# GitHub PAT with `repo` scope. ArgoCD uses it to read this repo, including
# private forks. A read-only token is enough.
export GITHUB_TOKEN=<your-pat>

just up      # setup -> clusters (hub/dev/prod) -> bootstrap -> verify
just down    # delete all three kind clusters
```

UI access (each in its own shell, the credentials prints come from `bootstrap.sh`):

```bash
# ArgoCD          username admin
kubectl --context kind-hub port-forward -n argocd svc/argocd-server 8080:443

# Grafana         username admin
kubectl --context kind-hub port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80

# Prometheus
kubectl --context kind-hub port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090

# AlertManager
kubectl --context kind-hub port-forward -n monitoring svc/kube-prometheus-stack-alertmanager 9093:9093
```

The teams (`frontend`, `backend`, `data`) ship podinfo to `local` (= hub) and `staging` (= dev). Each team x env combination is visible at a glance in Grafana and as its own card in the ArgoCD UI.

## Architecture

```
                   +--------------------------------------------+
                   |                  HUB cluster               |
                   |   (kind-hub, also runs all platform infra) |
                   |                                            |
   GitHub repo --->|   ArgoCD 2.12       AppProject x team      |
   (this repo)     |   ApplicationSet    AlertManager           |
                   |   controller        Prometheus + Grafana   |
                   |                     Vault (dev)            |
                   |                     vault-secrets-operator |
                   +-------+----------------+-------------------+
                           |                |
              cluster Secret              cluster Secret
              (kind --internal)           (kind --internal)
                           |                |
                  +--------v-----+   +------v---------+
                  | DEV cluster  |   | PROD cluster   |
                  |  (kind-dev)  |   |  (kind-prod)   |
                  |              |   |                |
                  | staging apps |   | future apps    |
                  +--------------+   +----------------+
```

How a team gets onboarded:

```
1. Team drops a directory:
       appsops/<team>/argocd/<app>/<env>/Chart.yaml + values.yaml

2. The platform's simpleOnboarding ApplicationSet (one per project) sees
   the directory through its git generator and creates an Application:
       name        = <team>-<app>-<env>
       project     = <team>           (matches the AppProject)
       destination = env -> cluster   (local=in-cluster, staging=dev, prod=prod)
       source      = the directory itself

3. ArgoCD syncs the directory's chart into <team>-<env> namespace.
   The team never wrote an ArgoCD Application, an AppProject, or
   touched the cluster directly.
```

The same simpleOnboarding pattern handles the `monitoring` and `vault` projects too, walking `appsops/*/monitoring/*/*` and `appsops/*/vault/*/*` respectively. Adding a new project = appending one string to `pkg/common/config/managed.k`.

## Layout

```
appsops/                       team-owned input. one directory per
  <team>/<project>/<app>/<env>/  Application. teams never edit anything else.

.policy/                       OPA conftest rules + tests + fixtures.
                                 just lint runs them against manifests/.

local-demo/                    setup.sh -> clusters.sh -> bootstrap.sh
                                 -> verify.sh -> teardown.sh.
                                 Idempotent. Re-run any step safely.
  kind/                          one kind config per cluster.
  manifests/                     hand-written platform manifests
                                 (ArgoCD patches, kube-prometheus-stack
                                 Application, Vault Application,
                                 vault-bootstrap.sh).

manifests/main.yaml            committed KCL output. one AppProject per
                                 team + one ApplicationSet per project
                                 listed in ManagedProjects.

models/stacks/                 KCL entry point (main.k) + base types.
pkg/                           KCL packages.
  common/config/                 ManagedProjects, Teams, RepoURL.
  gitops/                        appProject + simpleOnboarding lambdas.
  util/                          path helpers (fsutil unavailable).

justfile                       build / lint / clean / up / down.
conftest.toml                  policy = .policy, namespace = main.
kcl.mod                        KCL package manifest.
```

## Phases

The git history is built to be read top to bottom. Each commit is a self-contained step you can check out and run.

| | Phase | Commit |
|---|---|---|
| 1 | scaffolding | `chore: scaffold project structure` |
| 2 | hub-only ArgoCD | `feat: bootstrap hub-only ArgoCD on kind` |
| 3 | dev + prod spokes | `feat: register dev and prod spokes via cluster Secrets` |
| 4 | simpleOnboarding | `feat: simpleOnboarding ApplicationSet via KCL` |
| 5 | full team rollout | `feat: onboard backend and data teams` |
| 6 | OPA conftest | `feat: add OPA conftest policies (just lint)` |
| 7 | monitoring | `feat: enable kube-prometheus-stack on the hub` |
| 8 | Vault | `feat: enable Vault dev mode + vault-secrets-operator` |
| 9 | README + diagram | `docs: rewrite README with architecture diagram and quickstart` |

## What is intentionally not in scope

- **Production-grade Vault.** Dev mode only. No HA, no auto-unseal, no audit log, no cert rotation.
- **Cross-cluster Vault reach.** Vault lives on `hub`. The `staging` env's VaultStaticSecret CRs target `dev`, where `vault.vault.svc.cluster.local` does not resolve. A real deployment would expose Vault via NodePort/Ingress with TLS.
- **CI.** No GitHub Actions. The just recipes are the contract.
- **Multi-region or geo-replication.**
- **Custom KCL Operator authoring.** KCL only renders manifests; runtime CR controllers are out of scope.
- **Real AlertManager receivers.** Routes exist; webhooks are placeholders.

## Things to know if you fork

- Bump every `https://github.com/lynjobseek-sys/cluster-platform-demo.git` reference to your fork. Two places: `pkg/common/config/teams.k` (`RepoURL`), and the four `repoURL` fields in `manifests/main.yaml` (`just build` will regenerate this from `RepoURL`).
- Pinned chart versions in `local-demo/manifests/*-app.yaml`: ArgoCD 7.6.12, kube-prometheus-stack 65.1.0, Vault 0.29.1, vault-secrets-operator 0.9.1. Bump them through the matching Application's `targetRevision`.
- `models/stacks/main.k` is the entry point. Reading it top-to-bottom tells you exactly what the platform owns.

## License

MIT.
