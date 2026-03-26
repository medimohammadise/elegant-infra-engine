variable "ssh_context_host" {
  type        = string
  description = "Target SSH host for Docker access."
}

variable "ssh_private_key_path" {
  type        = string
  description = "Path to the SSH private key used for the remote Docker host."
  default     = "~/.ssh/id_rsa"
}

variable "api_server_host" {
  type        = string
  description = "Host name or IP used in generated URLs."
}

variable "registry" {
  type = object({
    network_name    = optional(string, "registry_net")
    create_network  = optional(bool, true)
    create_registry = optional(bool, true)
    create_ui       = optional(bool, true)
    bind_address    = optional(string, "0.0.0.0")
    port            = optional(number, 5000)
    ui_bind         = optional(string, "127.0.0.1")
    ui_port         = optional(number, 8081)
    title           = optional(string, "Remote Docker Registry")
  })
  description = "Docker registry and registry UI settings."
  default     = {}
}

variable "recreate_revision" {
  type        = string
  description = "Change this token to force replacement of registry resources."
  default     = ""
}
