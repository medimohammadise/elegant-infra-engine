variable "namespace" {
  type        = string
  description = "Namespace where Kafka and the dashboard are installed."
}

variable "api_server_host" {
  type        = string
  description = "Host name or IP exposed by the cluster for public services."
  default     = null
  nullable    = true
}

variable "kafka" {
  type = object({
    release_name             = optional(string, "kafka")
    chart_repository         = optional(string, "oci://registry-1.docker.io/bitnamicharts")
    chart_name               = optional(string, "kafka")
    chart_version            = optional(string, "32.0.2")
    controller_replica_count = optional(number, 1)
    broker_replica_count     = optional(number, 1)
    persistence_enabled      = optional(bool, false)
    persistence_size         = optional(string, "8Gi")
    image_registry           = optional(string, "docker.io")
    image_repository         = optional(string, "bitnamilegacy/kafka")
    image_tag                = optional(string, "4.0.0-debian-12-r10")
    expose_public            = optional(bool, false)
    external_node_port       = optional(number, 32092)
    external_host_port       = optional(number, 9092)
    expose_dashboard_public  = optional(bool, false)
    dashboard_node_port      = optional(number, 32081)
    dashboard_host_port      = optional(number, 8088)
    dashboard = optional(object({
      release_name     = optional(string, "kafka-ui")
      chart_repository = optional(string, "https://provectus.github.io/kafka-ui-charts")
      chart_name       = optional(string, "kafka-ui")
      chart_version    = optional(string)
    }), {})
  })
  description = "Kafka and Kafka dashboard Helm release settings."
  default     = {}
}

variable "recreate_revision" {
  type        = string
  description = "Change this token to force replacement of Kafka Helm releases."
  default     = ""
}
