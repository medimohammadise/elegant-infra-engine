variable "network_name" {
  type        = string
  description = "Docker network used by the registry UI."
}

variable "bind_address" {
  type        = string
  description = "Host IP address to bind the registry UI to."
  default     = "127.0.0.1"
}

variable "external_port" {
  type        = number
  description = "Host port exposed by the registry UI."
  default     = 8081
}

variable "registry_title" {
  type        = string
  description = "Title shown by the registry UI."
  default     = "Remote Docker Registry"
}

variable "registry_internal_url" {
  type        = string
  description = "Internal registry URL reachable from the Docker network."
  default     = "http://registry:5000"
}

variable "registry_external_url" {
  type        = string
  description = "External registry UI URL used by the UI application."
}

variable "image_registry" {
  type        = string
  description = "Docker pull URL shown in the UI."
}

variable "container_name" {
  type        = string
  description = "Docker container name for the registry UI."
  default     = "registry-ui"
}

variable "image_name" {
  type        = string
  description = "Registry UI image reference."
  default     = "joxit/docker-registry-ui:2.5.7"
}

variable "recreate_revision" {
  type        = string
  description = "Change this token to force replacement of the registry UI resources."
  default     = ""
}
