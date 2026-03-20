variable "release_name" {
  type        = string
  description = "Helm release name for Kubernetes Dashboard."
  default     = "kubernetes-dashboard"
}

variable "namespace" {
  type        = string
  description = "Namespace where Kubernetes Dashboard is installed."
}

variable "chart_url" {
  type        = string
  description = "Download URL for the Kubernetes Dashboard chart archive."
  default     = "https://github.com/kubernetes-retired/dashboard/releases/download/kubernetes-dashboard-7.14.0/kubernetes-dashboard-7.14.0.tgz"
}

variable "service_type" {
  type        = string
  description = "Kubernetes Service type used by the dashboard."
  default     = "ClusterIP"

  validation {
    condition     = contains(["ClusterIP", "NodePort"], var.service_type)
    error_message = "service_type must be ClusterIP or NodePort."
  }
}

variable "node_port" {
  type        = number
  description = "Optional NodePort used when service_type is NodePort."
  default     = null
}

variable "create_admin_user" {
  type        = bool
  description = "Create a cluster-admin service account for dashboard login."
  default     = true
}

variable "admin_user_name" {
  type        = string
  description = "Service account name used for dashboard login."
  default     = "admin-user"
}

variable "recreate_revision" {
  type        = string
  description = "Change this token to force replacement of the dashboard release."
  default     = ""
}
