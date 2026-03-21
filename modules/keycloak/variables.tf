variable "name" {
  type        = string
  description = "Base name used for Keycloak Kubernetes resources."
  default     = "keycloak"
}

variable "namespace" {
  type        = string
  description = "Namespace where Keycloak is installed."
}

variable "image_repository" {
  type        = string
  description = "Container image repository used for Keycloak."
  default     = "quay.io/keycloak/keycloak"
}

variable "image_tag" {
  type        = string
  description = "Pinned Keycloak image tag."
  default     = "26.5.5"
}

variable "replicas" {
  type        = number
  description = "Number of Keycloak pods."
  default     = 1
}

variable "service_type" {
  type        = string
  description = "Kubernetes Service type used by Keycloak."
  default     = "ClusterIP"

  validation {
    condition     = contains(["ClusterIP", "NodePort"], var.service_type)
    error_message = "service_type must be ClusterIP or NodePort."
  }
}

variable "node_port" {
  type        = number
  description = "Optional NodePort used when service_type is NodePort."
  default     = null
}

variable "admin_username" {
  type        = string
  description = "Admin username used to bootstrap Keycloak."
  default     = "admin"
}

variable "admin_password" {
  type        = string
  description = "Admin password used to bootstrap Keycloak."
  sensitive   = true
}

variable "recreate_revision" {
  type        = string
  description = "Change this token to force replacement of the Keycloak resources."
  default     = ""
}
