variable "ssh_context_host" {
  type        = string
  description = "Target SSH host backing the remote Docker daemon."
}

variable "api_server_host" {
  type        = string
  description = "Host name or IP exposed by the kind API server."
}

variable "kubernetes" {
  type = object({
    cluster_name    = optional(string, "blitzinfra")
    api_server_port = optional(number, 6443)
    worker_count    = optional(number, 4)
    kind_node_image = optional(string, "kindest/node:v1.30.0@sha256:047357ac0cfea04663786a612ba1eaba9702bef25227a794b52890dd8bcd692e")
    kubeconfig_path = optional(string)
  })
  description = "kind cluster settings."
  default     = {}
}

variable "backstage_port_mapping" {
  type = object({
    node_port = number
    host_port = number
  })
  description = "Optional NodePort to host-port mapping reserved for Backstage."
  default     = null
}

variable "headlamp_port_mapping" {
  type = object({
    node_port = number
    host_port = number
  })
  description = "Optional NodePort to host-port mapping reserved for Headlamp."
  default     = null
}

variable "recreate_revision" {
  type        = string
  description = "Change this token to force replacement of the kind cluster."
  default     = ""
}
