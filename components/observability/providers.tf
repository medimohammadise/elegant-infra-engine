terraform {
  required_providers {
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

provider "kubernetes" {
  config_path = local.resolved_kubeconfig_path
  insecure    = true
}

provider "helm" {
  kubernetes {
    config_path = local.resolved_kubeconfig_path
    insecure    = true
  }
}


locals {
  requested_kubeconfig_path = var.kubeconfig_path != null ? pathexpand(var.kubeconfig_path) : "${path.root}/../kind-cluster/${var.cluster_name}-kubeconfig"
  resolved_kubeconfig_path  = fileexists(local.requested_kubeconfig_path) ? local.requested_kubeconfig_path : null
}
