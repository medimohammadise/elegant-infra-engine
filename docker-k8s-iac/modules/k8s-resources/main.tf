# main.tf

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
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
