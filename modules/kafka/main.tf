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

locals {
  kafka_bootstrap_servers = (
    var.kafka.expose_public
    ? format("%s-broker-headless.%s.svc.cluster.local:9092", var.kafka.release_name, var.namespace)
    : format("%s.%s.svc.cluster.local:9092", var.kafka.release_name, var.namespace)
  )
  kafka_public_bootstrap_servers = (
    var.kafka.expose_public && var.api_server_host != null
    ? "${var.api_server_host}:${var.kafka.external_host_port}"
    : null
  )
  dashboard_bootstrap_servers = format("%s-broker-headless.%s.svc.cluster.local:9092", var.kafka.release_name, var.namespace)
  dashboard_service_type      = var.kafka.expose_dashboard_public ? "NodePort" : "ClusterIP"
  dashboard_node_port         = var.kafka.expose_dashboard_public ? var.kafka.dashboard_node_port : null
  dashboard_url = (
    var.kafka.expose_dashboard_public && var.api_server_host != null
    ? "http://${var.api_server_host}:${var.kafka.dashboard_host_port}"
    : null
  )
}

resource "terraform_data" "recreate" {
  input = var.recreate_revision
}

resource "helm_release" "kafka" {
  name             = var.kafka.release_name
  repository       = var.kafka.chart_repository
  chart            = var.kafka.chart_name
  version          = try(var.kafka.chart_version, null)
  namespace        = var.namespace
  create_namespace = false

  values = [
    yamlencode({
      global = {
        security = {
          allowInsecureImages = true
        }
      }
      kraft = {
        enabled = true
      }
      zookeeper = {
        enabled = false
      }
      listeners = {
        client = {
          protocol = "PLAINTEXT"
        }
        external = {
          protocol = "PLAINTEXT"
        }
        advertisedListeners = (
          var.kafka.expose_public && var.api_server_host != null
          ? "CLIENT://${var.kafka.release_name}-broker-headless.${var.namespace}.svc.cluster.local:9092,EXTERNAL://${var.api_server_host}:${var.kafka.external_host_port}"
          : ""
        )
        securityProtocolMap = (
          var.kafka.expose_public
          ? "CLIENT:PLAINTEXT,CONTROLLER:PLAINTEXT,INTERNAL:PLAINTEXT,EXTERNAL:PLAINTEXT"
          : ""
        )
      }
      image = {
        registry   = var.kafka.image_registry
        repository = var.kafka.image_repository
        tag        = var.kafka.image_tag
      }
      controller = {
        replicaCount = var.kafka.controller_replica_count
        persistence = {
          enabled = var.kafka.persistence_enabled
          size    = var.kafka.persistence_size
        }
      }
      broker = {
        replicaCount = var.kafka.broker_replica_count
        persistence = {
          enabled = var.kafka.persistence_enabled
          size    = var.kafka.persistence_size
        }
      }
      externalAccess = {
        enabled = var.kafka.expose_public
      }
    })
  ]

  lifecycle {
    replace_triggered_by = [terraform_data.recreate]
  }
}

resource "helm_release" "dashboard" {
  name             = var.kafka.dashboard.release_name
  repository       = var.kafka.dashboard.chart_repository
  chart            = var.kafka.dashboard.chart_name
  version          = try(var.kafka.dashboard.chart_version, null)
  namespace        = var.namespace
  create_namespace = false

  values = [
    yamlencode({
      yamlApplicationConfig = {
        kafka = {
          clusters = [
            {
              name             = var.kafka.release_name
              bootstrapServers = local.dashboard_bootstrap_servers
            }
          ]
        }
      }
      service = {
        type     = local.dashboard_service_type
        nodePort = local.dashboard_node_port
      }
    })
  ]

  depends_on = [helm_release.kafka]

  lifecycle {
    replace_triggered_by = [terraform_data.recreate]
  }
}

resource "kubernetes_service" "kafka_external" {
  count = var.kafka.expose_public ? 1 : 0

  metadata {
    name      = "${var.kafka.release_name}-external"
    namespace = var.namespace
  }

  spec {
    selector = {
      "app.kubernetes.io/component" = "broker"
      "app.kubernetes.io/instance"  = var.kafka.release_name
      "app.kubernetes.io/name"      = "kafka"
      "app.kubernetes.io/part-of"   = "kafka"
    }

    port {
      name        = "external"
      port        = var.kafka.external_host_port
      protocol    = "TCP"
      target_port = 9095
      node_port   = var.kafka.external_node_port
    }

    type = "NodePort"
  }

  depends_on = [helm_release.kafka]
}
