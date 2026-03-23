# Tasks: Kafka Component and Dashboard

**Input**: Design documents from `/specs/001-add-kafka-dashboard/`
**Prerequisites**: [plan.md](/Users/mehdi/MyProject/elegant-infra-engine/specs/001-add-kafka-dashboard/plan.md), [spec.md](/Users/mehdi/MyProject/elegant-infra-engine/specs/001-add-kafka-dashboard/spec.md), [research.md](/Users/mehdi/MyProject/elegant-infra-engine/specs/001-add-kafka-dashboard/research.md), [data-model.md](/Users/mehdi/MyProject/elegant-infra-engine/specs/001-add-kafka-dashboard/data-model.md), [contracts/](/Users/mehdi/MyProject/elegant-infra-engine/specs/001-add-kafka-dashboard/contracts)

**Tests**: Include validation tasks with `terraform fmt -check`, `terraform validate`, and targeted `terraform plan` for affected roots. No separate test-first tasks were generated because the feature spec did not request TDD.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g. `US1`, `US2`, `US3`)
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Establish the new feature skeleton and document entry points for implementation.

- [X] T001 Create the Kafka component directory structure and placeholder Terraform files in `/Users/mehdi/MyProject/elegant-infra-engine/components/kafka/` and `/Users/mehdi/MyProject/elegant-infra-engine/modules/kafka/`
- [X] T002 [P] Add the Kafka component to the repository layout and workflow documentation in `/Users/mehdi/MyProject/elegant-infra-engine/README.md`
- [X] T003 [P] Review exposed endpoint documentation expectations for future Kafka dashboard output updates in `/Users/mehdi/MyProject/elegant-infra-engine/docs/exposed-urls.md`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Build the shared Terraform contracts that every user story depends on.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T004 Define reusable Kafka module inputs in `/Users/mehdi/MyProject/elegant-infra-engine/modules/kafka/variables.tf`
- [X] T005 [P] Implement reusable Kafka module resources and Helm values wiring in `/Users/mehdi/MyProject/elegant-infra-engine/modules/kafka/main.tf`
- [X] T006 [P] Expose reusable Kafka module outputs for namespace, release names, bootstrap servers, and dashboard URL in `/Users/mehdi/MyProject/elegant-infra-engine/modules/kafka/outputs.tf`
- [X] T007 Create the standalone Kafka component provider configuration in `/Users/mehdi/MyProject/elegant-infra-engine/components/kafka/providers.tf`
- [X] T008 Define standalone Kafka component variables in `/Users/mehdi/MyProject/elegant-infra-engine/components/kafka/variables.tf`
- [X] T009 Create the standalone Kafka component example configuration in `/Users/mehdi/MyProject/elegant-infra-engine/components/kafka/terraform.tfvars.example`

**Checkpoint**: Foundation ready. User story implementation can begin.

---

## Phase 3: User Story 1 - Provision Kafka Messaging (Priority: P1) 🎯 MVP

**Goal**: Deliver a standalone Kafka component that deploys into an existing kind cluster and exposes connection details for internal workloads.

**Independent Test**: Run `terraform fmt -check`, `terraform validate`, and a targeted `terraform plan` in `/Users/mehdi/MyProject/elegant-infra-engine/components/kafka/` with a valid kubeconfig and confirm the plan produces Kafka resources plus bootstrap server outputs without requiring unrelated components.

### Implementation for User Story 1

- [X] T010 [US1] Compose the standalone Kafka deployment root using `modules/k8s-namespace` and `modules/kafka` in `/Users/mehdi/MyProject/elegant-infra-engine/components/kafka/main.tf`
- [X] T011 [US1] Expose standalone Kafka outputs for namespace, release names, bootstrap servers, and consolidated URLs in `/Users/mehdi/MyProject/elegant-infra-engine/components/kafka/outputs.tf`
- [X] T012 [US1] Add operator-facing failure handling and dependency notes for missing cluster prerequisites in `/Users/mehdi/MyProject/elegant-infra-engine/components/kafka/variables.tf`
- [X] T013 [US1] Validate formatting and configuration for the standalone Kafka root in `/Users/mehdi/MyProject/elegant-infra-engine/components/kafka/`

**Checkpoint**: User Story 1 should now be independently functional and plannable.

---

## Phase 4: User Story 2 - Access Kafka Dashboard (Priority: P2)

**Goal**: Deliver the open-source Kafka dashboard as part of the Kafka capability, including optional public access through the documented platform entry point.

**Independent Test**: Run a targeted `terraform plan` in `/Users/mehdi/MyProject/elegant-infra-engine/components/kafka/` with dashboard exposure enabled and confirm the plan includes dashboard resources, public exposure settings, and a dashboard URL output that remains valid even for an empty Kafka deployment.

### Implementation for User Story 2

- [X] T014 [US2] Add Kafka dashboard deployment, connection wiring, and exposure options to `/Users/mehdi/MyProject/elegant-infra-engine/modules/kafka/main.tf`
- [X] T015 [P] [US2] Extend Kafka module variable definitions for dashboard chart, service type, node port, and persistence-related settings in `/Users/mehdi/MyProject/elegant-infra-engine/modules/kafka/variables.tf`
- [X] T016 [P] [US2] Extend Kafka module outputs for dashboard release name and dashboard URL in `/Users/mehdi/MyProject/elegant-infra-engine/modules/kafka/outputs.tf`
- [X] T017 [US2] Surface dashboard-specific defaults and exposure controls in `/Users/mehdi/MyProject/elegant-infra-engine/components/kafka/terraform.tfvars.example`
- [X] T018 [US2] Document the standalone dashboard access workflow and Kafka connection outputs in `/Users/mehdi/MyProject/elegant-infra-engine/README.md`
- [X] T019 [US2] Validate formatting and configuration for the standalone Kafka root with dashboard settings in `/Users/mehdi/MyProject/elegant-infra-engine/components/kafka/`

**Checkpoint**: User Stories 1 and 2 should now work independently through the standalone component.

---

## Phase 5: User Story 3 - Operate Components Independently (Priority: P3)

**Goal**: Align standalone and aggregate deployments so Kafka support works both on its own and through `components/all` without breaking the existing workflow.

**Independent Test**: Run `terraform fmt -check`, `terraform validate`, and a targeted `terraform plan` in `/Users/mehdi/MyProject/elegant-infra-engine/components/all/` with Kafka enabled and confirm the aggregate root exposes the same Kafka connection details and dashboard URL contract as the standalone root.

### Implementation for User Story 3

- [X] T020 [US3] Add Kafka enablement, configuration defaults, and optional dashboard host-port mapping inputs in `/Users/mehdi/MyProject/elegant-infra-engine/components/all/variables.tf`
- [X] T021 [US3] Wire Kafka and optional dashboard host-port mapping into the aggregate stack in `/Users/mehdi/MyProject/elegant-infra-engine/components/all/main.tf`
- [X] T022 [P] [US3] Expose aggregate Kafka outputs and consolidated URLs in `/Users/mehdi/MyProject/elegant-infra-engine/components/all/outputs.tf`
- [X] T023 [P] [US3] Add Kafka dashboard host-port mapping support to `/Users/mehdi/MyProject/elegant-infra-engine/modules/kind-cluster/variables.tf`
- [X] T024 [US3] Implement the Kafka dashboard host-port mapping in `/Users/mehdi/MyProject/elegant-infra-engine/modules/kind-cluster/main.tf`
- [X] T025 [US3] Surface Kafka-related example values for aggregate deployments in `/Users/mehdi/MyProject/elegant-infra-engine/components/all/terraform.tfvars.example`
- [X] T026 [US3] Document standalone versus aggregate Kafka deployment workflows in `/Users/mehdi/MyProject/elegant-infra-engine/README.md`
- [X] T027 [US3] Validate formatting and configuration for `/Users/mehdi/MyProject/elegant-infra-engine/components/all/` and `/Users/mehdi/MyProject/elegant-infra-engine/components/kind-cluster/`

**Checkpoint**: All three user stories should now be independently plannable and aligned with the repo’s component model.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Finish shared documentation and repository-level validation.

- [X] T028 [P] Update consolidated exposed endpoint documentation for Kafka dashboard access in `/Users/mehdi/MyProject/elegant-infra-engine/docs/exposed-urls.md`
- [X] T029 Reconcile any README examples and prerequisites affected by Kafka dashboard public exposure in `/Users/mehdi/MyProject/elegant-infra-engine/README.md`
- [X] T030 Run final validation across `/Users/mehdi/MyProject/elegant-infra-engine/components/kafka/`, `/Users/mehdi/MyProject/elegant-infra-engine/components/all/`, and `/Users/mehdi/MyProject/elegant-infra-engine/components/kind-cluster/`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1: Setup**: No dependencies; can start immediately.
- **Phase 2: Foundational**: Depends on Phase 1; blocks all user stories.
- **Phase 3: User Story 1**: Depends on Phase 2; establishes the MVP Kafka component.
- **Phase 4: User Story 2**: Depends on Phase 3 because the dashboard is attached to the Kafka component and uses its outputs.
- **Phase 5: User Story 3**: Depends on Phases 3 and 4 so aggregate wiring can reuse the finalized standalone contract.
- **Phase 6: Polish**: Depends on all desired user stories being complete.

### User Story Dependencies

- **User Story 1 (P1)**: Starts after the foundational Terraform contracts are in place.
- **User Story 2 (P2)**: Depends on User Story 1 because the dashboard requires a working Kafka component and its connection details.
- **User Story 3 (P3)**: Depends on User Story 1 for the component contract and on User Story 2 for the public dashboard exposure model.

### Within Each User Story

- Module contracts before component wiring.
- Component outputs before documentation and validation.
- Aggregate wiring before aggregate example configuration and final validation.

### Parallel Opportunities

- `T002` and `T003` can run in parallel during setup.
- `T005` and `T006` can run in parallel after `T004`.
- `T015` and `T016` can run in parallel after `T014` is scoped.
- `T022` and `T023` can run in parallel during aggregate-stack implementation.
- `T028` can run in parallel with late-stage validation once aggregate outputs are stable.

---

## Parallel Example: User Story 2

```bash
Task: "Extend Kafka module variable definitions for dashboard chart, service type, node port, and persistence-related settings in /Users/mehdi/MyProject/elegant-infra-engine/modules/kafka/variables.tf"
Task: "Extend Kafka module outputs for dashboard release name and dashboard URL in /Users/mehdi/MyProject/elegant-infra-engine/modules/kafka/outputs.tf"
```

## Parallel Example: User Story 3

```bash
Task: "Expose aggregate Kafka outputs and consolidated URLs in /Users/mehdi/MyProject/elegant-infra-engine/components/all/outputs.tf"
Task: "Add Kafka dashboard host-port mapping support to /Users/mehdi/MyProject/elegant-infra-engine/modules/kind-cluster/variables.tf"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 and Phase 2.
2. Complete User Story 1 tasks `T010` through `T013`.
3. Validate the standalone Kafka component in `/Users/mehdi/MyProject/elegant-infra-engine/components/kafka/`.
4. Stop after the P1 checkpoint if only Kafka provisioning is needed for the first delivery.

### Incremental Delivery

1. Ship User Story 1 to establish the Kafka component contract.
2. Add User Story 2 to make the dashboard operational and operator-friendly.
3. Add User Story 3 to align `components/all` and kind host-port mappings with the standalone deployment.
4. Finish with documentation and validation tasks in Phase 6.

### Parallel Team Strategy

1. One engineer completes Phase 1 and Phase 2.
2. After User Story 1 is stable, one engineer can handle dashboard module changes while another prepares aggregate outputs and kind cluster mapping support.
3. Merge on the shared contracts before the final validation pass.

---

## Notes

- All tasks use the required checklist format with task ID, optional parallel marker, optional story label, and an exact file path.
- Suggested MVP scope: **User Story 1** only.
- Validation commands should stay targeted to affected Terraform roots and must avoid remote apply operations unless explicitly requested later.
