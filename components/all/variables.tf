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

variable "dashboard" {
  type = object({
    enabled           = optional(bool, false)
    namespace         = optional(string, "kubernetes-dashboard")
    chart_url         = optional(string, "https://github.com/kubernetes-retired/dashboard/releases/download/kubernetes-dashboard-7.14.0/kubernetes-dashboard-7.14.0.tgz")
    expose_public     = optional(bool, false)
    node_port         = optional(number, 32443)
    host_port         = optional(number, 8443)
    create_admin_user = optional(bool, true)
    admin_user_name   = optional(string, "admin-user")
    recreate_revision = optional(string, "")
  })
  description = "Kubernetes Dashboard deployment settings."
  default     = {}
}

variable "recreate_revision" {
  type        = string
  description = "Global replacement token passed to modules that support one-shot recreation."
  default     = ""
}


variable "observability" {
  type = object({
    enabled           = optional(bool, true)
    namespace         = optional(string, "observability")
    recreate_revision = optional(string, "")
    elasticsearch = optional(object({
      enabled        = optional(bool, true)
      chart_version  = optional(string, "8.5.1")
      replicas       = optional(number, 1)
      minimum_master = optional(number, 1)
    }), {})
    fluentd = optional(object({
      enabled       = optional(bool, true)
      chart_version = optional(string, "0.5.2")
    }), {})
    kibana = optional(object({
      enabled       = optional(bool, true)
      chart_version = optional(string, "8.5.1")
      expose_public = optional(bool, false)
      node_port     = optional(number, 32081)
      host_port     = optional(number, 7081)
    }), {})
    jaeger = optional(object({
      enabled          = optional(bool, true)
      chart_version    = optional(string, "3.4.1")
      expose_public    = optional(bool, false)
      query_node_port  = optional(number, 31686)
      query_host_port  = optional(number, 7068)
      collector_memory = optional(string, "256Mi")
      query_memory     = optional(string, "256Mi")
    }), {})
  })
  description = "Observability settings for EFK and Jaeger."
  default     = {}
}
