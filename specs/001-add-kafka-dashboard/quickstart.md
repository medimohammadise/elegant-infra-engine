# Quickstart: Kafka Component and Dashboard

## Goal

Validate the planned operator workflow for deploying Kafka into an existing kind cluster and opening the Kafka dashboard.

## Prerequisites

- The kind cluster component has already been applied and its kubeconfig is available.
- Terraform CLI is installed locally.
- For any later plan or apply against roots that interact with the remote kind cluster, `DOCKER_HOST` and `DOCKER_CONFIG` are set as documented in the repository README.

## Standalone Component Workflow

1. Change into `components/kafka`.
2. Copy `terraform.tfvars.example` to `terraform.tfvars`.
3. Populate the kubeconfig path, cluster name, and any Kafka or dashboard overrides.
4. Run `terraform init`.
5. Run `terraform fmt -check`.
6. Run `terraform validate`.
7. Run `terraform plan`.
8. Confirm the planned outputs include Kafka connection details and, when enabled, a dashboard URL.

## Aggregate Stack Workflow

1. Change into `components/all`.
2. Update the aggregate configuration to enable Kafka and set any dashboard exposure values.
3. Run `terraform init`.
4. Run `terraform fmt -check`.
5. Run `terraform validate`.
6. Run `terraform plan`.
7. Confirm the aggregate outputs include Kafka-related access details and that any dashboard host-port mapping remains aligned with the kind cluster settings.

## Validation Focus

- Kafka can be planned without deploying unrelated new components.
- The dashboard is included in the Kafka capability and follows the documented entry point.
- Standalone and aggregate plans expose consistent operator-facing Kafka outputs.
- Re-running plan with unchanged inputs yields no unintended drift beyond expected provider noise.
