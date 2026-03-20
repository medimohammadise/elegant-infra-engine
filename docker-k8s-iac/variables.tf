# variables.tf

variable "ssh_context_host" {
  type        = string
  description = "The target SSH host for Docker (e.g. mehdi@myserver or simply myserver)"
}

variable "ssh_private_key_path" {
  type        = string
  description = "The path to the SSH private key used for authenticating to the remote Docker host"
  default     = "~/.ssh/id_rsa"
}

variable "api_server_host" {
  type        = string
  description = "The host IP or name where the API server will be exposed"
}

variable "registry_bind_address" {
  type        = string
  description = "IP address to bind the registry to"
  default     = "0.0.0.0"
}

variable "ui_bind_address" {
  type        = string
  description = "IP address to bind the registry UI to"
  default     = "127.0.0.1"
}

variable "registry_title" {
  type        = string
  description = "Title for the Registry UI"
  default     = "Remote Docker Registry"
}

variable "postgres_bind_address" {
  type        = string
  description = "IP address to bind PostgreSQL to"
  default     = "0.0.0.0"
}

variable "postgres_port" {
  type        = number
  description = "Port to expose PostgreSQL on"
  default     = 5432
}

variable "postgres_db_name" {
  type        = string
  description = "Default PostgreSQL database name"
  default     = "blitzinfra"
}

variable "postgres_user" {
  type        = string
  description = "PostgreSQL application user"
  default     = "blitzinfra"
}

variable "postgres_password" {
  type        = string
  description = "PostgreSQL password"
  sensitive   = true
}

variable "cluster_name" {
  type        = string
  description = "Name for the kind cluster"
  default     = "blitzinfra"
}

variable "worker_count" {
  type        = number
  description = "Number of worker nodes in kind"
  default     = 4
}

variable "kind_node_image" {
  type        = string
  description = "The kind node image to use for the Kubernetes cluster"
  default     = "kindest/node:v1.30.0@sha256:047357ac0cfea04663786a612ba1eaba9702bef25227a794b52890dd8bcd692e"
}

variable "kube_namespace" {
  type        = string
  description = "Namespace to provision"
  default     = "blitzpay-dev"
}

variable "enable_k8s_dashboard" {
  type        = bool
  description = "Install the Kubernetes Dashboard Helm chart when true"
  default     = false
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
  description = "Pinned Backstage application image tag used by the Helm chart. Do not leave this floating on latest."
  default     = "1.30.2"
}

variable "backstage_base_url" {
  type        = string
  description = "Base URL used by the Backstage app and backend. Leave empty to derive http://<api_server_host>:<backstage_host_port>."
  default     = ""
}

variable "expose_backstage_public" {
  type        = bool
  description = "Expose Backstage on the remote host through the kind control-plane host port"
  default     = true
}

variable "backstage_node_port" {
  type        = number
  description = "The Kubernetes NodePort used for the Backstage HTTP service"
  default     = 32007
}

variable "backstage_host_port" {
  type        = number
  description = "The remote host port mapped to the Backstage NodePort"
  default     = 7007
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
  description = "Expose the Kubernetes Dashboard on the remote host"
  default     = false
}

variable "dashboard_node_port" {
  type        = number
  description = "The Kubernetes NodePort used for the Dashboard HTTPS service"
  default     = 32443
}

variable "dashboard_host_port" {
  type        = number
  description = "The remote host port mapped to the Dashboard HTTPS service"
  default     = 8443
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
  description = "Change this token when you want Terraform to replace all managed infrastructure resources once"
  default     = ""
}
