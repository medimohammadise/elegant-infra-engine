# Implementation Plan: Kafka Component and Dashboard

**Branch**: `[001-add-kafka-dashboard]` | **Date**: 2026-03-22 | **Spec**: [spec.md](/Users/mehdi/MyProject/elegant-infra-engine/specs/001-add-kafka-dashboard/spec.md)
**Input**: Feature specification from `/specs/001-add-kafka-dashboard/spec.md`

## Summary

Add Kafka as a new Terraform-managed platform component for an existing kind cluster, package an open-source Kafka dashboard alongside it, and keep both standalone and `components/all` workflows aligned with existing module and component conventions. The plan uses the repository’s established pattern of a reusable module under `modules/`, a deployable root under `components/`, explicit variable and output contracts, and optional public exposure via NodePort plus kind host-port mappings.

## Technical Context

**Language/Version**: Terraform HCL with Terraform CLI 1.x, Bash-compatible helper scripts  
**Primary Dependencies**: HashiCorp Terraform providers (`helm`, `kubernetes`, `local` where needed), `tehcyx/kind` provider for host-port mappings, Helm charts for Kafka and the Kafka dashboard  
**Storage**: Kubernetes persistent volumes for Kafka data when persistence is enabled; Terraform state for infrastructure metadata  
**Testing**: `terraform fmt -check`, `terraform validate`, and targeted `terraform plan` in the affected component roots  
**Target Platform**: Existing remote or local kind Kubernetes cluster managed by the repository workflows  
**Project Type**: Terraform infrastructure monorepo with reusable modules and deployable component roots  
**Performance Goals**: Kafka component reaches a ready state within the operator workflow window defined in the spec and dashboard access is available shortly after Kafka readiness  
**Constraints**: Must preserve idempotent applies, support standalone and aggregate deployments, avoid mutating remote infrastructure during planning, and keep public exposure consistent with kind host-port mapping conventions  
**Scale/Scope**: Single new reusable Kafka capability, one new standalone component root, `components/all` wiring, README and operator documentation updates, and dashboard exposure support

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

The constitution file at `.specify/memory/constitution.md` is still an unfilled template and does not define enforceable project-specific gates. For this feature, the operative constraints come from the repository instructions and the approved specification:

- Pass: The plan preserves the existing split between reusable modules in `modules/` and deployable roots in `components/`.
- Pass: The plan keeps inputs explicit through `variables.tf`, outputs explicit through `outputs.tf`, and provider setup scoped to component roots.
- Pass: The plan maintains partial deployment support and keeps `components/all` aligned with the standalone component.
- Pass: The plan does not require destructive operations, remote applies, or cluster mutation during planning.

Post-design re-check: Phase 1 artifacts continue to satisfy these constraints with no justified violations.

## Project Structure

### Documentation (this feature)

```text
specs/001-add-kafka-dashboard/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── terraform-component-contract.md
│   └── aggregate-stack-contract.md
└── tasks.md
```

### Source Code (repository root)

```text
README.md
components/
├── all/
├── kafka/
└── kind-cluster/
modules/
├── kafka/
├── k8s-namespace/
└── kind-cluster/
scripts/
└── ...
```

**Structure Decision**: Implement Kafka using the existing Terraform monorepo layout by adding a reusable `modules/kafka` module, a standalone `components/kafka` root with scoped providers, aggregate wiring in `components/all`, and any required kind host-port exposure updates in `modules/kind-cluster` and `components/kind-cluster`.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No constitution violations or justified exceptions were identified during planning.
