# variables.tf

variable "kube_namespace" {
  type        = string
  description = "The namespace to provision for the app"
  default     = "BlitzPay-DEV"
}

variable "enable_k8s_dashboard" {
  type        = bool
  description = "Install the Kubernetes Dashboard Helm chart when true"
  default     = false
}

variable "dashboard_namespace" {
  type        = string
  description = "Namespace where Kubernetes Dashboard will be installed"
  default     = "kubernetes-dashboard"
}

variable "k8s_dashboard_chart_url" {
  type        = string
  description = "Download URL for the Kubernetes Dashboard chart archive"
  default     = "https://github.com/kubernetes-retired/dashboard/releases/download/kubernetes-dashboard-7.14.0/kubernetes-dashboard-7.14.0.tgz"
}

variable "expose_dashboard_public" {
  type        = bool
  description = "Expose the Kubernetes Dashboard through a NodePort service"
  default     = false
}

variable "dashboard_node_port" {
  type        = number
  description = "The Kubernetes NodePort used for the Dashboard HTTPS service"
  default     = 32443
}

variable "create_dashboard_admin_user" {
  type        = bool
  description = "Create a cluster-admin service account for Kubernetes Dashboard login"
  default     = true
}

variable "dashboard_admin_user_name" {
  type        = string
  description = "The Kubernetes service account name used for Dashboard admin login"
  default     = "admin-user"
}

variable "recreate_revision" {
  type        = string
  description = "Change this token to force replacement of Kubernetes resources"
  default     = ""
}
