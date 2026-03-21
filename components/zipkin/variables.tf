variable "kubeconfig_path" {
  type        = string
  description = "Path to the kubeconfig file of the target cluster."
}

variable "zipkin" {
  type = object({
    namespace         = optional(string, "zipkin")
    release_name      = optional(string, "zipkin")
    image             = optional(string, "openzipkin/zipkin:3")
    expose_public     = optional(bool, false)
    service_port      = optional(number, 9411)
    node_port         = optional(number, 32411)
    recreate_revision = optional(string, "")
  })
  description = "Zipkin deployment settings."
  default     = {}
}

variable "recreate_revision" {
  type        = string
  description = "Change this token to force replacement of Zipkin resources."
  default     = ""
}
