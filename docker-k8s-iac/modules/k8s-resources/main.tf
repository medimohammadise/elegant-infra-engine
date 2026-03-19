# main.tf

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

resource "terraform_data" "recreate" {
  input = var.recreate_revision
}

resource "kubernetes_namespace" "blitzpay" {
  metadata {
    name = var.kube_namespace
    labels = {
      name = var.kube_namespace
    }
  }

  lifecycle {
    replace_triggered_by = [terraform_data.recreate]
  }
}

resource "helm_release" "kubernetes_dashboard" {
  count = var.enable_k8s_dashboard ? 1 : 0

  name             = "kubernetes-dashboard"
  chart            = var.k8s_dashboard_chart_url
  namespace        = var.dashboard_namespace
  create_namespace = true
  values = [
    yamlencode({
      kong = {
        proxy = {
          type = var.expose_dashboard_public ? "NodePort" : "ClusterIP"
          http = {
            enabled = false
          }
          tls = var.expose_dashboard_public ? {
            nodePort = var.dashboard_node_port
          } : {}
        }
      }
    })
  ]

  depends_on = [kubernetes_namespace.blitzpay]

  lifecycle {
    replace_triggered_by = [terraform_data.recreate]
  }
}

resource "kubernetes_service_account" "dashboard_admin_user" {
  count = var.enable_k8s_dashboard && var.create_dashboard_admin_user ? 1 : 0

  metadata {
    name      = var.dashboard_admin_user_name
    namespace = var.dashboard_namespace
  }

  depends_on = [helm_release.kubernetes_dashboard]

  lifecycle {
    replace_triggered_by = [terraform_data.recreate]
  }
}

resource "kubernetes_cluster_role_binding" "dashboard_admin_user" {
  count = var.enable_k8s_dashboard && var.create_dashboard_admin_user ? 1 : 0

  metadata {
    name = var.dashboard_admin_user_name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    api_group = ""
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.dashboard_admin_user[0].metadata[0].name
    namespace = kubernetes_service_account.dashboard_admin_user[0].metadata[0].namespace
  }

  lifecycle {
    replace_triggered_by = [terraform_data.recreate]
  }
}
