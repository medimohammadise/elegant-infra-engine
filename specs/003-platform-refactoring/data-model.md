# Data Model: Platform Refactoring

**Feature**: 003-platform-refactoring
**Date**: 2026-03-30

## Entities

### Infra Layer

Represents the foundational infrastructure provisioned on the remote Docker host.

| Attribute | Type | Source | Description |
|-----------|------|--------|-------------|
| cluster_name | string | var | Kind cluster name (e.g., "blitzinfra") |
| kubernetes_api_endpoint | string | computed | `https://{api_server_host}:{api_server_port}` |
| kubeconfig_path | string | computed | Path to generated kubeconfig file |
| api_server_host | string | var | Remote Docker host hostname (e.g., "myserver") |
| ssh_context_host | string | var | SSH connection string for Docker provider |
| postgres_host | string | computed | Docker bridge gateway IP for kind pod access |
| postgres_port | number | var | PostgreSQL host port |
| postgres_db_name | string | var | Database name |
| postgres_user | string | var | Database user |
| docker_network_name | string | computed | Docker network name for container connectivity |

**Lifecycle**: Created first, destroyed last. Apps depend on infra; infra has no app dependencies.

**State**: `components/infra/terraform.tfstate`

---

### Application Component

Represents a single deployable application. Each follows the standardized contract.

| Attribute | Type | Source | Description |
|-----------|------|--------|-------------|
| namespace | string | var | Kubernetes namespace for this app |
| exposed_urls | map(string) | computed | Map of endpoint name → URL |
| kubeconfig_path | string | var (default) | Path to kubeconfig (stable default) |
| recreate_revision | string | var | Force recreation trigger |

**Lifecycle**: Independent per app. Can be created/destroyed without affecting other apps or infra.

**State**: `components/<app-name>/terraform.tfstate`

**Instances**:
- Backstage (depends on: postgres, keycloak)
- Headlamp (no app dependencies)
- Kafka (no app dependencies, has socat proxies)
- Keycloak (depends on: postgres)
- Observability (no app dependencies)
- Dependency-Track (depends on: postgres, has socat proxies)

---

## Relationships

```text
Infra Layer ──outputs──▶ terraform_remote_state ──consumed by──▶ Application Components
```

- **Infra → Apps**: One-to-many. Infra outputs are consumed by each app independently.
- **App → App**: No direct dependencies at the Terraform level. Inter-app runtime dependencies (e.g., Backstage → Keycloak) are handled at the application layer, not infrastructure.

## Validation Rules

- Infra must be applied before any app component (enforced by remote state — if infra state doesn't exist, apps fail).
- `postgres_password` is never exposed via remote state outputs (sensitive data). Each app receives it via its own tfvars.
- `kubeconfig_path` uses a stable default path; provider blocks cannot reference data sources.
