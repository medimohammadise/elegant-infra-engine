terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
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

provider "docker" {
  host = "ssh://${var.ssh_context_host}"
  ssh_opts = [
    "-o", "StrictHostKeyChecking=no",
    "-o", "UserKnownHostsFile=/dev/null",
    "-i", pathexpand(var.ssh_private_key_path)
  ]
}

provider "kubernetes" {
  config_path = var.kubeconfig_path
  insecure    = true
}

provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_path
    insecure    = true
  }
}
