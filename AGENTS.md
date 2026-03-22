# AGENTS.md

## Scope
These instructions apply to the entire repository unless a deeper `AGENTS.md` overrides them.

## Project Layout
- Root docs live in `README.md`.
- Deployable Terraform roots live under `components/`.
- Reusable Terraform modules live under `modules/`.
- Shared helper scripts live under `scripts/`.
- Current component roots include `all`, `docker-registry`, `postgres`, `kind-cluster`, `backstage`, `headlamp`, `keycloak`, and `observability`.

## Working Agreement
- Keep changes focused on Terraform-based infrastructure automation, bootstrap flow, helper scripts, and related documentation.
- Prefer small, surgical edits that preserve the existing Terraform and shell style used in the repo.
- Preserve the split between reusable modules and deployable component roots; avoid duplicating module logic across `components/`.
- When changing behavior, update `README.md` if architecture, prerequisites, variables, or operator workflow changes.

## Terraform Conventions
- Follow the existing component and module patterns instead of introducing new layout conventions.
- Keep inputs explicit through `variables.tf`, surface useful values via `outputs.tf`, and keep provider setup scoped to the component roots.
- Prefer composing behavior from `modules/` inside `components/` rather than adding one-off resources directly to multiple roots.
- Preserve idempotency and support partial deployments where a component may be applied independently from `components/all`.
- Keep `components/all` aligned with the standalone component roots when shared capabilities are exposed there, especially for Keycloak and observability.
- For observability changes, preserve the separation between the deployable stack in `components/observability` and the reusable Helm logic in `modules/observability`.
- When exposing Grafana or Prometheus publicly, make sure the matching `kind` host-port mappings stay wired through `modules/kind-cluster` and any corresponding `components/all` outputs remain in sync.

## Shell Script Conventions
- Use `bash`-compatible syntax consistent with the existing scripts.
- Prefer explicit variable names and fail-fast patterns already present in the repo.
- Do not introduce new tool dependencies unless they are clearly necessary and documented.
- Preserve idempotency for bootstrap and provisioning scripts where possible.
- Keep helper scripts aligned with the current Terraform flow, such as post-render hooks used by Kubernetes-related components.

## Validation
- For Terraform changes, validate with the narrowest relevant command first, such as `terraform fmt -check`, `terraform validate`, or a targeted plan in the affected component root.
- For script changes, validate with the narrowest relevant command first.
- Avoid commands that mutate remote Docker, SSH, Terraform state, or Kubernetes resources unless the user explicitly asks for that execution.
- If a command depends on local secrets, SSH access, remote Docker, or cluster access, note that limitation before running it.
- Be careful with roots that create or modify the remote `kind` cluster; they may require `DOCKER_HOST` and `DOCKER_CONFIG` to be set as documented in `README.md`.
- For `components/all` plans that touch the remote `kind` cluster, use the Docker environment expected by the repo so Terraform can talk to the remote daemon through the `kind` provider.
- For observability changes in `components/all`, confirm the plan does not accidentally destroy the live `module.observability` resources when only documentation or variable wiring was intended to change.

## Safety
- Treat `terraform.tfvars`, SSH targets, Docker contexts, kubeconfig paths, and Kubernetes contexts as user-specific configuration.
- Never commit secrets, generated credentials, or machine-specific config changes unless the user explicitly requests it.
- Do not hardcode hostnames, private key paths, database passwords, tokens, or host-port mappings outside the documented examples.
