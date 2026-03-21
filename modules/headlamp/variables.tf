variable "release_name" {
  type        = string
  description = "Helm release name for Headlamp."
  default     = "headlamp"
}

variable "namespace" {
  type        = string
  description = "Namespace where Headlamp is installed."
}

variable "chart_name" {
  type        = string
  description = "Helm chart name or local chart path for Headlamp."
  default     = "../../vendor/headlamp-chart"
}

variable "chart_repository" {
  type        = string
  description = "Helm repository URL for the Headlamp chart when using a remote chart reference."
  default     = null
}

variable "chart_version" {
  type        = string
  description = "Headlamp chart version."
  default     = "0.40.1"
}

variable "service_type" {
  type        = string
  description = "Kubernetes Service type used by Headlamp."
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

variable "create_service_account" {
  type        = bool
  description = "Create the Headlamp service account."
  default     = true
}

variable "service_account_name" {
  type        = string
  description = "Service account name used by the Headlamp deployment."
  default     = "headlamp"
}

variable "create_cluster_role_binding" {
  type        = bool
  description = "Create a cluster role binding for the Headlamp service account."
  default     = true
}

variable "cluster_role_name" {
  type        = string
  description = "Cluster role granted to the Headlamp service account."
  default     = "cluster-admin"
}

variable "recreate_revision" {
  type        = string
  description = "Change this token to force replacement of the Headlamp release."
  default     = ""
}
