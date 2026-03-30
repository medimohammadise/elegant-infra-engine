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

variable "keycloak" {
  type = object({
    name             = optional(string, "keycloak")
    namespace        = optional(string, "keycloak")
    image_repository = optional(string, "quay.io/keycloak/keycloak")
    image_tag        = optional(string, "26.5.6")
    replicas         = optional(number, 1)
    expose_public    = optional(bool, true)
    node_port        = optional(number, 32080)
    host_port        = optional(number, 8080)
    admin_username   = optional(string, "admin")
    admin_password   = string
  })
  description = "Keycloak deployment settings."
}

variable "postgres_password" {
  type        = string
  description = "Password for the PostgreSQL user Keycloak uses; other connection details come from the infra component via remote state."
  sensitive   = true
}

variable "recreate_revision" {
  type        = string
  description = "Change this token to force replacement of the Keycloak deployment."
  default     = ""
}
