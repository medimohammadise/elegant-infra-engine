# providers.tf

terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
    kind = {
      source  = "tehcyx/kind"
      version = "~> 0.5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

# The DOCKER_HOST for this provider natively manages containers on the remote context
provider "docker" {
  host = "ssh://${var.ssh_context_host}"
  ssh_opts = [
    "-o", "StrictHostKeyChecking=no",
    "-o", "UserKnownHostsFile=/dev/null",
    "-i", pathexpand(var.ssh_private_key_path)
  ]
}

# The kind provider uses the local `kind` CLI. 
# It MUST be run with DOCKER_HOST mapped to the remote host (e.g., DOCKER_HOST=ssh://myserver terraform apply)
provider "kind" {}

# Kubernetes and Helm providers are configured dynamically from the kind cluster outputs!
provider "kubernetes" {
  host                   = module.kind-cluster.endpoint
  client_certificate     = module.kind-cluster.client_certificate
  client_key             = module.kind-cluster.client_key
  cluster_ca_certificate = module.kind-cluster.cluster_ca_certificate
}

provider "helm" {
  kubernetes {
    host                   = module.kind-cluster.endpoint
    client_certificate     = module.kind-cluster.client_certificate
    client_key             = module.kind-cluster.client_key
    cluster_ca_certificate = module.kind-cluster.cluster_ca_certificate
  }
}
