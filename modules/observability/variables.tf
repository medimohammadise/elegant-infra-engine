variable "namespace" {
  type        = string
  description = "Namespace where the observability stack is installed."
}

variable "grafana" {
  type = object({
    release_name     = optional(string, "grafana")
    chart_repository = optional(string, "https://grafana.github.io/helm-charts")
    chart_name       = optional(string, "grafana")
    chart_version    = optional(string, "10.5.15")
    service_type     = optional(string, "ClusterIP")
    node_port        = optional(number)
    admin_user       = optional(string, "admin")
    admin_password   = optional(string, "admin")
    persistence      = optional(bool, false)
    persistence_size = optional(string, "5Gi")
  })
  description = "Grafana Helm release settings."
  default     = {}
}

variable "loki" {
  type = object({
    enabled          = optional(bool, false)
    release_name     = optional(string, "loki")
    chart_repository = optional(string, "https://grafana.github.io/helm-charts")
    chart_name       = optional(string, "loki")
    chart_version    = optional(string, "6.30.1")
    persistence      = optional(bool, false)
    persistence_size = optional(string, "10Gi")
  })
  description = "Loki Helm release settings."
  default     = {}
}

variable "tempo" {
  type = object({
    enabled                   = optional(bool, false)
    release_name              = optional(string, "tempo")
    chart_repository          = optional(string, "https://grafana.github.io/helm-charts")
    chart_name                = optional(string, "tempo")
    chart_version             = optional(string, "1.23.3")
    persistence               = optional(bool, false)
    persistence_size          = optional(string, "10Gi")
    metrics_generator_enabled = optional(bool, true)
  })
  description = "Tempo Helm release settings."
  default     = {}
}

variable "prometheus" {
  type = object({
    enabled          = optional(bool, true)
    release_name     = optional(string, "prometheus")
    chart_repository = optional(string, "https://prometheus-community.github.io/helm-charts")
    chart_name       = optional(string, "prometheus")
    chart_version    = optional(string, "27.20.0")
    service_type     = optional(string, "ClusterIP")
    node_port        = optional(number)
    persistence      = optional(bool, false)
    persistence_size = optional(string, "10Gi")
  })
  description = "Prometheus Helm release settings for metrics collection."
  default     = {}
}

variable "recreate_revision" {
  type        = string
  description = "Change this token to force replacement of observability Helm releases."
  default     = ""
}
