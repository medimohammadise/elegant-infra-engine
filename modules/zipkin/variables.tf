variable "release_name" {
  type        = string
  description = "Workload and service name used for Zipkin resources."
  default     = "zipkin"
}

variable "namespace" {
  type        = string
  description = "Namespace where Zipkin is installed."
}

variable "image" {
  type        = string
  description = "Container image used for Zipkin."
  default     = "openzipkin/zipkin:3"
}

variable "service_type" {
  type        = string
  description = "Kubernetes Service type used by Zipkin."
  default     = "ClusterIP"

  validation {
    condition     = contains(["ClusterIP", "NodePort"], var.service_type)
    error_message = "service_type must be ClusterIP or NodePort."
  }
}

variable "service_port" {
  type        = number
  description = "Service port exposed by Zipkin."
  default     = 9411
}

variable "node_port" {
  type        = number
  description = "Optional NodePort used when service_type is NodePort."
  default     = null

  validation {
    condition     = var.service_type != "NodePort" || var.node_port != null
    error_message = "node_port must be set when service_type is NodePort."
  }
}

variable "recreate_revision" {
  type        = string
  description = "Change this token to force replacement of Zipkin resources."
  default     = ""
}
