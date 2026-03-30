# Tasks: Platform Refactoring — Split Infra and Apps

**Input**: Design documents from `/specs/003-platform-refactoring/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Not requested — no test tasks included.

**Organization**: Tasks grouped by user story. US1 = Provision Infra Independently (P1), US2 = Deploy Apps Independently (P1), US3 = Full Stack Single Command (P2).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Paths are relative to repository root

## Path Conventions

- **Component roots**: `components/<name>/` (main.tf, variables.tf, outputs.tf, providers.tf, terraform.tfvars)
- **Modules**: `modules/<name>/` (unchanged)
- **Specs**: `specs/003-platform-refactoring/`

---

## Phase 1: Setup

**Purpose**: Clean up deprecated components and prepare directory structure

- [x] T001 Remove `components/docker-registry/` directory (all files including state)
- [x] T002 [P] Remove `modules/docker-registry/` directory
- [x] T003 [P] Remove `modules/docker-registry-ui/` directory
- [x] T004 [P] Remove `components/cluster-apps/` directory (empty placeholder)
- [x] T005 [P] Remove `modules/kafka-ui-proxy/` directory (lifecycle bug, unused going forward)
- [x] T006 Clean up `components/infra/` — remove existing symlink, prepare as empty component root

**Checkpoint**: Deprecated code removed. Directory structure ready for new components.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Build the infra component root — MUST complete before any app component work

**CRITICAL**: No user story work can begin until this phase is complete

- [x] T007 Create `components/infra/providers.tf` — declare docker (~> 3.0), kind, and external providers with SSH-based Docker host configuration. Use variables for `ssh_context_host` and `ssh_private_key_path`
- [x] T008 Create `components/infra/variables.tf` — define variables for: api_server_host, ssh_context_host, ssh_private_key_path, docker network config, postgres config (create, bind_address, port, db_name, user, password, volume_name), kubernetes config (create_cluster, cluster_name, api_server_port, worker_count, kind_node_image, kubeconfig_path, extra_port_mappings), recreate_revision
- [x] T009 Create `components/infra/main.tf` — call `modules/docker-network`, `modules/postgres`, and `modules/kind-cluster`. Wire variables to module inputs. Include `terraform_data.kind_cluster_ready` resource for signaling cluster readiness. Pass port mappings for all known services to kind-cluster module (backstage, headlamp, keycloak, grafana, prometheus, dependencytrack, kafka)
- [x] T010 Create `components/infra/outputs.tf` — expose all outputs per infra-outputs-contract.md: kubeconfig_path, cluster_name, kubernetes_api_endpoint, api_server_host, ssh_context_host, postgres_host, postgres_port, postgres_db_name, postgres_user, docker_network_name
- [x] T011 Create `components/infra/terraform.tfvars` — populate it with the infra-related values that the new root consumes (api_server_host, ssh_context_host, docker network, postgres, kubernetes settings)
- [x] T012 Validate infra component: run `terraform -chdir=components/infra fmt -check && terraform -chdir=components/infra validate`

**Checkpoint**: Infra component is a valid Terraform root. Can be planned/applied independently.

---

## Phase 3: User Story 1 — Provision Infrastructure Independently (Priority: P1) MVP

**Goal**: Operator can apply `components/infra` alone to get Docker network, PostgreSQL, and kind cluster running.

**Independent Test**: Run `terraform -chdir=components/infra apply`, then verify: kind cluster is running (`kubectl --kubeconfig=... get nodes`), PostgreSQL is accessible, Docker network exists. No apps deployed.

### Implementation for User Story 1

- [ ] T013 [US1] Apply infra component against remote Docker host: `DOCKER_CONFIG=/tmp/docker-empty-config DOCKER_HOST=ssh://myserver terraform -chdir=components/infra init && terraform -chdir=components/infra plan`
- [ ] T014 [US1] Fix any issues found during plan, iterate until `terraform plan` succeeds cleanly
- [ ] T015 [US1] Apply infra component: `terraform -chdir=components/infra apply` — verify Docker network, PostgreSQL container, and kind cluster are created
- [ ] T016 [US1] Verify outputs: `terraform -chdir=components/infra output` — confirm kubeconfig_path, cluster_name, postgres_host, postgres_port are populated
- [ ] T017 [US1] Verify cluster access: `kubectl --kubeconfig=<kubeconfig_path> get nodes` returns ready nodes

**Checkpoint**: Infra layer is fully functional and independently deployable. Outputs available for app consumption.

---

## Phase 4: User Story 2 — Deploy Applications Independently (Priority: P1)

**Goal**: Each application is a standalone component root that reads infra via remote state and can be applied/destroyed independently.

**Independent Test**: With infra running, apply any single app component (e.g., `components/headlamp`) and verify the app is reachable. Destroy it and verify infra + other apps are unaffected.

### 4a: Refactor Backstage Component

- [ ] T018 [P] [US2] Update `components/backstage/providers.tf` — add kubernetes + helm providers using `var.kubeconfig_path` (keep existing pattern)
- [ ] T019 [P] [US2] Update `components/backstage/main.tf` — add `terraform_remote_state.infra` data source (path = `${path.module}/../infra/terraform.tfstate`). Update `postgres_host` and `postgres_port` references to use remote state outputs. Keep module call to `modules/backstage`
- [ ] T020 [US2] Update `components/backstage/variables.tf` — remove any infra-level variables that are now from remote state. Keep app-specific variables (image, chart, keycloak config, passwords). Add `kubeconfig_path` variable with default `"../kubeconfigs/blitzinfra-kubeconfig"`
- [ ] T021 [US2] Update `components/backstage/outputs.tf` — ensure `namespace` and `exposed_urls` outputs exist per component contract
- [ ] T022 [US2] Update `components/backstage/terraform.tfvars` — remove infra values, keep only backstage-specific config

### 4b: Refactor Headlamp Component

- [ ] T023 [P] [US2] Update `components/headlamp/providers.tf` — ensure kubernetes + helm providers use `var.kubeconfig_path`
- [ ] T024 [P] [US2] Update `components/headlamp/main.tf` — add `terraform_remote_state.infra` data source. Keep module call to `modules/headlamp`
- [ ] T025 [US2] Update `components/headlamp/variables.tf` — add `kubeconfig_path` variable with default. Remove any infra-level variables
- [ ] T026 [US2] Update `components/headlamp/outputs.tf` — ensure `namespace` and `exposed_urls` outputs per contract
- [ ] T027 [US2] Update `components/headlamp/terraform.tfvars` — keep only headlamp-specific config

### 4c: Refactor Kafka Component

- [ ] T028 [P] [US2] Update `components/kafka/providers.tf` — ensure kubernetes + helm + docker providers. Docker provider uses `ssh_context_host` from remote state for socat proxies
- [ ] T029 [P] [US2] Update `components/kafka/main.tf` — add `terraform_remote_state.infra` data source. Keep module call to `modules/kafka`. Replace kafka-ui-proxy module calls with direct `docker_image` + `docker_container` resources for socat proxies (per CLAUDE.md guidance — kafka-ui-proxy has lifecycle bug)
- [ ] T030 [US2] Update `components/kafka/variables.tf` — add `kubeconfig_path` and `ssh_private_key_path` variables. Remove infra-level variables
- [ ] T031 [US2] Update `components/kafka/outputs.tf` — ensure `namespace` and `exposed_urls` outputs per contract
- [ ] T032 [US2] Update `components/kafka/terraform.tfvars` — keep only kafka-specific config

### 4d: Refactor Keycloak Component

- [ ] T033 [P] [US2] Update `components/keycloak/providers.tf` — ensure kubernetes + helm providers use `var.kubeconfig_path`
- [ ] T034 [P] [US2] Update `components/keycloak/main.tf` — add `terraform_remote_state.infra` data source. Wire postgres_host/port from remote state. Keep module call to `modules/keycloak`
- [ ] T035 [US2] Update `components/keycloak/variables.tf` — add `kubeconfig_path` variable with default. Remove infra-level variables. Keep keycloak-specific vars and `postgres_password`
- [ ] T036 [US2] Update `components/keycloak/outputs.tf` — ensure `namespace` and `exposed_urls` outputs per contract
- [ ] T037 [US2] Create `components/keycloak/terraform.tfvars` (currently only .example exists) — populate with keycloak-specific config

### 4e: Refactor Observability Component

- [ ] T038 [P] [US2] Update `components/observability/providers.tf` — ensure kubernetes + helm providers use `var.kubeconfig_path`
- [ ] T039 [P] [US2] Update `components/observability/main.tf` — add `terraform_remote_state.infra` data source. Keep module call to `modules/observability`
- [ ] T040 [US2] Update `components/observability/variables.tf` — add `kubeconfig_path` variable with default. Remove infra-level variables
- [ ] T041 [US2] Update `components/observability/outputs.tf` — ensure `namespace` and `exposed_urls` outputs per contract
- [ ] T042 [US2] Update `components/observability/terraform.tfvars` — keep only observability-specific config

### 4f: Refactor Dependency-Track Component

- [ ] T043 [P] [US2] Update `components/dependencytrack/main.tf` — add `terraform_remote_state.infra` data source. Wire postgres_host/port and api_server_host from remote state. Include socat proxy resources using direct docker_image + docker_container pattern (not kafka-ui-proxy module)
- [ ] T044 [P] [US2] Create `components/dependencytrack/providers.tf` — kubernetes + helm + docker providers (docker for socat proxies)
- [ ] T045 [US2] Create `components/dependencytrack/variables.tf` — add `kubeconfig_path`, `ssh_private_key_path`, and dependencytrack-specific variables. Keep `postgres_password`
- [ ] T046 [US2] Create `components/dependencytrack/outputs.tf` — ensure `namespace` and `exposed_urls` outputs per contract
- [ ] T047 [US2] Verify `components/dependencytrack/terraform.tfvars` exists with dependencytrack-specific config

### 4g: Validate All App Components

- [ ] T048 [US2] Run `terraform validate` on each app component: backstage, headlamp, kafka, keycloak, observability, dependencytrack
- [ ] T049 [US2] Run `terraform plan` on each app component (with infra state present) — verify no errors
- [ ] T050 [US2] Apply one app component (e.g., headlamp) and verify it deploys and is reachable
- [ ] T051 [US2] Destroy that app component and verify infra remains healthy

**Checkpoint**: All 6 app components are standalone, follow the component contract, and can be independently applied/destroyed.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Documentation, cleanup, and validation across all components

- [x] T058 [P] Update `CLAUDE.md` — describe the two-layer architecture, remove registry references, and refresh the commands operators use for infra-first deployment
- [x] T059 [P] Rewrite `README.md` — document the infra/app split, remote-state contract, workflows, and component outputs that replaced the old combined root
- [x] T060 Remove stale registry references and apply the new layout requirements across documentation (`README.md`, `TROUBLESHOOTING.md`, `AGENTS.md`, `CONTRIBUTING.md`, etc.)
- [x] T061 Update `specs/003-platform-refactoring` (spec, plan, tasks, quickstart, contracts) to spell out the infra-first workflow, remote-state requirements, and the absence of `components/all`
- [ ] T062 Run quickstart.md validation — follow the quickstart guide end-to-end to confirm both deployment options work

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup (T001-T006) — BLOCKS all user stories
- **US1 (Phase 3)**: Depends on Foundational (T007-T012) — validates infra works
- **US2 (Phase 4)**: Depends on US1 completion (infra must be running for app components to plan/validate)
- **Polish (Phase 6)**: Depends on US1 + US2

### User Story Dependencies

- **US1 (Infra)**: Can start after Foundational — no story dependencies
- **US2 (Apps)**: Depends on US1 (infra state must exist for remote state data source)

### Within User Story 2 (App Components)

All 6 app refactoring sub-phases (4a–4f) are **parallelizable** — they modify different component directories:
- 4a: Backstage (T018–T022)
- 4b: Headlamp (T023–T027)
- 4c: Kafka (T028–T032)
- 4d: Keycloak (T033–T037)
- 4e: Observability (T038–T042)
- 4f: Dependency-Track (T043–T047)

Validation tasks (T048–T051) must wait for all 6 sub-phases.

### Parallel Opportunities

```text
Phase 1: T002 + T003 + T004 + T005 in parallel
Phase 2: T007 + T008 in parallel, then T009 + T010, then T011
Phase 4: All sub-phases 4a–4f in parallel (different directories)
Phase 6: T058 + T059 in parallel
```

---

## Parallel Example: User Story 2

```bash
# Launch all app component refactors in parallel (different directories):
Task: "Update components/backstage/main.tf — add terraform_remote_state.infra"
Task: "Update components/headlamp/main.tf — add terraform_remote_state.infra"
Task: "Update components/kafka/main.tf — add terraform_remote_state.infra"
Task: "Update components/keycloak/main.tf — add terraform_remote_state.infra"
Task: "Update components/observability/main.tf — add terraform_remote_state.infra"
Task: "Update components/dependencytrack/main.tf — add terraform_remote_state.infra"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (remove deprecated code)
2. Complete Phase 2: Foundational (build infra component)
3. Complete Phase 3: US1 (validate infra works independently)
4. **STOP and VALIDATE**: Infra deploys independently, outputs are correct
5. This alone delivers value — infra can be managed without touching apps

### Incremental Delivery

1. Setup + Foundational + US1 → Infra is standalone (MVP!)
2. Add US2 → Each app is standalone → Full modularity achieved
3. Polish → Documentation and validation complete

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. One developer: US1 (validate infra)
3. Once US1 passes, 6 developers can each take one app component (4a–4f)
4. One developer: US3 (combined root) after US2 patterns established
5. All: Polish phase

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story
- `postgres_password` is NEVER in remote state — always via tfvars
- `kubeconfig_path` uses variable (not remote state) due to Terraform provider limitation
- Do NOT use `modules/kafka-ui-proxy` — use direct docker_image + docker_container (CLAUDE.md)
- Commit after each task or logical group
- Stop at any checkpoint to validate independently
