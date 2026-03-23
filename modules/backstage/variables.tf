variable "release_name" {
  type        = string
  description = "Helm release name for Backstage."
  default     = "backstage"
}

variable "namespace" {
  type        = string
  description = "Namespace where Backstage is installed."
}

variable "chart_version" {
  type        = string
  description = "Version of the official Backstage Helm chart."
  default     = "2.6.3"
}

variable "image_tag" {
  type        = string
  description = "Pinned Backstage application image tag."
  default     = "1.30.2"
}

variable "base_url" {
  type        = string
  description = "Base URL used by the Backstage app and backend."
}

variable "service_type" {
  type        = string
  description = "Kubernetes Service type used by Backstage."
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

variable "app_title" {
  type        = string
  description = "Displayed Backstage application title."
  default     = "Backstage"
}

variable "organization_name" {
  type        = string
  description = "Backstage organization name."
  default     = "elegant-infra-engine"
}

variable "postgres_host" {
  type        = string
  description = "Hostname of the PostgreSQL instance used by Backstage."
}

variable "postgres_port" {
  type        = number
  description = "Port of the PostgreSQL instance used by Backstage."
}

variable "postgres_db_name" {
  type        = string
  description = "Database name used by Backstage."
}

variable "postgres_user" {
  type        = string
  description = "Database user used by Backstage."
}

variable "postgres_password" {
  type        = string
  description = "Database password used by Backstage."
  sensitive   = true
}

variable "backend_auth_key" {
  type        = string
  description = "Static backend auth key used for plugin-to-plugin and external token validation in protected mode."
  sensitive   = true
}

variable "auth_provider" {
  type        = string
  description = "Backstage sign-in provider mode."
  default     = "guest"

  validation {
    condition     = contains(["none", "guest", "keycloak"], var.auth_provider)
    error_message = "auth_provider must be none, guest, or keycloak."
  }
}

variable "keycloak_base_url" {
  type        = string
  description = "Keycloak base URL, for example http://myserver:8080."
  default     = null
  nullable    = true
}

variable "keycloak_realm" {
  type        = string
  description = "Keycloak realm used by Backstage."
  default     = null
  nullable    = true
}

variable "keycloak_client_id" {
  type        = string
  description = "Keycloak client ID used by Backstage."
  default     = null
  nullable    = true
}

variable "keycloak_client_secret" {
  type        = string
  description = "Keycloak client secret used by Backstage."
  default     = null
  nullable    = true
  sensitive   = true
}

variable "recreate_revision" {
  type        = string
  description = "Change this token to force replacement of the Backstage release."
  default     = ""
}
