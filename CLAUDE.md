# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Does

Provisions a full developer platform on a **remote Docker host** (`myserver`) using Terraform. The stack includes: Docker registry, PostgreSQL, a `kind` Kubernetes cluster, Backstage (with Keycloak oauth2-proxy), Headlamp, Kafka + Kafka UI, Keycloak, Dependency-Track, and an observability stack (Grafana, Loki, Tempo, Prometheus).

## Repository Layout

```
components/   Deployable Terraform roots (each has its own state)
modules/      Reusable Terraform modules (no providers, no state)
scripts/      Helper scripts (post-render hooks, health checks, cluster manager)
vendor/       Vendored Helm charts (e.g. Headlamp 0.40.1)
specs/        Infrastructure specs/documentation
```

`components/all` orchestrates the full stack from a single root. All other `components/*` are standalone roots for independent lifecycle management.

## Core Architecture Patterns

### Two-Layer Terraform Pattern
- `modules/` contain reusable logic with no provider config and no `terraform {}` backend blocks.
- `components/` are deployable roots: they declare providers, call modules, and hold `terraform.tfstate`.
- Never put one-off resources directly into multiple components — extract to a module instead.

### Remote Docker + kind
All Docker-backed resources (registry, postgres, socat proxy containers, kind cluster itself) run on the **remote Docker host** via SSH. Any root that touches Docker or kind requires:

```bash
mkdir -p /tmp/docker-empty-config && printf '{}' > /tmp/docker-empty-config/config.json
export DOCKER_CONFIG=/tmp/docker-empty-config
export DOCKER_HOST=ssh://myserver
```

`DOCKER_CONFIG` is needed to avoid local credential-helper issues. `DOCKER_HOST` is required because the `tehcyx/kind` provider shells out to the local `kind` CLI which must reach the remote daemon.

### Port Exposure Model
kind host-port mappings are **baked in at cluster creation** — adding a new NodePort service does not require cluster recreation. Instead, use a Docker socat proxy container on the remote host:

```hcl
resource "docker_container" "proxy" {
  image   = docker_image.socat[0].image_id
  name    = "${var.cluster_name}-myservice-proxy"
  restart = "unless-stopped"
  command = ["tcp-listen:8080,fork,reuseaddr", "tcp-connect:${var.cluster_name}-control-plane:${var.node_port}"]
  networks_advanced { name = "kind" }
  ports { internal = 8080; external = var.host_port; ip = "0.0.0.0" }
}
```

**Do not use `modules/kafka-ui-proxy`** for new services — it has a lifecycle bug where its `container_exists` data source causes Terraform to destroy the container it just created on the next apply. Use direct `docker_image` + `docker_container` resources instead (see `components/dependencytrack/main.tf` as the correct pattern).

### Backstage Authentication
Backstage uses oauth2-proxy → Keycloak exclusively. Guest mode is not supported. `base_url` must use `https://`. Required variables in `terraform.tfvars`:

```hcl
backstage_keycloak_base_url          = "http://myserver:8080"
backstage_keycloak_realm             = "backstage"
backstage_keycloak_client_id         = "backstage"
backstage_keycloak_client_secret     = "<real secret from Keycloak>"
backstage_oauth2_proxy_cookie_secret = "<base64 random>"
```

The client secret must be obtained from Keycloak admin CLI:
```bash
kubectl -n keycloak exec <pod> -- /opt/keycloak/bin/kcadm.sh get clients -r backstage \
  --server http://localhost:8080 --realm master --user admin --password <pw> \
  --fields "clientId,secret"
```

## Common Commands

### Validate / Format
```bash
terraform -chdir=components/<name> fmt -check
terraform -chdir=components/<name> validate
terraform -chdir=components/<name> plan
```

### Apply a Component
```bash
DOCKER_CONFIG=/tmp/docker-empty-config DOCKER_HOST=ssh://myserver \
  terraform -chdir=components/<name> apply
```

### Refresh Kubeconfig (after reboot or cluster recreation)
```bash
KIND_CLUSTER_NAME=blitz-cluster \
KIND_KUBECONFIG_PATH=components/kubeconfigs/blitzinfra-kubeconfig \
KIND_API_SERVER_HOST=myserver \
KIND_API_SERVER_PORT=6443 \
DOCKER_HOST=ssh://myserver \
scripts/kind-cluster-manager.sh refresh-kubeconfig
```

### Generate Headlamp Token (Kubernetes 1.24+)
```bash
kubectl --kubeconfig=components/kubeconfigs/blitzinfra-kubeconfig \
  create token headlamp -n headlamp --duration=8760h
```

### Check Live URLs
```bash
terraform -chdir=components/all output exposed_urls
terraform -chdir=components/<name> output exposed_urls
```

### Force Recreate a Deployment
Set `recreate_revision = "some-new-value"` in the relevant `terraform.tfvars` and re-apply.

## Known Gotchas

### `cluster-name.auto.tfvars` Is Invalid
Some component directories contain a `cluster-name.auto.tfvars` with:
```hcl
cluster_name = trimspace(file("${path.root}/../cluster-name.txt"))
```
Terraform function calls are **not valid in `.tfvars` files**. Delete this file and set `cluster_name` directly in `terraform.tfvars`.

### Terraform `count` Cannot Depend on Data Sources with Pending Changes
When a resource uses `count` based on a data source that hasn't been applied yet, use a two-step apply:
```bash
terraform apply -target=<dependency_resource>
terraform apply
```

### DependencyTrack JVM Heap
`JAVA_OPTS` is ignored by the `alpine-executable-war` launcher. Use `JAVA_TOOL_OPTIONS=-Xmx4g` instead. The memory limit must exceed the heap by at least 1Gi for JVM overhead (default `api_memory_limit = "5Gi"`).

### Post-Reboot: NodePorts Stop Working
If `kube-proxy` enters `CrashLoopBackOff` after host reboot with `too many open files`, apply the permanent fix on the Docker host:
```bash
sudo tee /etc/sysctl.d/99-kind-inotify.conf >/dev/null <<'EOF'
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 512
EOF
sudo sysctl --system
kubectl -n kube-system delete pod -l k8s-app=kube-proxy
```
See `TROUBLESHOOTING.md` for full recovery steps.

### PostgreSQL Access from kind Pods
The Docker-hosted PostgreSQL is reached by kind pods via the Docker bridge gateway (e.g. `172.19.0.1`), not `localhost` or `host.docker.internal`.

## Commit Conventions

Semantic commits: `<type>: <summary>` where type is `feat`, `fix`, `docs`, `refactor`, or `chore`. Keep summaries short and imperative. See `CONTRIBUTING.md`.