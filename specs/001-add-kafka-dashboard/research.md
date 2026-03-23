# Research: Kafka Component and Dashboard

## Decision 1: Model Kafka as a reusable module plus a standalone component root

**Decision**: Implement Kafka using a new reusable module under `modules/kafka` and a deployable root under `components/kafka`, then wire the same capability into `components/all`.

**Rationale**: This repository already separates reusable infrastructure logic from deployable roots for cluster applications such as Headlamp, Keycloak, and observability. Using the same pattern preserves partial deployment support, keeps provider setup scoped to component roots, and avoids duplicating Kafka deployment logic between standalone and aggregate workflows.

**Alternatives considered**:

- Add Kafka resources only to `components/all`: rejected because it would break the repository’s component model and remove independent lifecycle management.
- Add all Kafka resources directly into multiple component roots: rejected because it would duplicate logic and drift over time.

## Decision 2: Deploy Kafka through the existing Helm-based Kubernetes application pattern

**Decision**: Use a Helm-managed Kafka deployment pattern, exposed through Terraform inputs that mirror the current chart-based components in this repository.

**Rationale**: Existing Kubernetes-facing components already use Terraform `helm_release` resources with chart settings surfaced through typed variables. Reusing that pattern keeps the implementation consistent with the current repo style, makes chart source and version explicit, and allows operator overrides without altering the module structure.

**Alternatives considered**:

- Write raw Kubernetes manifests in Terraform resources: rejected because it would diverge from the repo’s current chart-driven approach and increase maintenance overhead.
- Introduce a separate scripting-based installer: rejected because it would bypass the Terraform workflow the repository is built around.

## Decision 3: Default to a single-cluster Kafka footprint appropriate for kind-based platform environments

**Decision**: Plan for a compact default Kafka deployment profile suitable for the existing kind-based environment, with configuration exposed so operators can adjust capacity and persistence later.

**Rationale**: The feature specification targets an environment where kind is already in place and values repeatable operator workflows more than production-scale throughput. A compact default reduces friction for initial adoption while leaving room for future scaling through explicit inputs.

**Alternatives considered**:

- Optimize immediately for a large multi-broker production footprint: rejected because it adds complexity that the current spec does not require.
- Hardcode a fixed lightweight footprint with no operator controls: rejected because the spec requires explicit configuration inputs and repeatable lifecycle management.

## Decision 4: Use an open-source Kafka dashboard as part of the same component capability

**Decision**: Bundle an open-source Kafka dashboard with the Kafka component and manage it through the same Terraform-driven deployment flow, with public exposure remaining optional.

**Rationale**: The user explicitly requested a Kafka dashboard, and the repo already treats operator-facing web interfaces as first-class Terraform-managed components. Keeping the dashboard tied to Kafka simplifies operator onboarding and ensures the dashboard configuration stays aligned with the Kafka service it observes.

**Alternatives considered**:

- Leave dashboard deployment as a manual post-step: rejected because it weakens repeatability and conflicts with the repo’s automation goals.
- Create a completely separate dashboard component with no Kafka coupling: rejected because the dashboard has limited value without a Kafka service and would complicate configuration for the initial release.

## Decision 5: Expose the dashboard using the same kind host-port mapping model used by existing public services

**Decision**: When public exposure is enabled, reserve dashboard access through a NodePort in-cluster and a matching host-port mapping in the kind cluster workflow, with outputs surfaced in both the standalone component and `components/all`.

**Rationale**: The current repository already uses this pattern for Backstage, Headlamp, Keycloak, Grafana, and Prometheus. Reusing it gives operators a familiar access model, keeps public endpoints explicit, and avoids creating a one-off exposure path for Kafka tooling.

**Alternatives considered**:

- Require only in-cluster access with no host mapping support: rejected because the spec requires a documented operator entry point after deployment.
- Introduce a different ingress mechanism only for Kafka dashboard access: rejected because it would create an inconsistent operator experience and new integration work not required by the feature.
