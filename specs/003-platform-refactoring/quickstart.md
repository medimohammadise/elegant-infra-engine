# Quickstart: Platform Refactoring

**Feature**: 003-platform-refactoring
**Date**: 2026-03-30

## Prerequisites

- Terraform >= 1.0 installed
- SSH access to remote Docker host (`myserver`)
- Docker CLI installed locally
- `kind` CLI installed locally

## Environment Setup

```bash
mkdir -p /tmp/docker-empty-config && printf '{}' > /tmp/docker-empty-config/config.json
export DOCKER_CONFIG=/tmp/docker-empty-config
export DOCKER_HOST=ssh://myserver
```

## Step 1: Deploy Infrastructure

```bash
cd components/infra
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply
```

Infra publishes kubeconfig paths, PostgreSQL connection details, the Docker SSH context, and the kind host-port mappings. App roots consume those outputs through `terraform_remote_state`, so make sure the infra apply has succeeded before moving on.

## Step 2: Deploy Applications

Each application is a standalone Terraform root. Apply them in any order that respects runtime dependencies (e.g., Keycloak before Backstage).

```bash
cd ../keycloak
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply

cd ../backstage
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply

cd ../kafka
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply

cd ../headlamp
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply

cd ../observability
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply
```

Each app root reads `components/infra/terraform.tfstate` to pick up `kubeconfig_path`, PostgreSQL host/port, and API host details before provisioning its Kubernetes workloads and any Docker proxies.

## Check URLs

```bash
terraform -chdir=components/backstage output exposed_urls
terraform -chdir=components/headlamp output exposed_urls
terraform -chdir=components/kafka output exposed_urls
terraform -chdir=components/keycloak output exposed_urls
terraform -chdir=components/observability output exposed_urls
```

## Destroying

- Destroy a single app root without touching infra: `terraform -chdir=components/<app> destroy`.
- Destroy infrastructure only after all apps have been removed: `terraform -chdir=components/infra destroy`.

## Adding a New Component

Follow the standardized component contract in [contracts/component-contract.md](./contracts/component-contract.md): create a new directory under `components/`, add a `terraform_remote_state` data source for `components/infra`, wire the module inputs, expose `namespace` + `exposed_urls`, and keep the new root self-contained.
