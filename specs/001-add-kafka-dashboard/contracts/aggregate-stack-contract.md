# Contract: Aggregate Stack Kafka Wiring

## Purpose

Define how Kafka support is surfaced through `components/all` while remaining aligned with the standalone Kafka component contract.

## Aggregate Inputs

`components/all` adds a `kafka` object and, if public dashboard exposure is supported, a dedicated kind dashboard port mapping input or equivalent derived mapping.

### Aggregate Kafka Capabilities

- Feature enablement flag for Kafka in the aggregate stack.
- Kafka and dashboard namespace and release naming.
- Chart source and version overrides.
- Persistence controls for Kafka data.
- Optional dashboard exposure settings including NodePort and host-port behavior.

## Aggregate Outputs

`components/all` surfaces Kafka-related outputs alongside the existing platform outputs.

### Expected Output Additions

- `kafka_bootstrap_servers`
- `kafka_dashboard_url`
- `exposed_urls.kafka_dashboard`

## Alignment Rules

- Standalone and aggregate roots must expose the same operator-visible Kafka access details.
- If public dashboard exposure is enabled in `components/all`, the matching kind host-port mapping must remain synchronized with the cluster configuration.
- Aggregate defaults must not prevent Kafka from being deployed independently in its own component root.
