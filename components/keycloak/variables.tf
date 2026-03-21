variable "kubeconfig_path" {
  type        = string
  description = "Path to the kubeconfig file of the target cluster."
}

variable "cluster_name" {
  type        = string
  description = "kind cluster name used by the kubeconfig context."
  default     = "blitzinfra"
}

variable "keycloak" {
  type = object({
    namespace         = optional(string, "keycloak")
    image_repository  = optional(string, "quay.io/keycloak/keycloak")
    image_tag         = optional(string, "26.5.5")
    replicas          = optional(number, 1)
    expose_public     = optional(bool, false)
    node_port         = optional(number, 32080)
    admin_username    = optional(string, "admin")
    admin_password    = optional(string, "change-me")
    recreate_revision = optional(string, "")
  })
  description = "Keycloak settings."
  sensitive   = true
  default     = {}
}

variable "recreate_revision" {
  type        = string
  description = "Change this token to force replacement of the Keycloak resources."
  default     = ""
}
