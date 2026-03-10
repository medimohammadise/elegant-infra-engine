# BlitzInfra

This repository contains the infrastructure bootstrap scripts under `docker-k8s-iac/`.

## Bootstrap Infra

## Prerequisites

- SSH access to the Docker host used by `DOCKER_CONTEXT`
- `docker`, `kubectl`, `curl`, `ssh`, and `scp` installed locally
- Docker Compose support via `docker compose` or `docker-compose`
- `docker` and `kind` installed on the remote host if you want Kubernetes provisioning
- If your local Docker config references a missing credential helper such as `docker-credential-desktop`, the scripts fall back to a temporary clean Docker config for public image pulls

Example checks:

```bash
curl http://myserver:5000/v2/
docker context ls
kubectl config get-contexts
```

If the Docker context does not exist yet, `bootstrap.sh` creates it automatically from `.env`:

```env
DOCKER_CONTEXT=myserver
DOCKER_CONTEXT_HOST=myserver
DOCKER_CONTEXT_USER=mehdi
```

That is equivalent to:

```bash
docker context create myserver --docker "host=ssh://mehdi@myserver"
```

If passwordless SSH is not ready yet, `bootstrap.sh` runs:

```bash
./scripts/setup-ssh-access.sh
```

That script:

- creates an SSH key if you do not already have one
- prompts once for the remote account password
- installs your public key on the remote host with `ssh-copy-id`
- verifies passwordless SSH before continuing

If the Kubernetes context does not exist yet, run:

```bash
./scripts/provision-kind-cluster.sh
```

That script provisions a remote `kind` cluster with 5 nodes total:

- 1 control-plane node
- 4 worker nodes
- Kubernetes API exposed on `${KIND_API_SERVER_HOST}:${KIND_API_SERVER_PORT}`
- local `kubectl` context imported as `KUBE_CONTEXT`

If the context is not reachable and `KUBE_REQUIRED=false`, bootstrap skips the namespace apply step.

1. Move into the infra directory:

```bash
cd docker-k8s-iac
```

2. Create your environment file from the example:

```bash
cp .env.example .env
```

3. Update `.env` with the values for your server and cluster:

```env
REGISTRY_URL=http://myserver:5000
REGISTRY_PROXY_PASS_URL=http://myserver:5000
REGISTRY_TITLE="Remote Docker Registry"
REGISTRY_BIND_ADDRESS=0.0.0.0
UI_BIND_ADDRESS=127.0.0.1
DOCKER_CONTEXT=myserver
DOCKER_CONTEXT_HOST=myserver
DOCKER_CONTEXT_USER=mehdi
KUBE_CONTEXT=myserver
KUBE_REQUIRED=false
KUBE_NAMESPACE=BlitzPay-DEV
KIND_CLUSTER_NAME=blitzinfra
KIND_WORKER_COUNT=4
KIND_API_SERVER_PORT=6443
KIND_API_SERVER_HOST=myserver
KIND_WAIT_DURATION=300s
KIND_PROVISION_ON_BOOTSTRAP=false
IMAGE_REGISTRY=myserver:5000
IMAGE_NAME=sample-app
IMAGE_TAG=latest
```

4. Make sure the scripts are executable if needed:

```bash
chmod +x scripts/*.sh
```

5. Run the infra bootstrap command:

```bash
./scripts/bootstrap.sh
```

This bootstrap script runs the following steps:

- validates required local commands and Kubernetes context
- creates the Docker context from `.env` if it is missing
- optionally provisions the remote `kind` cluster when `KIND_PROVISION_ON_BOOTSTRAP=true`
- ensures the remote `registry` container is running on port `5000`
- waits for the remote registry health endpoint to respond
- starts `registry-ui` with Docker Compose on the remote Docker context
- applies the Kubernetes namespace from `k8s/namespace.yaml` when the configured cluster is reachable

## Optional Commands

Build and push an image:

```bash
./scripts/build-and-push.sh .
```

Start the remote registry and UI:

```bash
./scripts/compose-up-remote.sh
```

Provision the remote 5-node `kind` cluster:

```bash
./scripts/provision-kind-cluster.sh
```

Apply the Kubernetes namespace only:

```bash
./scripts/apply-namespace.sh
```
