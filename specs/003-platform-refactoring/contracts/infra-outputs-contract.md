# Infra Outputs Contract

**Version**: 1.0
**Date**: 2026-03-30

## Purpose

Defines the stable output interface that the infra component (`components/infra/`) exposes via its Terraform state. All application components depend on this contract via `terraform_remote_state`.

## Outputs

| Output | Type | Sensitive | Description |
|--------|------|-----------|-------------|
| `kubeconfig_path` | string | no | Absolute path to the generated kubeconfig file |
| `cluster_name` | string | no | Kind cluster name |
| `kubernetes_api_endpoint` | string | no | Reachable Kubernetes API endpoint URL |
| `api_server_host` | string | no | Remote Docker host hostname (e.g., "myserver") |
| `ssh_context_host` | string | no | SSH connection string for Docker provider |
| `postgres_host` | string | no | Docker bridge gateway IP for kind pod access |
| `postgres_port` | number | no | PostgreSQL host port |
| `postgres_db_name` | string | no | Default database name |
| `postgres_user` | string | no | Database user |
| `docker_network_name` | string | no | Docker network name for container connectivity |

## NOT Exposed (by design)

| Value | Reason |
|-------|--------|
| `postgres_password` | Sensitive — each app component receives this via its own `terraform.tfvars` |
| `kubeconfig` (content) | Sensitive — apps use `kubeconfig_path` instead |
| `client_certificate` | Sensitive — not needed by app components |
| `client_key` | Sensitive — not needed by app components |

## Compatibility Rules

- Outputs may be **added** without breaking existing consumers.
- Existing outputs MUST NOT be **renamed** or **removed** without updating all consumers.
- Output **types** MUST NOT change (e.g., string → number) without migration.
