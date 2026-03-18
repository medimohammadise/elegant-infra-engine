# BlitzInfra

This repository contains the infrastructure configuration for provisioning a Docker registry, Postgres, a UI, and a 5-node remote Kubernetes (`kind`) cluster over SSH, along with a required namespace using Terraform.

## Prerequisites

- SSH access to the remote host (e.g. `myserver`) where Docker is running.
- `docker`, `ssh`, and `scp` installed locally.
- `terraform` CLI installed locally.
- passwordless SSH setup to the remote host (e.g., using `ssh-copy-id myserver`).

## Setup

1. Move into the infra directory:

```bash
cd docker-k8s-iac
```

2. Create your terraform variables file from the example:

```bash
cp terraform.tfvars.example terraform.tfvars
```

3. Update `terraform.tfvars` with the values for your server:

```hcl
ssh_context_host      = "myserver"
api_server_host       = "myserver"
registry_bind_address = "0.0.0.0"
ui_bind_address       = "127.0.0.1"
registry_title        = "Remote Docker Registry"
postgres_bind_address = "0.0.0.0"
postgres_port         = 5432
postgres_db_name      = "blitzinfra"
postgres_user         = "blitzinfra"
postgres_password     = "change-me"
cluster_name          = "blitzinfra"
worker_count          = 4
kind_node_image       = "kindest/node:v1.30.0@sha256:047357ac0cfea04663786a612ba1eaba9702bef25227a794b52890dd8bcd692e"
kube_namespace        = "blitzpay-dev"
recreate_revision     = ""
```

Set `postgres_password` to a real secret before you apply.

## Provisioning

Initialize Terraform to download required providers:

```bash
terraform init
```

Review the execution plan:

```bash
mkdir -p /tmp/docker-empty-config
printf '{}' > /tmp/docker-empty-config/config.json
DOCKER_CONFIG=/tmp/docker-empty-config DOCKER_HOST=ssh://myserver terraform plan
```

Apply the changes to provision the infrastructure:

```bash
DOCKER_CONFIG=/tmp/docker-empty-config DOCKER_HOST=ssh://myserver terraform apply
```

> **Note**: `DOCKER_HOST` is required so that the `kind` CLI plugin inside the provider can communicate with the remote Docker daemon natively. `DOCKER_CONFIG=/tmp/docker-empty-config` forces the local Docker CLI to use a clean config, which avoids local credential-helper issues such as missing `docker-credential-desktop`.

## Force Recreate

If you need Terraform to tear down and recreate all managed infrastructure resources, change `recreate_revision` to a new value in `terraform.tfvars` and apply again:

```hcl
recreate_revision = "rebuild-2026-03-17-1"
```

Terraform will treat that token change as a one-time full replacement trigger for the Docker resources, the kind cluster, and the Kubernetes resources. Leave the value unchanged during normal applies.

## What it Does

When you apply the Terraform configuration, it systematically modules through:
1. `pre-k8s`: Creates PostgreSQL, the Docker Registry, and the Registry UI natively with Docker containers on the remote host.
2. `kind-cluster`: Provisions a 5-node `kind` cluster on the remote host and fetches the kubeconfig.
3. `k8s-resources`: Uses the cluster output to set up the `blitzpay-dev` namespace.
