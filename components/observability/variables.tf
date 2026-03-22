variable "kubeconfig_path" {
  type        = string
  description = "Path to the kubeconfig file of the target cluster."
}

variable "cluster_name" {
  type        = string
  description = "kind cluster name used by the kubeconfig context."
  default     = "blitzinfra"
}

variable "api_server_host" {
  type        = string
  description = "Host name or IP exposed by the kind cluster for public services."
  default     = null
  nullable    = true
}

variable "observability" {
  type = object({
    namespace            = optional(string, "observability")
    expose_public        = optional(bool, false)
    grafana_node_port    = optional(number, 32300)
    grafana_host_port    = optional(number, 3000)
    prometheus_node_port = optional(number, 32090)
    prometheus_host_port = optional(number, 9090)
    grafana = optional(object({
      release_name     = optional(string, "grafana")
      chart_repository = optional(string, "https://grafana.github.io/helm-charts")
      chart_name       = optional(string, "grafana")
      chart_version    = optional(string, "10.5.15")
      admin_user       = optional(string, "admin")
      admin_password   = optional(string, "admin")
      persistence      = optional(bool, false)
      persistence_size = optional(string, "5Gi")
    }), {})
    loki = optional(object({
      enabled          = optional(bool, false)
      release_name     = optional(string, "loki")
      chart_repository = optional(string, "https://grafana.github.io/helm-charts")
      chart_name       = optional(string, "loki")
      chart_version    = optional(string, "6.30.1")
      persistence      = optional(bool, false)
      persistence_size = optional(string, "10Gi")
    }), {})
    tempo = optional(object({
      enabled                   = optional(bool, false)
      release_name              = optional(string, "tempo")
      chart_repository          = optional(string, "https://grafana.github.io/helm-charts")
      chart_name                = optional(string, "tempo")
      chart_version             = optional(string, "1.23.3")
      persistence               = optional(bool, false)
      persistence_size          = optional(string, "10Gi")
      metrics_generator_enabled = optional(bool, true)
    }), {})
    prometheus = optional(object({
      enabled          = optional(bool, true)
      release_name     = optional(string, "prometheus")
      chart_repository = optional(string, "https://prometheus-community.github.io/helm-charts")
      chart_name       = optional(string, "prometheus")
      chart_version    = optional(string, "27.20.0")
      persistence      = optional(bool, false)
      persistence_size = optional(string, "10Gi")
    }), {})
  })
  description = "Observability stack settings for Grafana, Loki, Tempo, and Prometheus."
  default     = {}
}

variable "recreate_revision" {
  type        = string
  description = "Change this token to force replacement of observability releases."
  default     = ""
}
