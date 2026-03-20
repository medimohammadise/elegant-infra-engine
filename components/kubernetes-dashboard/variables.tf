variable "kubeconfig_path" {
  type        = string
  description = "Path to the kubeconfig file of the target cluster."
}

variable "cluster_name" {
  type        = string
  description = "kind cluster name used by the kubeconfig context."
  default     = "blitzinfra"
}

variable "dashboard" {
  type = object({
    namespace         = optional(string, "kubernetes-dashboard")
    chart_url         = optional(string, "https://github.com/kubernetes-retired/dashboard/releases/download/kubernetes-dashboard-7.14.0/kubernetes-dashboard-7.14.0.tgz")
    expose_public     = optional(bool, false)
    node_port         = optional(number, 32443)
    create_admin_user = optional(bool, true)
    admin_user_name   = optional(string, "admin-user")
  })
  description = "Kubernetes Dashboard settings."
  default     = {}
}

variable "recreate_revision" {
  type        = string
  description = "Change this token to force replacement of the dashboard release."
  default     = ""
}
