# Contract: Standalone Kafka Component

## Purpose

Define the operator-facing Terraform contract for the new standalone Kafka component root.

## Required Inputs

- `kubeconfig_path`: Path to the target cluster kubeconfig.
- `cluster_name`: kind cluster name used by provider context and documentation.

## Kafka Configuration Object

The standalone component exposes a single `kafka` object variable with explicit defaults for operator-tunable settings.

### Expected Capabilities

- Namespace selection for Kafka and dashboard resources.
- Kafka deployment identity settings such as release name and chart selection.
- Dashboard deployment identity settings such as release name and chart selection.
- Optional persistence controls for Kafka data.
- Optional public dashboard exposure controls including NodePort and host-port values.
- Replacement token support for controlled redeployments.

## Required Outputs

- `namespace`: Namespace where Kafka and the dashboard are deployed.
- `kafka_release_name`: Release identifier for the Kafka deployment.
- `dashboard_release_name`: Release identifier for the dashboard deployment.
- `bootstrap_servers`: In-cluster Kafka connection details for platform workloads.
- `dashboard_url`: Public dashboard URL when public exposure is enabled, otherwise null.
- `exposed_urls`: Consolidated output object for any public Kafka-related URLs.

## Behavioral Guarantees

- The component can be applied independently from `components/all`.
- The component fails clearly when the target cluster dependency is missing or unreachable.
- Re-running the same inputs produces an idempotent reconciliation rather than requiring manual cleanup.
- Public dashboard exposure is optional and does not change the in-cluster Kafka connection contract.
