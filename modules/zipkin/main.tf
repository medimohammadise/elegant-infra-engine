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

resource "kubernetes_deployment" "this" {
  metadata {
    name      = var.release_name
    namespace = var.namespace
    labels = {
      app = var.release_name
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = var.release_name
      }
    }

    template {
      metadata {
        labels = {
          app = var.release_name
        }
      }

      spec {
        container {
          name  = "zipkin"
          image = var.image

          port {
            container_port = var.service_port
            name           = "http"
          }
        }
      }
    }
  }

  lifecycle {
    replace_triggered_by = [terraform_data.recreate]
  }
}

resource "kubernetes_service" "this" {
  metadata {
    name      = var.release_name
    namespace = var.namespace
  }

  spec {
    selector = {
      app = var.release_name
    }

    type = var.service_type

    port {
      name        = "http"
      port        = var.service_port
      target_port = var.service_port
      node_port   = var.service_type == "NodePort" ? var.node_port : null
    }
  }

  lifecycle {
    replace_triggered_by = [terraform_data.recreate]
  }
}
