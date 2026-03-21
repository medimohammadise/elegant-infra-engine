terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

resource "terraform_data" "recreate" {
  input = var.recreate_revision
}

resource "helm_release" "this" {
  name             = var.release_name
  repository       = var.chart_repository
  chart            = var.chart_name
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = false

  values = [
    yamlencode({
      config = {
        inCluster = true
      }
      service = {
        type     = var.service_type
        nodePort = var.service_type == "NodePort" ? var.node_port : null
      }
      serviceAccount = {
        create = var.create_service_account
        name   = var.service_account_name
      }
      clusterRoleBinding = {
        create          = var.create_cluster_role_binding
        clusterRoleName = var.cluster_role_name
      }
    })
  ]

  lifecycle {
    replace_triggered_by = [terraform_data.recreate]
  }
}
