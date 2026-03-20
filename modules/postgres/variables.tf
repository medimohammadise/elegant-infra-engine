variable "network_name" {
  type        = string
  description = "Docker network used by PostgreSQL."
}

variable "bind_address" {
  type        = string
  description = "Host IP address to bind PostgreSQL to."
  default     = "0.0.0.0"
}

variable "port" {
  type        = number
  description = "Host port exposed by PostgreSQL."
  default     = 5432
}

variable "db_name" {
  type        = string
  description = "Default PostgreSQL database name."
  default     = "blitzinfra"
}

variable "user" {
  type        = string
  description = "PostgreSQL application user."
  default     = "blitzinfra"
}

variable "password" {
  type        = string
  description = "PostgreSQL password."
  sensitive   = true
}

variable "container_name" {
  type        = string
  description = "Docker container name for PostgreSQL."
  default     = "postgres"
}

variable "volume_name" {
  type        = string
  description = "Docker volume name for PostgreSQL data."
  default     = "postgres_data"
}

variable "image_name" {
  type        = string
  description = "PostgreSQL image reference."
  default     = "postgres:16.2"
}

variable "recreate_revision" {
  type        = string
  description = "Change this token to force replacement of PostgreSQL resources."
  default     = ""
}
