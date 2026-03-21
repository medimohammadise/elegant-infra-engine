variable "kubeconfig_path" {
  type        = string
  description = "Path to the kubeconfig file of the target cluster."
}

variable "cluster_name" {
  type        = string
  description = "kind cluster name used by the kubeconfig context."
  default     = "blitzinfra"
}

variable "headlamp" {
  type = object({
    namespace                   = optional(string, "headlamp")
    chart_repository            = optional(string)
    chart_name                  = optional(string, "../../vendor/headlamp-chart")
    chart_version               = optional(string, "0.40.1")
    expose_public               = optional(bool, false)
    node_port                   = optional(number, 32443)
    create_service_account      = optional(bool, true)
    service_account_name        = optional(string, "headlamp")
    create_cluster_role_binding = optional(bool, true)
    cluster_role_name           = optional(string, "cluster-admin")
  })
  description = "Headlamp settings."
  default     = {}
}

variable "recreate_revision" {
  type        = string
  description = "Change this token to force replacement of the Headlamp release."
  default     = ""
}
