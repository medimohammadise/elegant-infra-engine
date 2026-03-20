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
  chart            = var.chart_url
  namespace        = var.namespace
  create_namespace = false

  values = [
    yamlencode({
      kong = {
        proxy = {
          type = var.service_type
          http = {
            enabled = false
          }
          tls = var.service_type == "NodePort" ? {
            nodePort = var.node_port
          } : {}
        }
      }
    })
  ]

  lifecycle {
    replace_triggered_by = [terraform_data.recreate]
  }
}

resource "kubernetes_service_account" "admin_user" {
  count = var.create_admin_user ? 1 : 0

  metadata {
    name      = var.admin_user_name
    namespace = var.namespace
  }

  depends_on = [helm_release.this]

  lifecycle {
    replace_triggered_by = [terraform_data.recreate]
  }
}

resource "kubernetes_cluster_role_binding" "admin_user" {
  count = var.create_admin_user ? 1 : 0

  metadata {
    name = var.admin_user_name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    api_group = ""
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.admin_user[0].metadata[0].name
    namespace = kubernetes_service_account.admin_user[0].metadata[0].namespace
  }

  lifecycle {
    replace_triggered_by = [terraform_data.recreate]
  }
}
