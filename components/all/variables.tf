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

variable "bootstrap_namespace" {
  type        = string
  description = "Optional application namespace created alongside the platform."
  default     = "blitzpay-dev"
}

variable "registry" {
  type = object({
    network_name   = optional(string, "registry_net")
    create_network = optional(bool, true)
    bind_address   = optional(string, "0.0.0.0")
    port           = optional(number, 5000)
    ui_bind        = optional(string, "127.0.0.1")
    ui_port        = optional(number, 8081)
    title          = optional(string, "Remote Docker Registry")
  })
  description = "Docker registry and registry UI settings."
  default     = {}
}

variable "postgres" {
  type = object({
    bind_address = optional(string, "0.0.0.0")
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
  })
  description = "kind cluster settings."
  default     = {}
}

variable "backstage" {
  type = object({
    enabled           = optional(bool, true)
    namespace         = optional(string, "backstage")
    chart_version     = optional(string, "2.6.3")
    image_tag         = optional(string, "1.30.2")
    base_url          = optional(string)
    expose_public     = optional(bool, true)
    node_port         = optional(number, 32007)
    host_port         = optional(number, 7007)
    recreate_revision = optional(string, "")
  })
  description = "Backstage deployment settings."
  default     = {}
}

variable "headlamp" {
  type = object({
    enabled                     = optional(bool, false)
    namespace                   = optional(string, "headlamp")
    chart_repository            = optional(string)
    chart_name                  = optional(string, "../../vendor/headlamp-chart")
    chart_version               = optional(string, "0.40.1")
    expose_public               = optional(bool, false)
    node_port                   = optional(number, 32443)
    host_port                   = optional(number, 8443)
    create_service_account      = optional(bool, true)
    service_account_name        = optional(string, "headlamp")
    create_cluster_role_binding = optional(bool, true)
    cluster_role_name           = optional(string, "cluster-admin")
    recreate_revision           = optional(string, "")
  })
  description = "Headlamp deployment settings."
  default     = {}
}

variable "keycloak_port_mapping" {
  type = object({
    node_port = number
    host_port = number
  })
  description = "Optional NodePort to host-port mapping reserved for Keycloak."
  default     = null
}

variable "keycloak_url" {
  type        = string
  description = "Optional externally managed Keycloak base URL to surface with the platform endpoints."
  default     = null
  nullable    = true
}

variable "recreate_revision" {
  type        = string
  description = "Global replacement token passed to modules that support one-shot recreation."
  default     = ""
}
