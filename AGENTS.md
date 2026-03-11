# AGENTS.md

## Scope
These instructions apply to the entire repository unless a deeper `AGENTS.md` overrides them.

## Project Layout
- Root docs live in `README.md`.
- Infrastructure code lives under `docker-k8s-iac/`.
- Shell automation lives under `docker-k8s-iac/scripts/`.
- Kubernetes manifests live under `docker-k8s-iac/k8s/`.

## Working Agreement
- Keep changes focused on infrastructure automation, bootstrap flow, and related documentation.
- Prefer small, surgical edits that preserve the existing shell-script style.
- When changing behavior, update `README.md` if setup, prerequisites, or operator workflow changes.

## Shell Script Conventions
- Use `bash`-compatible syntax consistent with the existing scripts.
- Prefer explicit variable names and fail-fast patterns already present in the repo.
- Do not introduce new tool dependencies unless they are clearly necessary and documented.
- Preserve idempotency for bootstrap and provisioning scripts where possible.

## Validation
- For script changes, validate with the narrowest relevant command first.
- Avoid commands that mutate remote Docker, SSH, or Kubernetes resources unless the user explicitly asks for that execution.
- If a command depends on local secrets, remote hosts, or cluster access, note that limitation before running it.

## Safety
- Treat `.env` values, SSH targets, Docker contexts, and Kubernetes contexts as user-specific configuration.
- Never commit secrets, generated credentials, or machine-specific config changes unless the user explicitly requests it.
