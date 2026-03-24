variable "network_name" {
  type        = string
  description = "Docker network used to reach the kind control-plane container."
  default     = "kind"
}

variable "create" {
  type        = bool
  description = "Create and manage the Kafka proxy Docker resources."
  default     = true
}

variable "bind_address" {
  type        = string
  description = "Host IP address to bind the Kafka UI proxy to."
  default     = "0.0.0.0"
}

variable "external_port" {
  type        = number
  description = "Host port exposed by the Kafka UI proxy."
  default     = 8088
}

variable "target_host" {
  type        = string
  description = "Target host name reachable inside the Docker network."
}

variable "target_port" {
  type        = number
  description = "Target port reachable inside the Docker network."
}

variable "container_name" {
  type        = string
  description = "Docker container name for the Kafka UI proxy."
  default     = "kafka-ui-proxy"
}

variable "image_name" {
  type        = string
  description = "Proxy image reference."
  default     = "alpine/socat:1.8.0.0"
}

variable "recreate_revision" {
  type        = string
  description = "Change this token to force replacement of the Kafka UI proxy resources."
  default     = ""
}
