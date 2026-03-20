# variables.tf

variable "cluster_name" {
  type        = string
  description = "The name of the kind cluster"
  default     = "blitzinfra"
}

variable "api_server_port" {
  type        = number
  description = "The port for the kind API server"
  default     = 6443
}

variable "api_server_host" {
  type        = string
  description = "The host IP or name where the kind cluster is created"
}

variable "ssh_context_host" {
  type        = string
  description = "The SSH host used to access the remote node"
}

variable "worker_count" {
  type        = number
  description = "The number of worker nodes to provision"
  default     = 4
}

variable "kind_node_image" {
  type        = string
  description = "The kind node image to use when creating the cluster"
}

variable "recreate_revision" {
  type        = string
  description = "Change this token to force replacement of the kind cluster"
  default     = ""
}

variable "expose_backstage_public" {
  type        = bool
  description = "Expose Backstage through the kind control-plane host port"
  default     = false
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

variable "expose_dashboard_public" {
  type        = bool
  description = "Expose the Kubernetes Dashboard through the kind control-plane host port"
  default     = false
}

variable "dashboard_node_port" {
  type        = number
  description = "The Kubernetes NodePort used for the Dashboard HTTPS service"
  default     = 32443
}

variable "dashboard_host_port" {
  type        = number
  description = "The remote host port mapped to the Dashboard NodePort"
  default     = 8443
}
