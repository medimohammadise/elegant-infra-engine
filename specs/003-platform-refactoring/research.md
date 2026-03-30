# Research: Platform Refactoring

**Feature**: 003-platform-refactoring
**Date**: 2026-03-30

## R1: terraform_remote_state for Inter-Component Communication

**Decision**: Use `terraform_remote_state` with local backend to share infra outputs with app components.

**Rationale**: This is Terraform's native mechanism for cross-root state sharing. All state is already stored locally. Each app component will declare:

```hcl
data "terraform_remote_state" "infra" {
  backend = "local"
  config = {
    path = "${path.module}/../infra/terraform.tfstate"
  }
}
```

Then reference values like `data.terraform_remote_state.infra.outputs.kubeconfig_path`.

**Alternatives considered**:
- **File-based JSON**: Infra writes a JSON file, apps read via `file()`. Works but adds a custom step outside Terraform's lifecycle.
- **Manual tfvars**: Operator copies values. Error-prone, defeats automation goal.
- **Terraform Cloud/remote backend**: Overkill for single-host local development platform.

---

## R2: Standardized Component Contract

**Decision**: Each application component root must follow this contract:

### Required Variables
- `recreate_revision` (string, default `"1"`) — force resource recreation
- App-specific variables for image versions, ports, etc.

### Required Data Source
- `terraform_remote_state.infra` — reads infra outputs for kubeconfig_path, postgres connection, cluster_name, api_server_host

### Required Outputs
- `namespace` — Kubernetes namespace where the app is deployed
- `exposed_urls` — map of service name → URL for all endpoints this component exposes

### Required Providers
- `kubernetes` and `helm` using kubeconfig_path from infra remote state
- `docker` (only if component uses socat proxies)

### Directory Structure
```text
components/<app-name>/
├── main.tf            # Remote state data source + module call(s)
├── variables.tf       # App-specific variables only
├── outputs.tf         # namespace + exposed_urls
├── providers.tf       # Provider config using remote state values
└── terraform.tfvars   # Operator configuration
```

**Rationale**: Predictable structure means adding a new component (e.g., Kong Gateway) is copy-paste-adapt. No existing component needs modification.

**Alternatives considered**:
- **Convention-based (no formal contract)**: Relies on developers reading existing code. Leads to drift over time.
- **Auto-discovery plugin architecture**: Terraform doesn't natively support dynamic module loading. Would require code generation layer — unnecessary complexity.

---

## R3: Infra Component Output Design

**Decision**: The infra component must expose these outputs for downstream consumption:

| Output | Type | Source |
|--------|------|--------|
| `kubeconfig_path` | string | modules/kind-cluster output |
| `cluster_name` | string | modules/kind-cluster output |
| `kubernetes_api_endpoint` | string | modules/kind-cluster output |
| `api_server_host` | string | var.api_server_host passthrough |
| `ssh_context_host` | string | var.ssh_context_host passthrough |
| `postgres_host` | string | Docker bridge gateway IP (e.g., 172.19.0.1) |
| `postgres_port` | number | modules/postgres output |
| `postgres_db_name` | string | modules/postgres output |
| `postgres_user` | string | modules/postgres output |
| `docker_network_name` | string | modules/docker-network output |

**Rationale**: These are the values previously passed inline between modules in `components/all/main.tf`. Exposing them from `components/infra` lets each app component consume the shared kubeconfig, PostgreSQL, and host details via `terraform_remote_state` without duplicating wiring.

**Note**: `postgres_password` is intentionally NOT exposed via remote state (sensitive). Each app component that needs it must receive it via its own `terraform.tfvars`.

---

## R4: Provider Configuration in App Components

**Decision**: App components cannot use remote state values directly in provider blocks (Terraform limitation — provider config doesn't support data sources). Instead, each app component will:

1. Declare `variable "kubeconfig_path"` with a default pointing to the standard location (`../kubeconfigs/blitzinfra-kubeconfig`)
2. Use this variable in provider blocks
3. The remote state data source is used for non-provider values (postgres host, cluster name, etc.)

**Rationale**: Terraform evaluates provider configuration before data sources. This is a known Terraform limitation. The kubeconfig path is stable (written to a known location by the kind-cluster module), so a default variable value works reliably.

**Alternatives considered**:
- **Symlink kubeconfig**: Each component symlinks to `../kubeconfigs/`. Works but fragile.
- **Environment variable**: `KUBE_CONFIG_PATH` env var. Works but inconsistent with tfvars pattern.
- **Two-pass apply**: First apply reads remote state, second configures provider. Overly complex.

---

## R5: Two-Layer Workflow Without a Combined Root

**Decision**: Keep `components/infra` as the single-source-of-truth infra root and let each application root consume its outputs via `terraform_remote_state`. There is no combined `components/all` orchestrator; treating infra and apps as separate roots enforces clean lifecycles.

**Rationale**: A combined root would duplicate the remote state wiring and blur the separation between infrastructure and workloads. The two-layer workflow keeps infra changes isolated from application updates while still allowing each app to inherit the shared kubeconfig, PostgreSQL, API host, and host-port mappings.

**Alternatives considered**:
- **Rebuilding an aggregate root**: Still possible, but maintaining a separate combined root would reintroduce the very single-command coupling this refactor avoids.
- **Tooling wrapper script**: Running each root sequentially is already straightforward, so no new tooling is required.

---

## R6: Docker Registry Removal

**Decision**: Remove `components/docker-registry/`, `modules/docker-registry/`, and `modules/docker-registry-ui/` from the active platform. Remove all remaining registry references from documentation, scripts, and module wiring.

**Rationale**: User confirmed Docker registry and registry UI are not needed. Keeping unused code increases maintenance burden and confusion.

**Alternatives considered**:
- **Keep but disable by default**: Adds dead code. User explicitly said remove.
- **Move to archive directory**: Optional but adds clutter. Git history preserves the code.

---

## R7: Socat Proxy Placement

**Decision**: Socat proxy containers stay with the application component that owns the proxied service. For example:
- Kafka proxies → `components/kafka/`
- Dependency-Track proxies → `components/dependencytrack/`

Proxies require the Docker provider, so app components with proxies must also configure the Docker provider (in addition to kubernetes/helm).

**Rationale**: The proxy exists to expose a specific app's NodePort. It's logically part of that app's deployment. Moving it elsewhere would create cross-component dependencies.

**Note per CLAUDE.md**: Do NOT use `modules/kafka-ui-proxy` for new services (lifecycle bug). Use direct `docker_image` + `docker_container` resources instead.
