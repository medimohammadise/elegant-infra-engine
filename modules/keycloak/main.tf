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

resource "kubernetes_secret" "admin_credentials" {
  metadata {
    name      = "${var.name}-admin"
    namespace = var.namespace
  }

  data = {
    KEYCLOAK_ADMIN          = var.admin_username
    KEYCLOAK_ADMIN_PASSWORD = var.admin_password
  }

  type = "Opaque"

  lifecycle {
    replace_triggered_by = [terraform_data.recreate]
  }
}

resource "kubernetes_deployment" "this" {
  metadata {
    name      = var.name
    namespace = var.namespace
    labels = {
      app = var.name
    }
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        app = var.name
      }
    }

    template {
      metadata {
        labels = {
          app = var.name
        }
      }

      spec {
        container {
          name              = var.name
          image             = "${var.image_repository}:${var.image_tag}"
          image_pull_policy = "IfNotPresent"
          args              = ["start-dev", "--http-enabled=true", "--hostname-strict=false"]

          env {
            name = "KEYCLOAK_ADMIN"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.admin_credentials.metadata[0].name
                key  = "KEYCLOAK_ADMIN"
              }
            }
          }

          env {
            name = "KEYCLOAK_ADMIN_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.admin_credentials.metadata[0].name
                key  = "KEYCLOAK_ADMIN_PASSWORD"
              }
            }
          }

          port {
            container_port = 8080
            name           = "http"
          }

          readiness_probe {
            http_get {
              path = "/realms/master"
              port = 8080
            }

            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
          }

          liveness_probe {
            http_get {
              path = "/realms/master"
              port = 8080
            }

            initial_delay_seconds = 60
            period_seconds        = 15
            timeout_seconds       = 5
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
    name      = var.name
    namespace = var.namespace
    labels = {
      app = var.name
    }
  }

  spec {
    selector = {
      app = var.name
    }

    type = var.service_type

    port {
      name        = "http"
      port        = 80
      target_port = 8080
      node_port   = var.service_type == "NodePort" ? var.node_port : null
    }
  }

  lifecycle {
    replace_triggered_by = [terraform_data.recreate]
  }
}
