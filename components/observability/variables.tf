variable "kubeconfig_path" {
  type        = string
  description = "Path to the kubeconfig file of the target cluster."
}

variable "observability" {
  type = object({
    namespace = optional(string, "observability")
    elasticsearch = optional(object({
      enabled        = optional(bool, true)
      chart_version  = optional(string, "8.5.1")
      replicas       = optional(number, 1)
      minimum_master = optional(number, 1)
    }), {})
    fluentd = optional(object({
      enabled       = optional(bool, true)
      chart_version = optional(string, "0.5.2")
    }), {})
    kibana = optional(object({
      enabled       = optional(bool, true)
      chart_version = optional(string, "8.5.1")
      expose_public = optional(bool, false)
      node_port     = optional(number, 32081)
      host_port     = optional(number, 7081)
    }), {})
    jaeger = optional(object({
      enabled          = optional(bool, true)
      chart_version    = optional(string, "3.4.1")
      expose_public    = optional(bool, false)
      query_node_port  = optional(number, 31686)
      query_host_port  = optional(number, 7068)
      collector_memory = optional(string, "256Mi")
      query_memory     = optional(string, "256Mi")
    }), {})
  })
  description = "Observability stack settings for EFK and Jaeger."
  default     = {}
}

variable "recreate_revision" {
  type        = string
  description = "Change this token to force replacement of observability releases."
  default     = ""
}
