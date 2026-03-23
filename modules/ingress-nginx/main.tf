terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

resource "terraform_data" "recreate" {
  input = var.recreate_revision
}

resource "helm_release" "this" {
  name             = var.release_name
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = true
  timeout          = 900

  values = [
    yamlencode({
      controller = {
        ingressClassResource = {
          name    = var.ingress_class_name
          default = var.default_ingress_class
        }
        ingressClass = var.ingress_class_name
        service = {
          type = "NodePort"
          nodePorts = {
            http  = var.http_node_port
            https = var.https_node_port
          }
        }
      }
    })
  ]

  lifecycle {
    replace_triggered_by = [terraform_data.recreate]
  }
}
