# Feature Specification: Platform Refactoring — Split Infra and Apps

**Feature Branch**: `003-platform-refactoring`
**Created**: 2026-03-30
**Status**: Draft
**Input**: User description: "I want to refactor this into two parts — infra (like kind cluster) and the apps part — in a way that I can execute them separately"

## Clarifications

### Session 2026-03-30

- Q: Should new components follow a standardized contract so they plug in without modifying existing components? → A: Yes — standardized component contract. Each app must declare namespace, enable toggle, ports, and outputs.
- Q: How should the apps layer consume infra outputs? → A: Terraform remote state — apps layer reads infra outputs via `terraform_remote_state` data source.
- Q: Should each app have its own state or share one apps-layer state? → A: Per-app standalone roots — each application (Backstage, Kafka, Keycloak, Headlamp, observability, Dependency-Track) is its own independent component root with its own state. No shared apps root. Each app reads infra outputs via remote state independently.
- Q: What happens to Docker registry and registry UI? → A: Remove them from the new structure entirely. They are not needed.
- Q: What should the combined root do with standalone app components? → A: Terraform combined root — calls infra module + each app module via module calls, providing single `terraform apply` for full-stack bootstrapping.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Provision Infrastructure Independently (Priority: P1)

As a platform operator, I want to provision and manage the foundational infrastructure layer (Docker network, PostgreSQL, kind cluster) independently from any application deployments, so that I can bring up or tear down infrastructure without affecting application definitions and vice versa.

**Why this priority**: Infrastructure is the foundation. Without a standalone infra layer, nothing else runs. Decoupling it allows stable base infrastructure that persists across app changes.

**Independent Test**: Can be fully tested by running the infra component alone and verifying that the kind cluster, Docker network, and PostgreSQL are running and accessible — with zero application workloads deployed.

**Acceptance Scenarios**:

1. **Given** a fresh remote Docker host, **When** the operator applies only the infra layer, **Then** the Docker network, PostgreSQL, and kind cluster are created and healthy.
2. **Given** a running infra layer, **When** the operator destroys and re-applies only the infra layer, **Then** all infrastructure components are recreated without requiring any apps-layer configuration.
3. **Given** a running infra layer, **When** the operator checks outputs, **Then** connection details (kubeconfig path, PostgreSQL host/port, cluster name) are available for downstream consumption via remote state.

---

### User Story 2 - Deploy Applications Independently (Priority: P1)

As a platform operator, I want to deploy each application (Backstage, Headlamp, Kafka, Keycloak, observability stack, Dependency-Track) as a standalone component onto existing infrastructure, so that I can update, add, or remove individual applications without affecting anything else.

**Why this priority**: Equally critical — standalone app components are where user-facing value lives. Independent deployability per app maximizes isolation and reduces blast radius.

**Independent Test**: Can be fully tested by applying a single application component (e.g., Backstage) against a running infra layer and verifying it deploys and is accessible, with no other apps present.

**Acceptance Scenarios**:

1. **Given** a running infra layer, **When** the operator applies a single application component (e.g., Kafka), **Then** only that application is deployed and reachable; no other apps are affected.
2. **Given** a running application component, **When** the operator changes its configuration and re-applies, **Then** only that application is updated; infrastructure and other apps remain untouched.
3. **Given** a running application component, **When** the operator destroys it, **Then** only that application is removed; infrastructure and all other application components remain healthy.

---

### User Story 3 - Run Full Stack in One Command (Priority: P2)

As a platform operator, I want to retain the ability to provision the entire stack (infra + apps) in a single operation, so that fresh environment setup remains simple for initial bootstrapping.

**Why this priority**: Convenience for first-time setup or full environment recreation, but not blocking since the two-layer approach covers the primary workflow.

**Independent Test**: Can be tested by running the combined orchestration root and verifying both infra and apps come up end-to-end.

**Acceptance Scenarios**:

1. **Given** a fresh remote Docker host, **When** the operator applies the combined root, **Then** infrastructure is provisioned first, followed by all enabled applications — matching the same end state as running infra then apps separately.

---

### Edge Cases

- What happens when the apps layer is applied but infra has not been provisioned yet? The apps layer must fail with a clear error indicating missing infrastructure dependencies.
- What happens when infra is destroyed while apps are still running? The operator receives a warning or the apps layer gracefully handles the missing infrastructure on next apply.
- What happens when infra outputs change (e.g., cluster name or PostgreSQL port)? The apps layer must pick up updated values on next apply without manual intervention.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The platform MUST be split into two independently executable layers: an "infra" layer and an "apps" layer.
- **FR-002**: The infra layer MUST include: Docker network, PostgreSQL, and kind cluster creation. Docker registry and registry UI are removed from the platform.
- **FR-003**: Each application MUST be a standalone component root: Backstage, Headlamp, Kafka (with UI and proxies), Keycloak, observability stack (Grafana, Loki, Tempo, Prometheus), and Dependency-Track.
- **FR-004**: The infra layer MUST expose connection outputs (kubeconfig path, PostgreSQL connection details, Docker registry URL, cluster name) that the apps layer can consume.
- **FR-005**: The apps layer MUST consume infra connection details via a `terraform_remote_state` data source pointing at the infra layer's state file, rather than provisioning its own infrastructure.
- **FR-006**: Each component (infra, and each individual application) MUST maintain its own independent state, allowing separate plan/apply/destroy lifecycles. Each application is a standalone component root — there is no shared apps-layer root.
- **FR-007**: Operator-facing documentation (README, CLAUDE.md, quickstarts, etc.) MUST describe the two-phase workflow and the remote-state contract so operators understand that `components/infra` is the single source of truth for kubeconfig, PostgreSQL, and host-port mappings.
- **FR-008**: Each standalone application component is enabled/disabled by whether the operator chooses to apply it — no shared toggle variables needed.
- **FR-009**: The apps layer MUST fail clearly if required infra outputs are not available or not provided.
- **FR-010**: Socat proxy containers for exposing services MUST remain in the appropriate layer alongside the services they proxy.
- **FR-011**: Every application component MUST follow a standardized contract that declares: namespace, enable/disable toggle, port mappings (node port + host port), and outputs (URLs, connection details).
- **FR-012**: Adding a new application component (e.g., Kong Gateway, Argo CD) MUST NOT require modifications to any existing component — only the new component's own files and the apps-layer root wiring.
- **FR-013**: The standardized component contract MUST be documented so that an operator can add a new component by following the contract pattern without reverse-engineering existing components.

### Key Entities

- **Infra Layer**: Groups foundational resources — Docker network, PostgreSQL, kind cluster. Produces connection outputs (kubeconfig, postgres details, cluster name).
- **Application Component**: A standalone component root for a single application (e.g., Backstage, Kafka, Keycloak). Each consumes infra outputs via remote state and manages its own lifecycle independently.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Operator can provision infrastructure in isolation with a single command and verify all infra components are healthy within 5 minutes.
- **SC-002**: Operator can deploy each application independently onto existing infrastructure and verify each enabled service is reachable within 10 minutes.
- **SC-003**: Destroying and re-applying only the apps layer does not affect infrastructure state (cluster and database remain intact).
- **SC-004**: Destroying and re-applying only the infra layer is possible without needing apps-layer configuration files present.
- **SC-005**: Operator-facing documentation clearly describes the infra → app workflow, the remote-state contract, and which roots publish which outputs.
- **SC-006**: Existing `terraform.tfvars` configuration patterns are preserved — operator does not need to learn a new configuration approach.

## Assumptions

- The architecture intentionally keeps `components/infra` separate from each application root — there is no combined `components/all` orchestration root in this refactor.
- Existing standalone component directories (`components/backstage`, `components/kafka`, etc.) will be refactored to follow the standardized contract and consume infra via remote state.
- Docker registry and Docker registry UI are removed from the platform — they are not needed.
- Inter-layer communication uses Terraform remote state (`terraform_remote_state` data source) — the apps layer reads the infra layer's state file directly. No external coordination tool or intermediate files needed.
- The socat proxy pattern (Docker containers on the remote host) stays with whichever layer owns the proxied service.
- All existing modules in `modules/` remain unchanged; only the component roots are restructured.
- The remote Docker host (`myserver`) and SSH-based Docker access pattern remain unchanged.
