terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

locals {
  labels = {
    app = var.name
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
    KC_BOOTSTRAP_ADMIN_USERNAME = var.admin_username
    KC_BOOTSTRAP_ADMIN_PASSWORD = var.admin_password
    KC_DB_PASSWORD              = var.database_password
  }

  type = "Opaque"
}

resource "kubernetes_deployment" "this" {
  metadata {
    name      = var.name
    namespace = var.namespace
    labels    = local.labels
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = local.labels
    }

    template {
      metadata {
        labels = local.labels
      }

      spec {
        container {
          name  = var.name
          image = var.image
          args = [
            "start-dev",
            "--http-enabled=true",
            "--hostname-strict=false",
          ]

          env {
            name = "KC_BOOTSTRAP_ADMIN_USERNAME"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.admin_credentials.metadata[0].name
                key  = "KC_BOOTSTRAP_ADMIN_USERNAME"
              }
            }
          }

          env {
            name = "KC_BOOTSTRAP_ADMIN_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.admin_credentials.metadata[0].name
                key  = "KC_BOOTSTRAP_ADMIN_PASSWORD"
              }
            }
          }

          env {
            name  = "KC_DB"
            value = "postgres"
          }

          env {
            name  = "KC_DB_URL"
            value = "jdbc:postgresql://${var.database_host}:${var.database_port}/${var.database_name}"
          }

          env {
            name  = "KC_DB_USERNAME"
            value = var.database_user
          }

          env {
            name = "KC_DB_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.admin_credentials.metadata[0].name
                key  = "KC_DB_PASSWORD"
              }
            }
          }

          env {
            name  = "KC_HEALTH_ENABLED"
            value = "true"
          }

          env {
            name  = "KC_METRICS_ENABLED"
            value = "true"
          }

          env {
            name  = "JAVA_OPTS_KC_HEAP"
            value = var.java_opts_kc_heap
          }

          port {
            name           = "http"
            container_port = 8080
          }

          resources {
            limits = {
              memory = var.memory_limit
            }

            requests = {
              cpu    = var.cpu_request
              memory = var.memory_request
            }
          }

          startup_probe {
            http_get {
              path   = "/health/started"
              port   = 9000
              scheme = "HTTP"
            }

            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 30
          }

          readiness_probe {
            http_get {
              path   = "/health/ready"
              port   = 9000
              scheme = "HTTP"
            }

            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          liveness_probe {
            http_get {
              path   = "/health/live"
              port   = 9000
              scheme = "HTTP"
            }

            initial_delay_seconds = 60
            period_seconds        = 15
            timeout_seconds       = 5
            failure_threshold     = 3
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
    labels    = local.labels
  }

  spec {
    selector = local.labels
    type     = var.service_type

    port {
      name        = "http"
      port        = 80
      target_port = 8080
      node_port   = var.service_type == "NodePort" ? var.node_port : null
    }
  }

  depends_on = [kubernetes_deployment.this]
}
