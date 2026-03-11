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

variable "kube_namespace" {
  type        = string
  description = "Namespace to provision"
  default     = "blitzpay-dev"
}
