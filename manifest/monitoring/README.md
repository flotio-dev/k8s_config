# Monitoring

This directory defines the observability stack for the infra-first rollout.

## Target Architecture

Phase 1 keeps the scope infra-only:

- Grafana for dashboards.
- Prometheus via `kube-prometheus-stack` for Kubernetes, nodes, Proxmox exporters, and alerting.
- OpenTelemetry Collector gateway as the stable OTLP entry point for future metrics, traces, and logs.
- Proxmox node metrics via `node_exporter`.
- Proxmox cluster, VM, storage, and guest metrics via `prometheus-pve-exporter`.

The important design choice is to make applications and future agents talk to OpenTelemetry, not directly to a vendor backend. Prometheus/Grafana can be replaced or extended later without changing every service.

## Rollout Order

1. Apply `base/namespace.yaml`.
2. Install `kube-prometheus-stack` in the `monitoring` namespace with `helm-values/kube-prometheus-stack-values.yaml`.
3. Apply `opentelemetry/otel-collector-gateway.yaml`.
4. Install `node_exporter` on Proxmox hosts and VMs that must expose host metrics.
5. Apply `proxmox/proxmox-node-exporter.yaml`.
6. Create a real Proxmox API token secret outside Git, then apply `proxmox/pve-exporter.yaml`.

```bash
kubectl apply -f manifest/monitoring/base/namespace.yaml

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  -f manifest/monitoring/helm-values/kube-prometheus-stack-values.yaml

helm repo add grafana https://grafana.github.io/helm-charts
helm upgrade --install loki grafana/loki \
  --namespace monitoring \
  -f manifest/monitoring/helm-values/loki-values.yaml

helm upgrade --install tempo grafana/tempo \
  --namespace monitoring \
  -f manifest/monitoring/helm-values/tempo-values.yaml

kubectl apply -f manifest/monitoring/opentelemetry/otel-collector-gateway.yaml
kubectl apply -f manifest/monitoring/logs/otel-collector-logs-daemonset.yaml
kubectl apply -f manifest/monitoring/apm/prometheus-rules.yaml
```

## Backend Strategy

Current backend:

- Metrics: Prometheus.
- Dashboards: Grafana.
- Logs: Loki, fed through the OpenTelemetry Collector gateway.
- Traces: Tempo, fed through the OpenTelemetry Collector gateway.
- APM: OpenTelemetry span metrics exported to Prometheus.

Future backends can be added by changing the exporters in `opentelemetry/otel-collector-gateway.yaml`:

- Tempo, Jaeger, Grafana Cloud, Honeycomb, Datadog, or another OTLP-compatible backend for traces.
- Loki or another log backend for logs.
- Prometheus remote write, Mimir, VictoriaMetrics, or another metrics backend for long-term metrics.

## Secrets

Do not commit real API tokens or passwords. The checked-in `pve-exporter-secret.example.yaml` is only a template. In production, create the secret with ExternalSecrets, SealedSecrets, SOPS, or a manual command:

```bash
kubectl -n monitoring create secret generic pve-exporter --from-file=pve.yml
```

## Phase 2

Add logs after the infra dashboards are stable:

- Install Loki with `helm-values/loki-values.yaml`.
- Deploy `logs/otel-collector-logs-daemonset.yaml` on each node for container logs.
- Normalize labels: `cluster`, `namespace`, `pod`, `container`, `app`, `environment`.

The log pipeline is:

```text
Kubernetes container stdout/stderr
  -> OpenTelemetry Collector DaemonSet filelog receiver
  -> OpenTelemetry Collector gateway
  -> Loki OTLP endpoint
  -> Grafana Loki datasource
```

## Phase 3

Add application observability:

- Install Tempo with `helm-values/tempo-values.yaml`.
- Instrument backend services with OTLP metrics and traces.
- Send traces to `otel-collector-gateway.monitoring.svc:4317` or `:4318`.
- Add RED dashboards: request rate, errors, duration.
- Apply `apm/prometheus-rules.yaml` to get reusable RED recording rules.
- Add service-level alerts only after basic infra alerts are clean.

The current `grafana/tempo` chart is simple and fits this cluster size, but Helm marks it as deprecated. For a larger or long-lived production setup, migrate this values file to `tempo-distributed`.
