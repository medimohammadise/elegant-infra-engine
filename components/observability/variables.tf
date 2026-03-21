variable "kubeconfig_path" {
  type        = string
  description = "Path to the kubeconfig file of the target cluster."
}


variable "cluster_name" {
  type        = string
  description = "Target cluster name used for operator-facing metadata and naming alignment."
  default     = "blitzinfra"
}

variable "api_server_host" {
  type        = string
  description = "Public host or IP reachable by other machines for NodePort/host-port access."
}

variable "ingress_nginx" {
  type = object({
    enabled               = optional(bool, false)
    namespace             = optional(string, "ingress-nginx")
    chart_version         = optional(string, "4.14.2")
    ingress_class_name    = optional(string, "nginx")
    default_ingress_class = optional(bool, true)
    http_node_port        = optional(number, 32080)
    https_node_port       = optional(number, 32443)
    recreate_revision     = optional(string, "")
  })
  description = "Optional ingress-nginx controller settings for exposing ingress resources."
  default     = {}
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
      expose_public = optional(bool, true)
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
    }), {})
    jaeger = optional(object({
      enabled          = optional(bool, true)
      chart_version    = optional(string, "3.4.1")
      expose_public    = optional(bool, true)
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
