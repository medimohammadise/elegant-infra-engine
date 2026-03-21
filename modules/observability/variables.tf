variable "namespace" {
  type        = string
  description = "Namespace where observability components are installed."
}

variable "elasticsearch" {
  type = object({
    enabled        = optional(bool, true)
    chart_version  = optional(string, "8.5.1")
    replicas       = optional(number, 1)
    minimum_master = optional(number, 1)
  })
  description = "Elasticsearch Helm settings for centralized log storage."
  default     = {}
}

variable "fluentd" {
  type = object({
    enabled       = optional(bool, true)
    chart_version = optional(string, "0.5.2")
  })
  description = "Fluentd Helm settings for log collection."
  default     = {}
}

variable "kibana" {
  type = object({
    enabled       = optional(bool, true)
    chart_version = optional(string, "8.5.1")
    expose_public = optional(bool, false)
    node_port     = optional(number, 32081)
    host_port     = optional(number, 7081)
    ingress = optional(object({
      enabled         = optional(bool, false)
      host            = string
      class_name      = optional(string)
      annotations     = optional(map(string), {})
      path            = optional(string, "/")
      path_type       = optional(string, "Prefix")
      tls_secret_name = optional(string)
    }))
  })
  description = "Kibana Helm settings for log exploration dashboards."
  default     = {}
}

variable "jaeger" {
  type = object({
    enabled          = optional(bool, true)
    chart_version    = optional(string, "3.4.1")
    expose_public    = optional(bool, false)
    query_node_port  = optional(number, 31686)
    query_host_port  = optional(number, 7068)
    collector_memory = optional(string, "256Mi")
    query_memory     = optional(string, "256Mi")
    ingress = optional(object({
      enabled         = optional(bool, false)
      host            = string
      class_name      = optional(string)
      annotations     = optional(map(string), {})
      path            = optional(string, "/")
      path_type       = optional(string, "Prefix")
      tls_secret_name = optional(string)
    }))
  })
  description = "Jaeger Helm settings for distributed tracing and APM-like visibility."
  default     = {}
}

variable "recreate_revision" {
  type        = string
  description = "Change this token to force replacement of observability releases."
  default     = ""
}
