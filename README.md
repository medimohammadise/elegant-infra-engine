# elegant-infra-engine

This repository provisions a remote Docker network, PostgreSQL, a `kind` Kubernetes cluster, Backstage (with Keycloak), Headlamp, Kafka (plus the open-source Kafka UI), Keycloak, and an observability stack (Grafana, Loki, Tempo, and Prometheus) on a remote Docker host such as `myserver`. The layout follows a two-layer architecture: `components/infra` builds the foundational infrastructure and exposes connection outputs, while each application root under `components/` consumes those outputs via `terraform_remote_state`.

For contributor workflow and semantic commit guidance, see [CONTRIBUTING.md](CONTRIBUTING.md).
For operator troubleshooting, including the recurring post-reboot `kind` public endpoint failure on the Docker host, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

## Exposed URLs

Use the listed component roots as the source of truth for each service URL. When a service exposes a public NodePort, the host-port mapping is reserved by the `components/infra` root when it provisions the `kind` cluster.

| Service | Public URL | Root | Notes |
| --- | --- | --- | --- |
| Backstage | `https://<api_server_host>:7007/` | `components/backstage` | Requires `backstage.expose_public = true` and the matching host-port mapping reserved in `components/infra`. |
| Headlamp | `http://<api_server_host>:8443/` | `components/headlamp` | Requires `headlamp.expose_public = true` and the reserved port mapping. |
| Kafka UI | `http://<api_server_host>:8088` | `components/kafka` | Requires `kafka.expose_dashboard_public = true` and the Docker proxy managed by this root. |
| Keycloak | `http://<api_server_host>:8080/` | `components/keycloak` | Requires `keycloak.expose_public = true` and the host-port mapping reserved in `components/infra`. |
| Grafana | `http://<api_server_host>:3000` | `components/observability` | Requires `observability.expose_public = true` plus the matching host-port mapping. |
| Prometheus | `http://<api_server_host>:9090` | `components/observability` | Requires `observability.expose_public = true`, `observability.prometheus.enabled = true`, and the reserved host port. |

Use the following commands to inspect live outputs:

```bash
terraform -chdir=components/infra output kubeconfig_path
terraform -chdir=components/infra output api_server_host
terraform -chdir=components/infra output postgres_host
terraform -chdir=components/infra output postgres_port
terraform -chdir=components/backstage output exposed_urls
terraform -chdir=components/kafka output exposed_urls
terraform -chdir=components/keycloak output exposed_urls
terraform -chdir=components/observability output exposed_urls
```

## Overview

- `components/infra` provisions the Docker network, PostgreSQL container, and `kind` cluster. It exports kubeconfig, PostgreSQL connection details, the SSH host for Docker, and the reserved host ports for public services.
- Each application under `components/` (Backstage, Headlamp, Kafka, Keycloak, Observability) is a standalone component root. They read the infra outputs with `terraform_remote_state` and target the already-provisioned cluster.
- The Terraform modules under `modules/` house the reusable logic (no providers) shared by the component roots.
- Scripts, specs, and helper assets live in `scripts/`, `specs/`, and `references/`.

## Deployment Workflow

1. **Provision infrastructure first** – run the `components/infra` root once to bootstrap the Docker network, PostgreSQL database, `kind` cluster, and host-port mappings.
2. **Deploy each application root independently** – run the per-application Terraform roots in any order (respecting runtime dependencies such as Backstage → Keycloak) after verifying the infra outputs.
3. **Optional focused roots** – use `components/postgres/` or `components/kind-cluster/` if you need to manage PostgreSQL or the `kind` cluster separately.

### Infra Workflow

```bash
cd components/infra
cp terraform.tfvars.example terraform.tfvars
terraform init
mkdir -p /tmp/docker-empty-config
printf '{}' > /tmp/docker-empty-config/config.json
DOCKER_CONFIG=/tmp/docker-empty-config DOCKER_HOST=ssh://myserver terraform apply
```

Infra exposes `kubeconfig_path`, `postgres_*`, `api_server_host`, `ssh_context_host`, and the reserved `kind` host-port mappings. Backstage, Keycloak, Kafka, Headlamp, and Observability all read these outputs via remote state.

### Application Workflow

For each application root (e.g., Backstage, Headlamp, Kafka, Keycloak, Observability):

```bash
cd components/<app>
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply
```

Each root declares a `terraform_remote_state` data source that points to `components/infra/terraform.tfstate`. The apps consume `kubeconfig_path`, PostgreSQL connectivity, and API host details from that data source while keeping their own `terraform.tfstate` files.

## Layout

```text
components/
  infra/            Deploy Docker network, PostgreSQL, and the `kind` cluster (shared state for apps)
  postgres/         Optional root to reconfigure only PostgreSQL
  kind-cluster/     Optional root that manages the `kind` cluster independently
  kubeconfigs/      Stores the generated kubeconfig files
  backstage/         Backstage application root (consumes infra via remote state)
  headlamp/          Headlamp application root
  kafka/             Kafka + Kafka UI application root
  keycloak/          Keycloak application root
  observability/     Grafana/Loki/Tempo/Prometheus root
modules/            Reusable Terraform modules used by the components
scripts/            Helper scripts such as post-render hooks and cluster helpers
specs/              Feature specifications, quickstarts, and contracts
```

## Architecture

The platform uses a simple two-layer architecture:

- **Infra layer** (`components/infra`) builds the shared infrastructure and publishes outputs (kubeconfig path, PostgreSQL host/port, API host, SSH context, docker network name, host-port mappings).
- **Application layer** (`components/<app>`) consumes the infra outputs via `terraform_remote_state`. Each app root manages its own Kubernetes deployment, Helm charts, and any Docker proxies.

This pattern keeps infra and app lifecycles independent while still maintaining a single source of truth for connection information.

## Keycloak Without Port Forwarding

1. Reserve the host-port mapping when provisioning the infra layer:

```hcl
keycloak_port_mapping = {
  node_port = 32080
  host_port = 8080
}
```

2. Enable public exposure in the Keycloak root:

```hcl
keycloak = {
  expose_public = true
  node_port     = 32080
  host_port     = 8080
}
```

3. Deploy Keycloak:

```bash
terraform -chdir=components/keycloak apply
```

4. Read the live URL via:

```bash
terraform -chdir=components/keycloak output keycloak_url
```

## Component Workflows

### Infra (Docker network, PostgreSQL, kind cluster)

`components/infra` declares the Docker, PostgreSQL, and `kind` providers and wires the reusable modules (`modules/docker-network`, `modules/postgres`, `modules/kind-cluster`). It writes the kubeconfig to `components/kubeconfigs/<cluster>-kubeconfig` and outputs the connection details apps rely on. Always run this root with `DOCKER_CONFIG=/tmp/docker-empty-config` and `DOCKER_HOST=ssh://myserver` because it interacts with the remote Docker daemon and `kind`.

### PostgreSQL-only

Use `components/postgres` when you only need to manage the PostgreSQL container without touching the rest of the stack. It shares the same Docker network module as `components/infra`.

### kind cluster-only

`components/kind-cluster` still exists for operators who only want to rebuild the `kind` cluster. The infra root already calls the same module, but this standalone root is useful for rapid cluster reset or alternate host-port experiments.

### Backstage

Backstage reads its PostgreSQL connection and kubeconfig from `components/infra` via `terraform_remote_state`. When `backstage.expose_public = true`, ensure `components/infra` reserved the associated host-port mapping (`backstage_port_mapping`) and that the Backstage Helm chart uses `nodePort` mode.

### Headlamp

Headlamp also relies on the infra kubeconfig. Enable `headlamp.expose_public = true` only after the infra root reserved the `headlamp_port_mapping`. This root patches the upstream chart to avoid the `sessionTTL` bug and exposes the UI on the reserved host port.

### Kafka + Kafka UI

Kafka uses the infra kubeconfig and optionally manages Docker socat proxies for external bootstrap and dashboard access. The Docker provider points at the `ssh://` host stored in the remote state so the proxies run on the remote Docker host.

### Keycloak

Keycloak consumes the infra kubeconfig and PostgreSQL credentials through remote state. The root can expose Keycloak publicly by reusing the host-port mapping reserved earlier.

### Observability

Grafana, Loki, Tempo, Prometheus, and the collector components deploy via `components/observability`. They rely on `terraform_remote_state` for kubeconfig and read the reserved host-port mappings to expose Grafana and Prometheus if requested.

## Force Recreate

Each component root accepts `recreate_revision`. Update this string to a new value when you need Terraform to replace the resources managed by that root on the next apply.

```hcl
recreate_revision = "rebuild-2026-03-31-1"
```

Leave it unchanged during normal applies.

## Notes

- Backstage is pinned to known chart and image versions; it still uses self-signed TLS and is intended for bootstrap/evaluation.
- The Backstage Helm release is post-rendered to force a `Recreate` Deployment strategy so database migrations do not lock.
- Headlamp uses its own service account by default; grant a tighter `cluster_role_name` if you take it beyond disposable clusters.
- The observability stack keeps Grafana for dashboards/trace UI, Loki for logs, Prometheus for metrics, and Tempo for traces with the Grafana Alloy or OpenTelemetry Collector as the telemetry agent layer.
