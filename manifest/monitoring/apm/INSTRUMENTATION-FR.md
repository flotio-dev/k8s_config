# Instrumentation applicative OpenTelemetry

Cette documentation explique comment instrumenter les applications Flotio pour obtenir du vrai APM: traces, metriques applicatives, correlation logs/traces, puis dashboards Grafana.

L'objectif est de garder les applications independantes du backend d'observabilite. Les apps envoient tout vers l'OpenTelemetry Collector, et le Collector route ensuite vers Tempo, Loki, Prometheus ou un autre backend.

## Architecture cible

```text
Applications Flotio
  -> OpenTelemetry SDK / auto-instrumentation
  -> OTLP gRPC ou HTTP
  -> otel-collector-gateway.monitoring.svc.cluster.local
  -> Tempo pour les traces
  -> Loki pour les logs
  -> Prometheus pour les metriques et spanmetrics
  -> Grafana pour l'exploration
```

Endpoint interne commun:

```text
http://otel-collector-gateway.monitoring.svc.cluster.local:4317
```

## Variables communes

Chaque application instrumentee devrait avoir au minimum:

```yaml
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
```

A adapter par environnement:

```yaml
- name: OTEL_RESOURCE_ATTRIBUTES
  value: deployment.environment=production,service.namespace=flotio
```

Le nom du service doit etre specifique a chaque app:

```yaml
- name: OTEL_SERVICE_NAME
  value: core-api
```

## Ordre recommande

1. Instrumenter `core-api`.
2. Verifier que les traces arrivent dans Tempo.
3. Verifier que les spanmetrics arrivent dans Prometheus.
4. Ajouter les logs structures correles aux traces.
5. Instrumenter `app`.
6. Instrumenter `website`.
7. Ajouter des spans metier sur les parcours importants.

## core-api

Priorite haute. C'est l'application la plus importante a instrumenter en premier, car elle concentre les appels API, la base de donnees, Redis, GitHub, S3/Garage et les jobs de build.

### Ce qu'il faut tracer

- Requetes HTTP entrantes.
- Latence par route.
- Codes d'erreur HTTP.
- Appels PostgreSQL.
- Appels Redis.
- Appels S3/Garage.
- Appels GitHub API.
- Reception des webhooks GitHub.
- Creation et suivi des jobs de build Android.

### Spans metier utiles

Exemples de noms:

```text
github.webhook.received
build.request.created
build.job.submitted
build.job.status_checked
artifact.uploaded
artifact.download_url.generated
auth.login
auth.refresh_token
```

Attributs utiles:

```text
flotio.build.id
flotio.project.id
flotio.user.id
flotio.github.repository
flotio.github.branch
flotio.artifact.type
```

Evite de mettre des secrets, tokens, mots de passe, cles privees ou URLs signees dans les spans.

### Si `core-api` est en Go

Libs typiques:

```bash
go get go.opentelemetry.io/otel
go get go.opentelemetry.io/otel/sdk
go get go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc
go get go.opentelemetry.io/otel/exporters/otlp/otlpmetric/otlpmetricgrpc
go get go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp
```

Pour PostgreSQL, choisir selon le driver utilise:

```bash
go get github.com/exaring/otelpgx
```

ou une instrumentation compatible avec `database/sql` si le projet utilise `database/sql`.

Pour Redis:

```bash
go get github.com/redis/go-redis/extra/redisotel/v9
```

### Resultat attendu dans Grafana

- Service `core-api` visible dans Tempo.
- Traces par endpoint HTTP.
- Spans DB/Redis imbriques dans les requetes.
- Metriques Prometheus generees:

```promql
apm:request_rate:5m{service_name="core-api"}
apm:error_ratio:5m{service_name="core-api"}
apm:duration_p95:5m{service_name="core-api"}
```

## app

Priorite moyenne. Cette app semble etre l'interface applicative principale. Si c'est une app Next.js ou Node.js cote serveur, elle peut produire des traces backend utiles.

### Ce qu'il faut tracer

- Rendu serveur si SSR.
- Appels a `core-api`.
- Pages ou routes lentes.
- Erreurs cote serveur.
- Actions utilisateur importantes.

### Variables recommandees

```yaml
- name: OTEL_SERVICE_NAME
  value: app
- name: OTEL_RESOURCE_ATTRIBUTES
  value: deployment.environment=production,service.namespace=flotio
```

### Si c'est Next.js / Node.js

Libs typiques:

```bash
npm install @opentelemetry/sdk-node
npm install @opentelemetry/auto-instrumentations-node
npm install @opentelemetry/exporter-trace-otlp-grpc
npm install @opentelemetry/exporter-metrics-otlp-grpc
```

Il faut initialiser OpenTelemetry au demarrage du serveur Node, avant le chargement du reste de l'application.

### Spans metier utiles

```text
app.page.render
app.api.request
app.auth.redirect
app.project.opened
app.build.triggered
```

## website

Priorite plus basse. Le site vitrine est utile a monitorer, mais il est moins critique que `core-api` et `app`.

### Ce qu'il faut tracer

- Rendu serveur si SSR.
- Appels a l'API.
- Erreurs serveur.
- Latence des pages publiques importantes.

### Variables recommandees

```yaml
- name: OTEL_SERVICE_NAME
  value: website
- name: OTEL_RESOURCE_ATTRIBUTES
  value: deployment.environment=production,service.namespace=flotio
```

### Frontend navigateur

Pour du tracing navigateur, il faut etre prudent:

- Ne jamais exposer de secret.
- Envoyer vers un endpoint public controle.
- Filtrer les attributs sensibles.
- Limiter l'echantillonnage.

Dans un premier temps, il vaut mieux instrumenter uniquement le serveur Next.js si le site en a un.

## Jobs de build Android

Priorite haute des que `core-api` est instrumentee.

Meme si les jobs sont lances dans Kubernetes, il faut pouvoir suivre le cycle complet:

```text
webhook recu
  -> build cree
  -> pod/job Kubernetes lance
  -> logs du build collectes
  -> artefact genere
  -> upload S3/Garage
  -> statut final
```

Spans recommandes:

```text
build.pipeline.started
build.kubernetes.job_created
build.kubernetes.pod_wait
build.flutter.build
build.artifact.upload
build.pipeline.completed
```

Attributs recommandes:

```text
flotio.build.id
flotio.build.status
flotio.github.repository
flotio.github.commit_sha
k8s.namespace.name
k8s.job.name
k8s.pod.name
```

## Logs applicatifs

Les logs doivent rester sur `stdout` / `stderr`. Le DaemonSet OpenTelemetry les collecte deja depuis Kubernetes.

Pour une bonne correlation logs/traces, les logs applicatifs devraient inclure:

```text
trace_id
span_id
service.name
deployment.environment
```

Format recommande:

```json
{
  "level": "info",
  "message": "build started",
  "trace_id": "...",
  "span_id": "...",
  "build_id": "...",
  "service": "core-api"
}
```

## Sampling

Au debut, garder un sampling simple:

```yaml
- name: OTEL_TRACES_SAMPLER
  value: parentbased_traceidratio
- name: OTEL_TRACES_SAMPLER_ARG
  value: "1.0"
```

Quand tout fonctionne, reduire en production:

```yaml
- name: OTEL_TRACES_SAMPLER_ARG
  value: "0.2"
```

Pour les erreurs ou les builds, l'ideal est de garder 100% des traces importantes.

## Securite

Ne jamais envoyer dans les traces ou logs:

- Tokens Kubernetes.
- Secrets JWT.
- Cles S3/Garage.
- Private keys GitHub App.
- Passwords PostgreSQL.
- Headers `Authorization`.
- Cookies de session.
- URLs signees temporaires.

Les attributs metier doivent etre utiles mais non sensibles.

## Checklist par application

Pour chaque app:

```text
[ ] Variables OTEL ajoutees au Deployment
[ ] SDK OpenTelemetry initialise au demarrage
[ ] Requetes HTTP entrantes tracees
[ ] Appels HTTP sortants traces
[ ] DB/Redis traces si utilises
[ ] Logs structures avec trace_id/span_id
[ ] Service visible dans Tempo
[ ] RED metrics visibles dans Prometheus
[ ] Dashboard Grafana cree
[ ] Alertes ajoutees seulement apres stabilisation
```

## Validation

Apres deploiement d'une app instrumentee:

```bash
kubectl -n monitoring logs deploy/otel-collector-gateway
```

Dans Grafana:

- Aller dans Explore.
- Selectionner Tempo.
- Chercher `service.name = core-api`.
- Ouvrir une trace.
- Verifier les spans HTTP, DB, Redis ou metier.

Dans Prometheus:

```promql
sum by (service_name) (rate(traces_spanmetrics_calls_total[5m]))
histogram_quantile(0.95, sum by (le, service_name) (rate(traces_spanmetrics_duration_bucket[5m])))
```

