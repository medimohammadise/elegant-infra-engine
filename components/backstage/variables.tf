variable "kubeconfig_path" {
  type        = string
  description = "Path to the kubeconfig file of the target cluster."
}

variable "cluster_name" {
  type        = string
  description = "kind cluster name used by the kubeconfig context."
  default     = "blitzinfra"
}

variable "backstage_backend_auth_key" {
  type        = string
  description = "Static Backstage backend auth key used in protected mode."
  sensitive   = true
}

variable "backstage" {
  type = object({
    namespace     = optional(string, "backstage")
    chart_version = optional(string, "2.6.3")
    image_tag     = optional(string, "1.30.2")
    base_url      = string
    expose_public = optional(bool, true)
    node_port     = optional(number, 32007)
  })
  description = "Backstage Helm release settings."
}

variable "postgres" {
  type = object({
    host     = string
    port     = number
    db_name  = string
    user     = string
    password = string
  })
  description = "Existing PostgreSQL connection settings used by Backstage."
  sensitive   = true
}

variable "recreate_revision" {
  type        = string
  description = "Change this token to force replacement of the Backstage release."
  default     = ""
}

variable "keycloak_url" {
  type        = string
  description = "Optional externally managed Keycloak base URL to surface with the Backstage endpoints."
  default     = null
  nullable    = true
}
