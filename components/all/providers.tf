terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
    external = {
      source  = "hashicorp/external"
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
  cluster_name            = try(var.kubernetes.cluster_name, "blitzinfra")
  kubeconfig_default_path = "${path.root}/../kubeconfigs/${local.cluster_name}-kubeconfig"
  kubeconfig_path = try(trimspace(var.kubernetes.kubeconfig_path), "") != "" ? var.kubernetes.kubeconfig_path : (
    fileexists(local.kubeconfig_default_path) ? local.kubeconfig_default_path : "${path.root}/../kubeconfigs/blitzinfra-kubeconfig"
  )
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
  config_path = local.kubeconfig_path
  insecure    = true
}

provider "helm" {
  kubernetes {
    config_path = local.kubeconfig_path
    insecure    = true
  }
}
