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

variable "recreate_revision" {
  type        = string
  description = "Change this token when you want Terraform to replace all managed infrastructure resources once"
  default     = ""
}
