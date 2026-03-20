# BlitzInfra

This repository contains the infrastructure configuration for provisioning a Docker registry, Postgres, a UI, and a 5-node remote Kubernetes (`kind`) cluster over SSH, along with a required namespace using Terraform.


## GitHub Release Notes Automation

This repository includes a caller workflow at `.github/workflows/release-notes-on-main-merge.yml` that invokes the reusable Release Notes workflow from `medimohammadise/elegant-ci-cd-pipeline` on branch `001-release-notes-workflow`.

When a pull request is merged into `main`, this workflow forwards the merge commit range (`base_sha` and `head_sha`) to that reusable workflow.

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
enable_backstage      = false
backstage_namespace   = "backstage"
backstage_chart_version = "2.6.3"
backstage_image_tag   = "1.30.2"
backstage_base_url    = "http://myserver:7007"
expose_backstage_public = true
backstage_node_port   = 32007
backstage_host_port   = 7007
enable_k8s_dashboard  = false
dashboard_namespace   = "kubernetes-dashboard"
k8s_dashboard_chart_url = "https://github.com/kubernetes-retired/dashboard/releases/download/kubernetes-dashboard-7.14.0/kubernetes-dashboard-7.14.0.tgz"
expose_dashboard_public = false
dashboard_node_port   = 32443
dashboard_host_port   = 8443
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

## Optional: Kubernetes Dashboard

You can enable Kubernetes Dashboard installation through Helm by setting:

```hcl
enable_k8s_dashboard = true
dashboard_namespace  = "kubernetes-dashboard"
```

The Terraform module installs the chart from the Kubernetes Dashboard OCI registry on GHCR (`oci://ghcr.io/kubernetes-dashboard/charts`) to avoid dependency on the GitHub Pages chart index URL.
The Terraform module installs the chart from the published GitHub release archive by default because GHCR anonymous pulls can return `403 denied` for this chart. You can override `k8s_dashboard_chart_url` if you want to pin a different release.

After apply completes, access the dashboard from your local machine with:

```bash
kubectl --kubeconfig ./docker-k8s-iac/blitzinfra-kubeconfig -n kubernetes-dashboard port-forward svc/kubernetes-dashboard-kong-proxy 8443:443
```

Then open:

```text
https://localhost:8443
```

If you want Terraform to expose the dashboard on the remote host directly, set:

```hcl
enable_k8s_dashboard    = true
expose_dashboard_public = true
dashboard_host_port     = 8443
create_dashboard_admin_user = true
dashboard_admin_user_name   = "admin-user"
```

That changes the Dashboard service to a `NodePort` and adds a `kind` host-port mapping on the control-plane node. After apply, the URL will be:

```text
https://<api_server_host>:8443
```

Changing `expose_dashboard_public`, `dashboard_node_port`, or `dashboard_host_port` updates the `kind` cluster configuration and may require the cluster to be recreated.

When `create_dashboard_admin_user = true`, Terraform also creates a Dashboard login service account with a `ClusterRoleBinding` to `cluster-admin`. This is convenient for local or dev environments, but it grants full cluster access through the Dashboard.

After apply completes, generate a login token with:

```bash
kubectl --kubeconfig ./docker-k8s-iac/blitzinfra-kubeconfig -n kubernetes-dashboard create token admin-user
```

You can request a specific duration, for example:

```bash
kubectl --kubeconfig ./docker-k8s-iac/blitzinfra-kubeconfig -n kubernetes-dashboard create token admin-user --duration=24h
```

These tokens are short-lived service account tokens. If you omit `--duration`, the token lifetime is determined by the Kubernetes API server and is typically about one hour on modern clusters.

## Optional: Backstage

You can enable Backstage installation through the official Helm chart by setting:

```hcl
enable_backstage          = true
backstage_namespace       = "backstage"
backstage_chart_version   = "2.6.3"
backstage_image_tag       = "1.30.2"
backstage_base_url        = "https://<api_server_host>:7007"
expose_backstage_public   = true
```

By default, Terraform installs the official `backstage/backstage` chart and pins the Backstage application image to `1.30.2` instead of floating on `latest`. That keeps the deployed app compatible with the charted configuration and avoids frontend regressions caused by upstream image drift. The Backstage pod still points at the existing PostgreSQL container provisioned by `pre-k8s`, reusing `postgres_db_name`, `postgres_user`, and `postgres_password`, and reaches that Docker-host PostgreSQL instance through `host.docker.internal`. Terraform also enables Backstage HTTPS with a generated self-signed certificate on port `7007`, which matches the security headers emitted by this image. This remains an upstream demo image suitable for bootstrap and evaluation, not a production Backstage build.

The Terraform module also post-renders the Backstage Deployment to use the Kubernetes `Recreate` strategy. That avoids overlapping old and new Backstage pods during upgrades, which can otherwise leave Backstage database migrations locked against the shared PostgreSQL instance.

For remote-host access, Terraform exposes Backstage on the kind control-plane host port and the URL will be:

```text
https://<api_server_host>:7007
```

If you prefer local access through `kubectl port-forward`, set:

```hcl
expose_backstage_public = false
backstage_base_url      = "https://localhost:7007"
```

Then port-forward the service after apply completes:

```bash
kubectl --kubeconfig ./docker-k8s-iac/blitzinfra-kubeconfig -n backstage port-forward svc/backstage 7007:7007
```

Then open:

```text
https://localhost:7007
```

Because the chart uses a generated self-signed certificate for Backstage, your browser will show a certificate warning the first time you open the URL. Accept the warning to continue in dev environments.

Changing `expose_backstage_public`, `backstage_node_port`, or `backstage_host_port` updates the `kind` cluster configuration and may require the cluster to be recreated.

## What it Does

When you apply the Terraform configuration, it systematically modules through:
1. `pre-k8s`: Creates PostgreSQL, the Docker Registry, and the Registry UI natively with Docker containers on the remote host.
2. `kind-cluster`: Provisions a 5-node `kind` cluster on the remote host and fetches the kubeconfig.
3. `k8s-resources`: Uses the cluster output to set up the `blitzpay-dev` namespace and optionally install Backstage and Kubernetes Dashboard.
