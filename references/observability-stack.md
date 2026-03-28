# Observability Stack Reference

This document explains the observability stack deployed in BlitzInfra: what each component does, how they connect, and how data flows through the system.

---

## Components at a Glance

| Component | Role | Port |
|-----------|------|------|
| **Grafana Alloy** | Collector — gathers logs and receives traces, ships to backends | 4317 (OTLP gRPC), 4318 (OTLP HTTP) |
| **Loki** | Log storage and query engine | 3100 (internal), gateway on 80 |
| **Tempo** | Distributed trace storage and query engine | 3200 (query), 4317 (OTLP ingest) |
| **Prometheus** | Metrics scraping and storage | 9090 |
| **Grafana** | Dashboards and unified UI for all backends | 3000 |

---

## How They Work Together

```mermaid
flowchart TD
    subgraph Apps["Your Applications / Kubernetes Pods"]
        A1[Pod A]
        A2[Pod B]
        A3[Pod C]
    end

    subgraph Alloy["Grafana Alloy (DaemonSet)"]
        LC[Log Collector\nloki.source.kubernetes]
        OR[OTLP Receiver\notelcol.receiver.otlp\n:4317 / :4318]
    end

    subgraph Backends["Backends"]
        LK[Loki\nLog Storage]
        TM[Tempo\nTrace Storage]
        PR[Prometheus\nMetrics Storage]
    end

    GF[Grafana\nDashboards :3000]

    A1 -->|stdout / stderr| LC
    A2 -->|stdout / stderr| LC
    A3 -->|stdout / stderr| LC

    A1 -->|OTLP traces| OR
    A2 -->|OTLP traces| OR

    PR -->|scrapes /metrics| A1
    PR -->|scrapes /metrics| A2
    PR -->|scrapes /metrics| A3

    LC -->|push logs| LK
    OR -->|forward traces| TM

    GF -->|query logs| LK
    GF -->|query traces| TM
    GF -->|query metrics| PR
```

---

## Grafana Alloy

Alloy is the **collector** — it runs as a DaemonSet (one pod per node) and is responsible for gathering telemetry and shipping it to the right backend.

In this stack Alloy does two things:

1. **Log collection**: watches Kubernetes pod logs via the API and forwards them to Loki
2. **Trace ingestion**: listens for OTLP traces from your apps and forwards them to Tempo

```mermaid
flowchart LR
    subgraph Alloy["Alloy Pod (per node)"]
        D[discovery.kubernetes\nfind all pods]
        R[discovery.relabel\nadd namespace / pod / container labels]
        LS[loki.source.kubernetes\nstream pod logs]
        LW[loki.write\npush to Loki gateway]

        OR[otelcol.receiver.otlp\nlisten :4317 & :4318]
        OE[otelcol.exporter.otlp\nforward to Tempo :4317]

        D --> R --> LS --> LW
        OR --> OE
    end
```

Alloy's configuration is written in **River** (Alloy's own DSL), defined in the Helm chart as a ConfigMap. Each block declares a component with inputs and outputs — data flows like a pipeline.

---

## Loki

Loki is the **log backend**. Unlike traditional log systems (e.g. Elasticsearch), Loki does **not** index log content. It only indexes the **labels** attached to log streams (namespace, pod, container, app). The actual log lines are stored compressed in chunks.

This makes Loki cheap to run but means you query by label first, then filter by content.

```mermaid
flowchart LR
    subgraph Loki["Loki (SingleBinary mode)"]
        GW[Gateway\nnginx :80]
        IN[Ingester\nreceive & buffer logs]
        ST[Filesystem Storage\n/var/loki]
        QU[Querier\nexecute LogQL]

        GW --> IN
        IN --> ST
        GW --> QU
        QU --> ST
    end

    Alloy -->|POST /loki/api/v1/push| GW
    Grafana -->|LogQL queries| GW
```

**LogQL** is Loki's query language. Example:

```logql
{namespace="backstage"} |= "error"
```

This means: show me all log lines from the `backstage` namespace that contain the word "error".

---

## Tempo

Tempo is the **trace backend**. A trace represents a single request as it travels through multiple services. Each trace is made up of **spans** — individual units of work with a start time, duration, and metadata.

```mermaid
flowchart LR
    subgraph Trace["Single Request Trace"]
        S1[Span: API Gateway\n0ms → 120ms]
        S2[Span: Auth Service\n5ms → 30ms]
        S3[Span: Database query\n35ms → 80ms]

        S1 --> S2
        S1 --> S3
    end
```

```mermaid
flowchart LR
    subgraph Tempo["Tempo"]
        IN[OTLP Receiver\n:4317]
        ST[Local Storage\n/var/tempo]
        QU[Query API\n:3200]

        IN --> ST
        QU --> ST
    end

    Alloy -->|OTLP gRPC| IN
    Grafana -->|TraceQL / trace ID lookup| QU
```

Your apps send traces using the **OpenTelemetry** SDK. Alloy receives them on port 4317 (gRPC) or 4318 (HTTP) and forwards them to Tempo.

---

## Prometheus

Prometheus is the **metrics backend**. It works by **pulling** (scraping) metrics from your apps and services on a schedule — your app exposes a `/metrics` HTTP endpoint and Prometheus calls it every 15–60 seconds.

```mermaid
flowchart LR
    subgraph Prometheus["Prometheus"]
        SC[Scraper\npulls /metrics every 15s]
        DB[Time-Series DB\nlocal storage]
        QU[Query API\n:9090]

        SC --> DB
        QU --> DB
    end

    SC -->|GET /metrics| App1[Pod A /metrics]
    SC -->|GET /metrics| App2[Pod B /metrics]
    SC -->|GET /metrics| NE[node-exporter\nhost metrics]
    SC -->|GET /metrics| KSM[kube-state-metrics\nk8s object metrics]

    Grafana -->|PromQL| QU
```

**PromQL** is Prometheus's query language. Example:

```promql
rate(http_requests_total{namespace="backstage"}[5m])
```

This means: show me the per-second request rate for Backstage averaged over the last 5 minutes.

---

## Grafana

Grafana is the **unified UI**. It does not store any data itself — it connects to Loki, Tempo, and Prometheus as datasources and lets you query and visualize everything in one place.

```mermaid
flowchart TD
    subgraph Grafana["Grafana :3000"]
        EX[Explore\nad-hoc queries]
        DA[Dashboards\npre-built views]
        AL[Alerting\nthreshold rules]
    end

    subgraph Datasources["Configured Datasources"]
        DS_L[Loki\nLogQL]
        DS_T[Tempo\nTraceQL]
        DS_P[Prometheus\nPromQL]
    end

    EX --> DS_L
    EX --> DS_T
    EX --> DS_P
    DA --> DS_L
    DA --> DS_P
    AL --> DS_P
```

### Navigating Grafana

- **Explore** (compass icon): free-form querying — pick a datasource, write a query, see results
- **Dashboards** (four squares): pre-built panels for Kubernetes, Loki, etc.
- **Alerting** (bell icon): define rules that fire when a metric crosses a threshold

### Trace → Log correlation

Because Alloy attaches the same labels (namespace, pod, container) to both logs and traces, Grafana can jump from a slow trace directly to the logs from that pod at that exact timestamp. This is wired up via the `tracesToLogs` link in the Tempo datasource configuration.

---

## Data Flow Summary

```mermaid
sequenceDiagram
    participant App as Your App
    participant Alloy as Grafana Alloy
    participant Loki as Loki
    participant Tempo as Tempo
    participant Prom as Prometheus
    participant Graf as Grafana

    App->>Alloy: stdout/stderr logs (via k8s API)
    App->>Alloy: OTLP trace spans (:4317)
    Alloy->>Loki: push log streams
    Alloy->>Tempo: forward trace spans

    Prom->>App: scrape /metrics (pull)
    Prom->>Prom: store time series

    Graf->>Loki: LogQL query
    Graf->>Tempo: TraceQL / trace ID
    Graf->>Prom: PromQL query

    Loki-->>Graf: log lines
    Tempo-->>Graf: trace spans
    Prom-->>Graf: metric series
```
