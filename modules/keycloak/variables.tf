variable "name" {
  type        = string
  description = "Keycloak resource name."
  default     = "keycloak"
}

variable "namespace" {
  type        = string
  description = "Namespace where Keycloak is deployed."
}

variable "image" {
  type        = string
  description = "Keycloak container image."
  default     = "quay.io/keycloak/keycloak:26.1"
}

variable "replicas" {
  type        = number
  description = "Number of Keycloak replicas."
  default     = 1
}

variable "service_type" {
  type        = string
  description = "Kubernetes service type for Keycloak."
  default     = "ClusterIP"
}

variable "node_port" {
  type        = number
  description = "NodePort reserved for Keycloak when service_type is NodePort."
  default     = null
  nullable    = true
}

variable "admin_username" {
  type        = string
  description = "Bootstrap admin username."
  default     = "admin"
}

variable "admin_password" {
  type        = string
  description = "Bootstrap admin password."
  sensitive   = true
}

variable "database_host" {
  type        = string
  description = "PostgreSQL hostname reachable from the cluster."
}

variable "database_port" {
  type        = number
  description = "PostgreSQL port reachable from the cluster."
  default     = 5432
}

variable "database_name" {
  type        = string
  description = "Keycloak PostgreSQL database name."
}

variable "database_user" {
  type        = string
  description = "Keycloak PostgreSQL username."
}

variable "database_password" {
  type        = string
  description = "Keycloak PostgreSQL password."
  sensitive   = true
}

variable "cpu_request" {
  type        = string
  description = "CPU request for the Keycloak container."
  default     = "250m"
}

variable "memory_request" {
  type        = string
  description = "Memory request for the Keycloak container."
  default     = "1Gi"
}

variable "memory_limit" {
  type        = string
  description = "Memory limit for the Keycloak container."
  default     = "2Gi"
}

variable "java_opts_kc_heap" {
  type        = string
  description = "Heap tuning passed to Keycloak."
  default     = "-XX:MaxRAMPercentage=65 -XX:InitialRAMPercentage=30"
}

variable "recreate_revision" {
  type        = string
  description = "Change this token to force replacement of the Keycloak deployment."
  default     = ""
}
