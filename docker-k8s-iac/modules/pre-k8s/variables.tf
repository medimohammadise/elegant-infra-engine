# variables.tf

variable "registry_bind_address" {
  type        = string
  description = "The IP address to bind the registry to"
  default     = "0.0.0.0"
}

variable "ui_bind_address" {
  type        = string
  description = "The IP address to bind the registry UI to"
  default     = "127.0.0.1"
}

variable "registry_title" {
  type        = string
  description = "Title for the Registry UI"
  default     = "Remote Docker Registry"
}

variable "registry_ui_url" {
  type        = string
  description = "URL for the Registry UI to connect to"
  default     = "http://myserver:8081"
}

variable "image_registry" {
  type        = string
  description = "Pull URL for the Registry UI"
  default     = "myserver:5000"
}

variable "postgres_bind_address" {
  type        = string
  description = "The IP address to bind PostgreSQL to"
  default     = "127.0.0.1"
}

variable "postgres_port" {
  type        = number
  description = "The port to expose PostgreSQL on"
  default     = 5432
}

variable "postgres_db_name" {
  type        = string
  description = "The default PostgreSQL database name"
  default     = "blitzinfra"
}

variable "postgres_user" {
  type        = string
  description = "The PostgreSQL application user"
  default     = "blitzinfra"
}

variable "postgres_password" {
  type        = string
  description = "The PostgreSQL password"
  sensitive   = true
}

variable "recreate_revision" {
  type        = string
  description = "Change this token to force replacement of all pre-k8s Docker resources"
  default     = ""
}
