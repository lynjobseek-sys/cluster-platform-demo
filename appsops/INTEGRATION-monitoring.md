# Phase 7 monitoring integration

This document captures the wire-up steps the monitoring layer needs from
files I do not own (managed.k, main.yaml, bootstrap.sh, README, justfile).

## ManagedProjects

`pkg/common/config/managed.k` should become:

```kcl
ManagedProjects: [str] = ["argocd", "monitoring"]
```

After the change, regenerate `manifests/main.yaml` (`just build` or the
equivalent KCL command). The new entry produces a second
`monitoring-onboarding` ApplicationSet that walks
`appsops/*/monitoring/*/*` and emits one Application per team per env
(6 Applications total: frontend/backend/data x local/staging).

The existing per-team `AppProject` already permits the rules and dashboard
ConfigMap because they land in `<team>-<env>` namespaces, and the project's
`namespaceResourceWhitelist` is `{group: "*", kind: "*"}`.

## bootstrap.sh additions

Insert after step 4 (the `kctl apply -f ../manifests/main.yaml` line) and
before the admin password echo:

```bash
# 5. Install kube-prometheus-stack on the hub. This is platform infra, not
#    a team app, so it is a hand written ArgoCD Application rather than an
#    ApplicationSet output. Per-team PrometheusRules and dashboards are
#    delivered separately by the monitoring-onboarding ApplicationSet.
kctl apply -f manifests/kube-prometheus-stack-app.yaml

kctl -n "$ARGOCD_NS" wait --for=condition=Available=true \
  --timeout=10m application/kube-prometheus-stack || true

# CRDs and Prometheus/Grafana StatefulSets take a minute on first install.
kctl -n monitoring rollout status statefulset/prometheus-kube-prometheus-stack-prometheus --timeout 5m || true
kctl -n monitoring rollout status statefulset/alertmanager-kube-prometheus-stack-alertmanager --timeout 5m || true
kctl -n monitoring rollout status deployment/kube-prometheus-stack-grafana --timeout 5m || true
```

The Application has `CreateNamespace=true` so an explicit
`kubectl create namespace monitoring` is not required.

## Verification

Port-forward (run each in its own shell):

```bash
# Prometheus
kubectl --context kind-hub -n monitoring port-forward svc/kube-prometheus-stack-prometheus 9090:9090

# AlertManager
kubectl --context kind-hub -n monitoring port-forward svc/kube-prometheus-stack-alertmanager 9093:9093

# Grafana
kubectl --context kind-hub -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80
```

Default Grafana password (username `admin`):

```bash
kubectl --context kind-hub -n monitoring get secret kube-prometheus-stack-grafana \
  -o jsonpath='{.data.admin-password}' | base64 -d ; echo
```

Smoke checks once the pods are ready:

- Prometheus UI -> Status -> Rules: should list `frontend.rules`,
  `backend.rules`, `data.rules`.
- Grafana UI -> Dashboards: should list `frontend overview`,
  `backend overview`, `data overview` (auto-discovered by the sidecar from
  ConfigMaps labeled `grafana_dashboard=1`).
- AlertManager UI -> Status -> Config: routes block should show the four
  receivers (default, frontend-receiver, backend-receiver, data-receiver).

## Versions pinned

- kube-prometheus-stack chart: **65.1.0**
  (ships prometheus-operator v0.77.1, Grafana 11.2.x via the grafana 8.5.x
  subchart, kube-state-metrics, node-exporter)
- Helm repo: `https://prometheus-community.github.io/helm-charts`

## Why these defaults

- `kubeControllerManager`, `kubeScheduler`, `kubeProxy`, `kubeEtcd` are
  all disabled because kind collapses them into a single static-pod
  control plane that the operator's default ServiceMonitors cannot scrape.
  Leaving them enabled produces a permanent KubeControllerManagerDown /
  KubeSchedulerDown / KubeProxyDown / etcdMembersDown alert storm that
  drowns out real signal.
- Prometheus operator selectors are widened
  (`ruleNamespaceSelector: {}`, `ruleSelector: {}`,
  `serviceMonitorNamespaceSelector: {}`, `serviceMonitorSelector: {}`) so
  per-team rules in `<team>-<env>` namespaces are picked up without any
  per-team helm values change.
- Grafana sidecar `searchNamespace: ALL` lets dashboard ConfigMaps live
  next to their rules in the team namespaces.
- AlertManager receivers are placeholders (no webhooks). Wiring real
  Slack/PagerDuty endpoints is a deploy-time concern, not a demo concern.
