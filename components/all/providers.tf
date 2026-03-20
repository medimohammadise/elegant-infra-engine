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
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
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

locals {
  kubeconfig_path = try(var.kubernetes.kubeconfig_path, null) != null ? var.kubernetes.kubeconfig_path : "${path.root}/${try(var.kubernetes.cluster_name, "blitzinfra")}-kubeconfig"
}

provider "docker" {
  host = "ssh://${var.ssh_context_host}"
  ssh_opts = [
    "-o", "StrictHostKeyChecking=no",
    "-o", "UserKnownHostsFile=/dev/null",
    "-i", pathexpand(var.ssh_private_key_path)
  ]
}

provider "kind" {}

provider "kubernetes" {
  config_path = local.kubeconfig_path
  insecure    = true
}

provider "helm" {
  kubernetes {
    config_path = local.kubeconfig_path
    insecure    = true
  }
}
