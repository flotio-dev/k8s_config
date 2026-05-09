# APM

Phase 3 adds tracing and basic APM.

French application-by-application instrumentation guide: `INSTRUMENTATION-FR.md`.

## Pipeline

```text
Instrumented applications
  -> OTLP gRPC/HTTP
  -> OpenTelemetry Collector gateway
  -> Tempo for traces
  -> spanmetrics connector
  -> Prometheus for RED metrics
  -> Grafana dashboards
```

## Application Contract

Applications should send telemetry to the in-cluster OpenTelemetry gateway:

```text
otel-collector-gateway.monitoring.svc.cluster.local:4317
```

Minimum environment variables:

```yaml
- name: OTEL_SERVICE_NAME
  value: core-api
- name: OTEL_EXPORTER_OTLP_ENDPOINT
  value: http://otel-collector-gateway.monitoring.svc.cluster.local:4317
- name: OTEL_EXPORTER_OTLP_PROTOCOL
  value: grpc
- name: OTEL_TRACES_EXPORTER
  value: otlp
- name: OTEL_METRICS_EXPORTER
  value: otlp
- name: OTEL_LOGS_EXPORTER
  value: otlp
- name: OTEL_RESOURCE_ATTRIBUTES
  value: deployment.environment=production,service.namespace=flotio
```

For Go services, these variables are useful once the application initializes the OpenTelemetry SDK. For Node.js services, they are useful with OpenTelemetry SDK or auto-instrumentation packages.

## What Grafana Should Show

After app instrumentation:

- Tempo datasource can search traces by service name.
- Logs can be correlated manually by Kubernetes labels first.
- Prometheus receives generated span metrics from the OTel `spanmetrics` connector.

Useful first queries:

```promql
sum by (service_name) (rate(traces_spanmetrics_calls_total[5m]))
sum by (service_name, status_code) (rate(traces_spanmetrics_calls_total[5m]))
histogram_quantile(0.95, sum by (le, service_name) (rate(traces_spanmetrics_duration_bucket[5m])))
```
