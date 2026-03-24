variable "network_name" {
  type        = string
  description = "Docker network used by the registry container."
}

variable "create" {
  type        = bool
  description = "Create and manage the registry Docker resources."
  default     = true
}

variable "bind_address" {
  type        = string
  description = "Host IP address to bind the registry to."
  default     = "0.0.0.0"
}

variable "external_port" {
  type        = number
  description = "Host port exposed by the registry."
  default     = 5000
}

variable "container_name" {
  type        = string
  description = "Docker container name for the registry."
  default     = "registry"
}

variable "image_name" {
  type        = string
  description = "Registry image reference."
  default     = "registry:2"
}

variable "recreate_revision" {
  type        = string
  description = "Change this token to force replacement of the registry resources."
  default     = ""
}
