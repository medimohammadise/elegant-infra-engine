variable "ssh_context_host" {
  type        = string
  description = "Target SSH host for Docker access, for example user@server."
}

variable "ssh_private_key_path" {
  type        = string
  description = "Path to the SSH private key used for the remote Docker host."
  default     = "~/.ssh/id_rsa"
}

variable "api_server_host" {
  type        = string
  description = "Host name or IP exposed by the kind API server and public services."
}

variable "network" {
  type = object({
    name              = optional(string, "registry_net")
    create            = optional(bool, true)
    recreate_revision = optional(string, "")
  })
  description = "Docker network settings."
  default     = {}
}

variable "postgres" {
  type = object({
    create       = optional(bool, true)
    bind_address = optional(string, "0.0.0.0")
    access_host  = optional(string)
    port         = optional(number, 5432)
    db_name      = optional(string, "blitzinfra")
    user         = optional(string, "blitzinfra")
    password     = string
    volume_name  = optional(string, "postgres_data")
  })
  description = "PostgreSQL settings."
  sensitive   = true
}

variable "kubernetes" {
  type = object({
    create_cluster    = optional(bool, true)
    cluster_name      = optional(string, "blitzinfra")
    api_server_port   = optional(number, 6443)
    worker_count      = optional(number, 4)
    kind_node_image   = optional(string, "kindest/node:v1.30.0@sha256:047357ac0cfea04663786a612ba1eaba9702bef25227a794b52890dd8bcd692e")
    kubeconfig_path   = optional(string)
    recreate_revision = optional(string, "")
    extra_port_mappings = optional(list(object({
      node_port   = number
      host_port   = number
      description = optional(string, "")
    })), [])
  })
  description = "kind cluster settings."
  default     = {}
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

variable "kafka_dashboard_port_mapping" {
  type = object({
    node_port = number
    host_port = number
  })
  description = "Optional NodePort to host-port mapping for the Kafka dashboard."
  default     = null
}

variable "recreate_revision" {
  type        = string
  description = "Global replacement token passed to modules that support one-shot recreation."
  default     = ""
}
