variable "kubeconfig_path" {
  type        = string
  description = "Path to the kubeconfig file of the target cluster."
}

variable "cluster_name" {
  type        = string
  description = "kind cluster name used by the kubeconfig context."
  default     = "blitzinfra"
}

variable "ssh_context_host" {
  type        = string
  description = "Target SSH host for Docker access, for example user@server."
  default     = null
  nullable    = true
}

variable "ssh_private_key_path" {
  type        = string
  description = "Path to the SSH private key used for the remote Docker host."
  default     = "~/.ssh/id_rsa"
}

variable "api_server_host" {
  type        = string
  description = "Host name or IP exposed by the kind cluster for public Kafka and dashboard access."
  default     = null
  nullable    = true
}

variable "kafka" {
  type = object({
    namespace                = optional(string, "kafka")
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
  description = "Kafka deployment settings, including the bundled open-source dashboard."
  default     = {}
}

variable "recreate_revision" {
  type        = string
  description = "Change this token to force replacement of the Kafka releases."
  default     = ""
}
