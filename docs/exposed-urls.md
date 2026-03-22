# Exposed URLs

Use Terraform outputs as the source of truth for the live values. This file is the operator-facing inventory of which service is expected at which public URL shape.

## URL Table

| Service | Public URL | Root | Notes |
| --- | --- | --- | --- |
| Kubernetes API | `https://<api_server_host>:6443` | `components/kind-cluster` or `components/all` | Port follows `kubernetes.api_server_port`. |
| Docker Registry | `http://<api_server_host>:5000` | `components/docker-registry` or `components/all` | Port follows `registry.port`. |
| Registry UI | `http://<api_server_host>:8081` | `components/docker-registry` or `components/all` | If `registry.ui_bind` is `127.0.0.1` or `localhost`, use that bind address instead. |
| Backstage | `https://<api_server_host>:7007/` | `components/backstage` or `components/all` | Requires the matching Backstage host-port mapping on the kind cluster. |
| Headlamp | `http://<api_server_host>:8443/` | `components/headlamp` or `components/all` | Requires the matching Headlamp host-port mapping on the kind cluster. |
| Keycloak | `http://<api_server_host>:8080/` | `components/keycloak` | Requires `keycloak.expose_public = true` and the matching Keycloak host-port mapping on the kind cluster. |
| Grafana | `http://<api_server_host>:3000` | `components/observability` or `components/all` | Requires `observability.expose_public = true` and the matching Grafana host-port mapping on the kind cluster. |
| Prometheus | `http://<api_server_host>:9090` | `components/observability` or `components/all` | Requires `observability.expose_public = true`, `observability.prometheus.enabled = true`, and the matching Prometheus host-port mapping on the kind cluster. |

For the current example configuration this means:

| Service | Example URL |
| --- | --- |
| Backstage | `https://myserver:7007/` |
| Headlamp | `http://myserver:8443/` |
| Keycloak | `http://myserver:8080/` |
| Grafana | `http://myserver:3000` |
| Prometheus | `http://myserver:9090` |

## Commands

```bash
terraform -chdir=components/all output exposed_urls
terraform -chdir=components/backstage output exposed_urls
terraform -chdir=components/keycloak output exposed_urls
terraform -chdir=components/observability output exposed_urls
```

## Keycloak Without Port Forwarding

To reach Keycloak directly from outside the cluster:

1. Reserve the host-port mapping when creating or recreating the kind cluster:

```hcl
keycloak_port_mapping = {
  node_port = 32080
  host_port = 8080
}
```

2. Deploy Keycloak with public exposure enabled:

```hcl
keycloak = {
  expose_public = true
  node_port     = 32080
  host_port     = 8080
  # other fields omitted
}
```

3. Read the live URL from Terraform:

```bash
terraform -chdir=components/keycloak output keycloak_url
```
