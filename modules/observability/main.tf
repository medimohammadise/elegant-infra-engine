terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

locals {
  prometheus_enabled = try(var.prometheus.enabled, true)
  loki_enabled       = try(var.loki.enabled, false)
  tempo_enabled      = try(var.tempo.enabled, false)

  grafana_datasources = {
    apiVersion = 1
    datasources = concat(
      local.loki_enabled ? [
        {
          name      = "Loki"
          uid       = "loki"
          type      = "loki"
          access    = "proxy"
          url       = "http://${var.loki.release_name}.${var.namespace}.svc.cluster.local:3100"
          isDefault = false
        }
      ] : [],
      local.prometheus_enabled ? [
        {
          name      = "Prometheus"
          uid       = "prometheus"
          type      = "prometheus"
          access    = "proxy"
          url       = "http://${var.prometheus.release_name}-server.${var.namespace}.svc.cluster.local"
          isDefault = true
        }
      ] : [],
      local.tempo_enabled ? [
        {
          name      = "Tempo"
          uid       = "tempo"
          type      = "tempo"
          access    = "proxy"
          url       = "http://${var.tempo.release_name}.${var.namespace}.svc.cluster.local:3100"
          isDefault = !local.prometheus_enabled
          jsonData = {
            tracesToLogs = {
              datasourceUid = "loki"
            }
          }
        }
      ] : []
    )
  }
}

resource "terraform_data" "recreate" {
  input = var.recreate_revision
}

resource "helm_release" "loki" {
  count            = local.loki_enabled ? 1 : 0
  name             = var.loki.release_name
  repository       = var.loki.chart_repository
  chart            = var.loki.chart_name
  version          = var.loki.chart_version
  namespace        = var.namespace
  create_namespace = false

  values = [
    yamlencode({
      deploymentMode = "SingleBinary"
      loki = {
        commonConfig = {
          replication_factor = 1
        }
      }
      singleBinary = {
        replicas = 1
        persistence = {
          enabled = var.loki.persistence
          size    = var.loki.persistence_size
        }
      }
      backend = {
        replicas = 0
      }
      read = {
        replicas = 0
      }
      write = {
        replicas = 0
      }
      chunksCache = {
        enabled = false
      }
      resultsCache = {
        enabled = false
      }
      minio = {
        enabled = false
      }
      test = {
        enabled = false
      }
    })
  ]

  lifecycle {
    replace_triggered_by = [terraform_data.recreate]
  }
}

resource "helm_release" "tempo" {
  count            = local.tempo_enabled ? 1 : 0
  name             = var.tempo.release_name
  repository       = var.tempo.chart_repository
  chart            = var.tempo.chart_name
  version          = var.tempo.chart_version
  namespace        = var.namespace
  create_namespace = false

  values = [
    yamlencode({
      tempo = {
        metricsGenerator = {
          enabled = var.tempo.metrics_generator_enabled
        }
      }
      persistence = {
        enabled = var.tempo.persistence
        size    = var.tempo.persistence_size
      }
      serviceMonitor = {
        enabled = false
      }
      test = {
        enabled = false
      }
    })
  ]

  lifecycle {
    replace_triggered_by = [terraform_data.recreate]
  }
}

resource "helm_release" "prometheus" {
  count            = local.prometheus_enabled ? 1 : 0
  name             = var.prometheus.release_name
  repository       = var.prometheus.chart_repository
  chart            = var.prometheus.chart_name
  version          = var.prometheus.chart_version
  namespace        = var.namespace
  create_namespace = false

  values = [
    yamlencode({
      alertmanager = {
        enabled = false
      }
      pushgateway = {
        enabled = false
      }
      server = {
        service = {
          type     = var.prometheus.service_type
          nodePort = var.prometheus.service_type == "NodePort" ? var.prometheus.node_port : null
        }
        persistentVolume = {
          enabled = var.prometheus.persistence
          size    = var.prometheus.persistence_size
        }
      }
    })
  ]

  lifecycle {
    replace_triggered_by = [terraform_data.recreate]
  }
}

resource "helm_release" "grafana" {
  name             = var.grafana.release_name
  repository       = var.grafana.chart_repository
  chart            = var.grafana.chart_name
  version          = var.grafana.chart_version
  namespace        = var.namespace
  create_namespace = false

  values = [
    yamlencode({
      adminUser     = var.grafana.admin_user
      adminPassword = var.grafana.admin_password
      service = {
        type     = var.grafana.service_type
        nodePort = var.grafana.service_type == "NodePort" ? var.grafana.node_port : null
      }
      persistence = {
        enabled = var.grafana.persistence
        size    = var.grafana.persistence_size
      }
      datasources = {
        "datasources.yaml" = local.grafana_datasources
      }
      testFramework = {
        enabled = false
      }
    })
  ]

  depends_on = [
    helm_release.loki,
    helm_release.tempo,
    helm_release.prometheus,
  ]

  lifecycle {
    replace_triggered_by = [terraform_data.recreate]
  }
}
