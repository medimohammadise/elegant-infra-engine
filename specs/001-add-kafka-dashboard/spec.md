# Feature Specification: Kafka Component and Dashboard

**Feature Branch**: `[001-add-kafka-dashboard]`  
**Created**: 2026-03-22  
**Status**: Draft  
**Input**: User description: "I want to have Kafka as a new component considering I do have Kind Cluster in place and also I want to have Open Source KafakDashboard"

## Clarifications

### Session 2026-03-22

- Q: How should operators access the Kafka dashboard? → A: Public external access only, without port forwarding.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Provision Kafka Messaging (Priority: P1)

As a platform operator, I want to deploy a Kafka component into the existing kind-based environment so teams can use an event streaming service as part of the platform.

**Why this priority**: Kafka itself is the primary business capability requested. Without a working messaging component, the dashboard has no useful workload to expose.

**Independent Test**: Can be fully tested by enabling only the Kafka component in an environment that already has the cluster available, confirming the component reaches a ready state and exposes connection details needed by platform users.

**Acceptance Scenarios**:

1. **Given** an environment with the cluster component already available, **When** the operator deploys the Kafka component, **Then** the platform provides a running Kafka service inside the cluster without requiring unrelated components to be deployed.
2. **Given** the Kafka component is deployed, **When** the operator reviews the component outputs and deployment status, **Then** the operator can identify how internal platform workloads should connect to the Kafka service.

---

### User Story 2 - Access Kafka Dashboard (Priority: P2)

As a platform operator, I want an open source Kafka dashboard connected to the deployed Kafka service and reachable from outside the cluster without port forwarding so I can inspect brokers, topics, partitions, and consumer activity from a single interface.

**Why this priority**: Once Kafka is available, operators need a practical way to inspect and manage the service without relying on manual low-level checks.

**Independent Test**: Can be fully tested by deploying the dashboard with a running Kafka component, opening it from outside the cluster through the documented public entry point, and verifying it displays cluster metadata.

**Acceptance Scenarios**:

1. **Given** the Kafka component is running, **When** the operator opens the Kafka dashboard from its documented external entry point, **Then** the dashboard displays the Kafka cluster and its core metadata without requiring port forwarding.
2. **Given** the dashboard is connected, **When** the operator navigates to topics or consumers, **Then** the dashboard shows current topic and consumer information without additional manual configuration.

---

### User Story 3 - Operate Components Independently (Priority: P3)

As a platform operator, I want the Kafka component and dashboard to align with the existing component model so I can deploy them independently or through the aggregate stack without breaking existing workflows.

**Why this priority**: The repository already separates reusable modules from deployable roots and supports partial deployments. The new capability must fit that operating model.

**Independent Test**: Can be fully tested by reviewing the operator workflow for both standalone deployment and aggregate deployment and confirming the documented steps remain consistent and repeatable.

**Acceptance Scenarios**:

1. **Given** an operator deploys components individually, **When** the operator deploys Kafka and its dashboard without using the aggregate stack, **Then** the deployment works as a standalone slice of platform functionality.
2. **Given** an operator uses the aggregate stack, **When** Kafka support is enabled there, **Then** the aggregate deployment exposes the same capability and operator-visible access details as the standalone component.

### Edge Cases

- What happens when the cluster component is not available or not reachable at deployment time? The platform must fail clearly and explain that Kafka depends on an existing cluster environment.
- How does the system handle dashboard startup before Kafka is ready? The dashboard must surface a non-ready or degraded state until Kafka becomes available, without falsely indicating success.
- What happens when the operator deploys Kafka without any topics or consumers yet? The dashboard must still load successfully and show an empty but valid cluster view.
- How does the system handle a redeployment of Kafka or the dashboard? The deployment must remain idempotent and preserve previously configured operator access patterns.
- What happens when Kafka UI is intended for external access but the required public exposure path is not configured on the cluster? The deployment must fail clearly or surface a blocked state with instructions to enable the required external access configuration.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST provide Kafka as a deployable platform component for environments where the cluster component already exists.
- **FR-002**: The system MUST allow the Kafka component to be deployed independently from the aggregate stack.
- **FR-003**: The system MUST allow the aggregate stack to expose the Kafka capability in a way that remains aligned with the standalone Kafka component.
- **FR-004**: The system MUST provide operator-visible connection details for in-cluster workloads that need to use the Kafka service.
- **FR-005**: The system MUST provide an open source dashboard that connects to the deployed Kafka service and is included as part of the Kafka capability.
- **FR-006**: Operators MUST be able to access the dashboard through a documented public platform entry point after deployment.
- **FR-007**: The dashboard MUST display broker, topic, partition, and consumer information for the connected Kafka service.
- **FR-008**: The system MUST clearly communicate deployment failure when Kafka cannot start because the required cluster dependency is missing or unavailable.
- **FR-009**: The system MUST support repeated deployments of the Kafka component and dashboard without requiring manual cleanup between runs.
- **FR-010**: The system MUST document prerequisites, deployment flow, configuration inputs, and operator access steps for the Kafka component and dashboard.
- **FR-011**: The system MUST support external access to the Kafka dashboard without requiring operators to use port forwarding.
- **FR-012**: The system MUST keep the Kafka dashboard external access configuration aligned with the cluster exposure mechanism so the documented public URL remains reachable after deployment.

### Key Entities *(include if feature involves data)*

- **Kafka Component**: The deployable platform capability that provides event streaming within the cluster and exposes the operator-facing configuration and access details for that service.
- **Kafka Dashboard**: The operator-facing interface associated with the Kafka component that presents cluster health and metadata such as brokers, topics, partitions, and consumers.
- **Cluster Environment**: The pre-existing runtime environment that Kafka depends on in order to be deployed and reached by workloads and operators.
- **Operator Access Details**: The documented endpoints and connection information that allow platform operators and in-cluster workloads to use Kafka and open the dashboard.

### Assumptions

- The kind-based cluster component is already available and remains the foundational dependency for this feature.
- The Kafka dashboard is intended for platform operators and administrators rather than external end users.
- Internal platform workloads are the primary consumers and producers for the initial release of the Kafka capability.
- Authentication and fine-grained authorization for the dashboard will follow the platform defaults already used for internal operational interfaces unless later specified otherwise.
- External access to the Kafka dashboard is a required part of the feature scope and must not depend on manual port-forward commands.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Operators can deploy the Kafka component in an environment with an existing cluster dependency and reach a ready state within 20 minutes using the documented workflow.
- **SC-002**: Operators can access the Kafka dashboard from its documented external entry point within 5 minutes after Kafka becomes ready, without using port forwarding.
- **SC-003**: In validation testing, 100% of first-time operators can identify the Kafka connection details needed by internal workloads using the deployment outputs and documentation alone.
- **SC-004**: In validation testing, the dashboard correctly displays cluster metadata for an empty Kafka deployment and for a deployment containing at least one topic and one active consumer group.
- **SC-005**: Re-running the same deployment workflow for Kafka and its dashboard completes successfully in 95% of validation runs without requiring manual cleanup.
