# Standardized Component Contract

**Version**: 1.0
**Date**: 2026-03-30

## Purpose

Every application component in this platform must follow this contract. Adherence ensures that:
- New components can be added without modifying existing ones
- All components are independently deployable with predictable structure
- The combined root can orchestrate all components uniformly

## Directory Structure

```text
components/<app-name>/
├── main.tf            # Remote state data source + module call(s) + optional proxy resources
├── variables.tf       # App-specific variables (NO infra variables)
├── outputs.tf         # Must include: namespace, exposed_urls
├── providers.tf       # Provider config (kubernetes, helm, optionally docker)
└── terraform.tfvars   # Operator configuration
```

## Required: Remote State Data Source

Every app component must include this data source in `main.tf`:

```hcl
data "terraform_remote_state" "infra" {
  backend = "local"
  config = {
    path = "${path.module}/../infra/terraform.tfstate"
  }
}
```

Available outputs from infra:
- `kubeconfig_path` (string)
- `cluster_name` (string)
- `kubernetes_api_endpoint` (string)
- `api_server_host` (string)
- `ssh_context_host` (string)
- `postgres_host` (string)
- `postgres_port` (number)
- `postgres_db_name` (string)
- `postgres_user` (string)
- `docker_network_name` (string)

## Required: Variables

```hcl
variable "kubeconfig_path" {
  description = "Path to kubeconfig file."
  type        = string
  default     = "../kubeconfigs/blitzinfra-kubeconfig"
}

variable "recreate_revision" {
  description = "Change this value to force resource recreation."
  type        = string
  default     = "1"
}
```

App-specific variables (image versions, ports, feature flags) are defined per component.

**Note**: `postgres_password` and other secrets must be declared as variables in the component (not read from remote state). Pass them via `terraform.tfvars`.

## Required: Outputs

```hcl
output "namespace" {
  description = "Kubernetes namespace where this application is deployed."
  value       = "<namespace value>"
}

output "exposed_urls" {
  description = "Map of service endpoints exposed by this component."
  value = {
    <service_name> = "<url>"
  }
}
```

## Required: Providers

Minimum (Kubernetes-only apps):

```hcl
provider "kubernetes" {
  config_path = var.kubeconfig_path
  insecure    = true
}

provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_path
    insecure    = true
  }
}
```

Additional (apps with socat proxies):

```hcl
provider "docker" {
  host = "ssh://${data.terraform_remote_state.infra.outputs.ssh_context_host}"
  ssh_opts = ["-o", "StrictHostKeyChecking=no", "-i", var.ssh_private_key_path]
}
```

**Note**: Docker provider config CAN use data sources (unlike kubernetes/helm providers which must use variables).

## Adding a New Component

To add a new application (e.g., Kong Gateway):

1. Create `components/kong/` with the directory structure above
2. Create or reuse a module in `modules/kong/`
3. Add `terraform_remote_state.infra` data source to `main.tf`
4. Wire module inputs from remote state outputs + component-specific variables
5. Define `namespace` and `exposed_urls` outputs
6. Create `terraform.tfvars` with component-specific configuration
7. The new component is self-contained — no existing component files need modification.
