# Implementation Plan: Platform Refactoring — Split Infra and Apps

**Branch**: `003-platform-refactoring` | **Date**: 2026-03-30 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/003-platform-refactoring/spec.md`

## Summary

Refactor the deployment layout into a two-layer architecture: a standalone **infra** component (Docker network, PostgreSQL, kind cluster) and **per-app standalone component roots** (Backstage, Headlamp, Kafka, Keycloak, observability, Dependency-Track). Each app consumes infra outputs via `terraform_remote_state`. There is no combined `components/all` orchestrator in the final layout. Docker registry and registry UI are removed. All components follow a standardized contract (namespace, ports, outputs) so new applications (e.g., Kong, Argo CD) can be added without touching existing roots.

## Technical Context

**Language/Version**: HCL (Terraform >= 1.0)
**Primary Dependencies**: Terraform providers — kreuzwerker/docker ~> 3.0, hashicorp/kubernetes ~> 2.0, hashicorp/helm ~> 2.0, tehcyx/kind
**Storage**: Terraform local state files (one per component root)
**Testing**: `terraform validate`, `terraform plan` (dry-run), manual smoke tests against remote Docker host
**Target Platform**: Remote Docker host (`myserver`) via SSH, kind Kubernetes cluster
**Project Type**: Infrastructure-as-Code (Terraform multi-root)
**Performance Goals**: Infra provisioning < 5 min, per-app deployment < 2 min, full stack < 15 min
**Constraints**: SSH-based Docker access, kind cluster port mappings baked at creation, socat proxies for NodePort exposure
**Scale/Scope**: 6 application components + 1 infra component + 1 combined root = 8 component roots total

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Constitution file contains only template placeholders — no gates defined. Proceeding without constraints.

## Project Structure

### Documentation (this feature)

```text
specs/003-platform-refactoring/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
components/
├── infra/                    # NEW: Standalone infra root
│   ├── main.tf               #   Docker network + PostgreSQL + kind cluster
│   ├── variables.tf           #   Infra-specific variables
│   ├── outputs.tf             #   Exposes: kubeconfig_path, postgres_*, cluster_name, api_server_host
│   ├── providers.tf           #   Docker + kind providers
│   └── terraform.tfvars       #   Infra configuration
│
├── backstage/                # REFACTORED: Standalone app root
│   ├── main.tf               #   Reads infra remote state, deploys backstage module
│   ├── variables.tf           #   App-specific variables only
│   ├── outputs.tf             #   Standardized: namespace, urls, exposed_urls
│   ├── providers.tf           #   Kubernetes + Helm (kubeconfig from remote state)
│   └── terraform.tfvars       #   App configuration
│
├── headlamp/                 # REFACTORED: Same pattern as backstage
├── kafka/                    # REFACTORED: Same pattern + socat proxy resources
├── keycloak/                 # REFACTORED: Same pattern
├── observability/            # REFACTORED: Same pattern
├── dependencytrack/          # REFACTORED: Same pattern + socat proxy resources
│
├── docker-registry/          # REMOVED
├── cluster-apps/             # REMOVED (empty placeholder)
├── kind-cluster/             # KEPT as-is (independent lifecycle for cluster-only ops)
├── postgres/                 # KEPT as-is (independent lifecycle for DB-only ops)
└── kubeconfigs/              # UNCHANGED

modules/                      # UNCHANGED — all existing modules remain as-is
```

**Structure Decision**: Each application gets its own component root under `components/`. The infra root replaces the current empty `components/infra/` placeholder. There is no combined `components/all` orchestrator in the refactored layout — applications read infra outputs via remote state. Docker registry and registry UI components are removed.

## Complexity Tracking

No constitution violations to justify.
