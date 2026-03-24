variable "cluster_name" {
  type        = string
  description = "Name of the kind cluster."
  default     = "blitz-cluster"
}

variable "api_server_port" {
  type        = number
  description = "Port used by the Kubernetes API server."
  default     = 6443
}

variable "api_server_host" {
  type        = string
  description = "Host name or IP exposed in the kubeconfig."
}

variable "ssh_context_host" {
  type        = string
  description = "SSH host used to access the remote Docker host."
}

variable "worker_count" {
  type        = number
  description = "Number of worker nodes in the kind cluster."
  default     = 4
}

variable "kind_node_image" {
  type        = string
  description = "kind node image reference."
}

variable "backstage_port_mapping" {
  type = object({
    node_port = number
    host_port = number
  })
  description = "Optional NodePort to host-port mapping for Backstage."
  default     = null
}

variable "headlamp_port_mapping" {
  type = object({
    node_port = number
    host_port = number
  })
  description = "Optional NodePort to host-port mapping for Headlamp."
  default     = null
}

variable "kafka_dashboard_port_mapping" {
  type = object({
    node_port = number
    host_port = number
  })
  description = "Optional NodePort to host-port mapping for the Kafka dashboard."
  default     = null
}

variable "keycloak_port_mapping" {
  type = object({
    node_port = number
    host_port = number
  })
  description = "Optional NodePort to host-port mapping for Keycloak."
  default     = null
}

variable "grafana_port_mapping" {
  type = object({
    node_port = number
    host_port = number
  })
  description = "Optional NodePort to host-port mapping for Grafana."
  default     = null
}

variable "prometheus_port_mapping" {
  type = object({
    node_port = number
    host_port = number
  })
  description = "Optional NodePort to host-port mapping for Prometheus."
  default     = null
}

variable "dependencytrack_api_port_mapping" {
  type = object({
    node_port = number
    host_port = number
  })
  description = "Optional NodePort to host-port mapping for the DependencyTrack API."
  default     = null
}

variable "dependencytrack_frontend_port_mapping" {
  type = object({
    node_port = number
    host_port = number
  })
  description = "Optional NodePort to host-port mapping for the DependencyTrack frontend."
  default     = null
}

variable "extra_port_mappings" {
  type = list(object({
    node_port   = number
    host_port   = number
    description = optional(string, "")
  }))
  description = "Additional NodePort to host-port mappings to reserve on the kind control-plane at cluster creation time. Use this for new services instead of adding per-service variables to this module."
  default     = []
}

variable "kubeconfig_path" {
  type        = string
  description = "Absolute or relative path for the generated kubeconfig file."
  default     = null
}

variable "recreate_revision" {
  type        = string
  description = "Change this token to force replacement of the kind cluster."
  default     = ""
}
