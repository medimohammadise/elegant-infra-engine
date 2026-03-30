# Contributing

## Scope

This repository uses `CONTRIBUTING.md` as the source of truth for contributor workflow conventions, including Git commit structure. Human contributors and AI agents should follow the same rules.

## Architecture Principles

Contributors should preserve the project architecture described in `README.md`. In practice, that means:

- Keep deployable Terraform roots under `components/` and reusable building blocks under `modules/`.
- Prefer implementing reusable behavior in `modules/` and wiring it into `components/` rather than duplicating infrastructure logic across multiple roots.
- Preserve the split between the infra root (`components/infra`) and the standalone application roots. Keep the shared outputs aligned so that Keycloak, Grafana, Prometheus, and other services consume the expected host-port mappings.
- Preserve the split between roots that create foundational infrastructure and roots that deploy into an existing cluster.
- Treat `components/infra` (and, when needed, `components/kind-cluster`) as the roots that may create or modify the remote `kind` cluster and its host-port mappings.
- Treat `components/backstage`, `components/headlamp`, `components/keycloak`, and `components/observability` as roots that target an existing cluster unless explicitly reworked across the architecture.
- Keep public exposure settings consistent end to end: component variables, kind host-port mappings, Terraform outputs, and operator documentation must all match.
- Preserve the current service responsibilities in the observability stack:
  - Grafana for dashboards and trace UI
  - Loki for logs
  - Prometheus for metrics
  - Tempo for traces
  - Grafana Alloy or OpenTelemetry Collector as the collector-agent layer
- Keep infrastructure assumptions explicit when workloads depend on the Docker-hosted PostgreSQL pattern or the remote Docker-backed `kind` cluster.
- Maintain operator-facing docs when architecture, component boundaries, exposure model, prerequisites, or workflow expectations change.

When a change would violate one of these principles, either redesign it to fit the existing architecture or update the architecture docs and related roots together as one deliberate change.

## Commit Messages

Use semantic commit messages in the form:

```text
<type>: <summary>
```

Examples:

- `feat: observability`
- `fix: realign infra observability outputs`
- `docs: update README observability section`
- `refactor: simplify module outputs`
- `chore: refresh Terraform examples`

Prefer these commit types:

- `feat` for new user-visible capabilities
- `fix` for bug fixes or regressions
- `docs` for documentation-only changes
- `refactor` for structural changes without intended behavior change
- `chore` for maintenance, tooling, or non-feature housekeeping

Commit summaries should be short, imperative, and specific to the change.

## Squash Preference

Prefer a small, reviewable history. If a branch contains iterative fixup commits for one logical change, squash them before merging or pushing final review updates.

## Labels

If pull requests or issues use labels, keep them aligned with the commit intent and scope. Typical labels should reflect:

- change type, such as `feature`, `bug`, `docs`, or `chore`
- affected area, such as `terraform`, `observability`, `backstage`, `keycloak`, or `kind`

Do not invent new labels casually. Reuse the repository's existing label taxonomy when available.

## Versioning

When changes affect release notes, changelog generation, or version semantics, keep commit messages and PR descriptions clear enough to support downstream automation.

## Agent Guidance

AI agents working in this repository should:

- read this file before preparing commits
- prefer one semantic commit per logical change unless the user asks otherwise
- keep generated commit messages consistent with the conventions above
