# variables.tf

variable "kube_namespace" {
  type        = string
  description = "The namespace to provision for the app"
  default     = "blitzpay-dev"
}

variable "enable_backstage" {
  type        = bool
  description = "Install Backstage through the official Helm chart when true"
  default     = true
}

variable "backstage_namespace" {
  type        = string
  description = "Namespace where Backstage will be installed"
  default     = "backstage"
}

variable "backstage_chart_version" {
  type        = string
  description = "Version of the official Backstage Helm chart to install"
  default     = "2.6.3"
}

variable "backstage_image_tag" {
  type        = string
  description = "Pinned Backstage application image tag used by the Helm chart"
}

variable "backstage_base_url" {
  type        = string
  description = "Base URL used by the Backstage app and backend"
  default     = ""
}

variable "expose_backstage_public" {
  type        = bool
  description = "Expose Backstage through a NodePort service"
  default     = true
}

variable "backstage_node_port" {
  type        = number
  description = "The Kubernetes NodePort used for the Backstage HTTP service"
  default     = 32007
}

variable "postgres_host" {
  type        = string
  description = "Hostname or IP address for the existing PostgreSQL instance used by Backstage"
}

variable "postgres_port" {
  type        = number
  description = "Port for the existing PostgreSQL instance used by Backstage"
}

variable "postgres_db_name" {
  type        = string
  description = "Database name for the existing PostgreSQL instance used by Backstage"
}

variable "postgres_user" {
  type        = string
  description = "Database user for the existing PostgreSQL instance used by Backstage"
}

variable "postgres_password" {
  type        = string
  description = "Database password for the existing PostgreSQL instance used by Backstage"
  sensitive   = true
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
