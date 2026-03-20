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

resource "helm_release" "elasticsearch" {
  count = var.elasticsearch.enabled ? 1 : 0

  name             = "elasticsearch"
  repository       = "https://helm.elastic.co"
  chart            = "elasticsearch"
  version          = var.elasticsearch.chart_version
  namespace        = var.namespace
  create_namespace = false
  timeout          = 900

  values = [
    yamlencode({
      replicas = var.elasticsearch.replicas
      minimumMasterNodes = var.elasticsearch.minimum_master
      resources = {
        requests = {
          cpu    = "200m"
          memory = "512Mi"
        }
        limits = {
          cpu    = "1000m"
          memory = "1Gi"
        }
      }
      persistence = {
        enabled = false
      }
    })
  ]

  lifecycle {
    replace_triggered_by = [terraform_data.recreate]
  }
}

resource "helm_release" "kibana" {
  count = var.kibana.enabled ? 1 : 0

  name             = "kibana"
  repository       = "https://helm.elastic.co"
  chart            = "kibana"
  version          = var.kibana.chart_version
  namespace        = var.namespace
  create_namespace = false
  timeout          = 900

  values = [
    yamlencode({
      service = {
        type = var.kibana.expose_public ? "NodePort" : "ClusterIP"
        nodePort = var.kibana.expose_public ? var.kibana.node_port : null
      }
      elasticsearchHosts = "http://elasticsearch-master:9200"
    })
  ]

  depends_on = [helm_release.elasticsearch]

  lifecycle {
    replace_triggered_by = [terraform_data.recreate]
  }
}

resource "helm_release" "fluentd" {
  count = var.fluentd.enabled ? 1 : 0

  name             = "fluentd"
  repository       = "https://fluent.github.io/helm-charts"
  chart            = "fluentd"
  version          = var.fluentd.chart_version
  namespace        = var.namespace
  create_namespace = false
  timeout          = 900

  values = [
    yamlencode({
      kind = "DaemonSet"
      env = [
        {
          name  = "FLUENT_ELASTICSEARCH_HOST"
          value = "elasticsearch-master"
        },
        {
          name  = "FLUENT_ELASTICSEARCH_PORT"
          value = "9200"
        }
      ]
      fileConfigs = {
        "01_sources.conf" = <<-EOT
          <source>
            @type tail
            @id in_tail_container_logs
            @label @KUBERNETES
            path /var/log/containers/*.log
            pos_file /var/log/fluentd-containers.log.pos
            tag kubernetes.*
            read_from_head true
            <parse>
              @type multi_format
              <pattern>
                format json
                time_key time
                time_type string
                time_format %Y-%m-%dT%H:%M:%S.%NZ
              </pattern>
              <pattern>
                format regexp
                expression /^(?<time>.+) (?<stream>stdout|stderr) [^ ]* (?<log>.*)$/
                time_format %Y-%m-%dT%H:%M:%S.%N%:z
              </pattern>
            </parse>
          </source>
        EOT
        "04_outputs.conf" = <<-EOT
          <label @OUTPUT>
            <match **>
              @type elasticsearch
              host "#{ENV['FLUENT_ELASTICSEARCH_HOST']}"
              port "#{ENV['FLUENT_ELASTICSEARCH_PORT']}"
              scheme http
              logstash_format true
              include_tag_key true
              reconnect_on_error true
              reload_on_failure true
              request_timeout 30s
            </match>
          </label>
        EOT
      }
    })
  ]

  depends_on = [helm_release.elasticsearch]

  lifecycle {
    replace_triggered_by = [terraform_data.recreate]
  }
}

resource "helm_release" "jaeger" {
  count = var.jaeger.enabled ? 1 : 0

  name             = "jaeger"
  repository       = "https://jaegertracing.github.io/helm-charts"
  chart            = "jaeger"
  version          = var.jaeger.chart_version
  namespace        = var.namespace
  create_namespace = false
  timeout          = 900

  values = [
    yamlencode({
      provisionDataStore = {
        cassandra = false
        elasticsearch = false
      }
      allInOne = {
        enabled = true
      }
      storage = {
        type = "memory"
      }
      query = {
        service = {
          type     = var.jaeger.expose_public ? "NodePort" : "ClusterIP"
          nodePort = var.jaeger.expose_public ? var.jaeger.query_node_port : null
        }
        resources = {
          requests = {
            cpu    = "100m"
            memory = var.jaeger.query_memory
          }
        }
      }
      collector = {
        resources = {
          requests = {
            cpu    = "100m"
            memory = var.jaeger.collector_memory
          }
        }
      }
    })
  ]

  lifecycle {
    replace_triggered_by = [terraform_data.recreate]
  }
}
