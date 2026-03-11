# BlitzInfra

This repository contains the infrastructure configuration for provisioning a Docker registry, a UI, and a 5-node remote Kubernetes (`kind`) cluster over SSH, along with required namespaces and the Kubernetes Dashboard using Terraform.

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
cluster_name          = "blitzinfra"
worker_count          = 4
kube_namespace        = "blitzpay-dev"
```

## Provisioning

Initialize Terraform to download required providers:

```bash
terraform init
```

Review the execution plan:

```bash
DOCKER_HOST=ssh://myserver terraform plan
```

Apply the changes to provision the infrastructure:

```bash
DOCKER_HOST=ssh://myserver terraform apply
```

> **Note**: The `DOCKER_HOST` environment variable is required so that the `kind` CLI plugin inside the provider can communicate with the remote Docker daemon natively to build the cluster.

## What it Does

When you apply the Terraform configuration, it systematically modules through:
1. `pre-k8s`: Creates the Docker Registry and Registry UI natively with Docker containers on the remote host.
2. `kind-cluster`: Provisions a 5-node `kind` cluster on the remote host and fetches the kubeconfig.
3. `k8s-resources`: Uses the cluster output to set up the `blitzpay-dev` namespace and deploys the `kubernetes-dashboard` via Helm.

## Access Kubernetes Dashboard

The dashboard is installed via Helm automatically. Start a local proxy:

```bash
kubectl port-forward svc/kubernetes-dashboard -n kubernetes-dashboard 8443:443
```

Then open `https://localhost:8443` and create a login token with:

```bash
kubectl -n kubernetes-dashboard create token admin-user
```

