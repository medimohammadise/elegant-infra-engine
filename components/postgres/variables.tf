variable "ssh_context_host" {
  type        = string
  description = "Target SSH host for Docker access."
}

variable "ssh_private_key_path" {
  type        = string
  description = "Path to the SSH private key used for the remote Docker host."
  default     = "~/.ssh/id_rsa"
}

variable "postgres" {
  type = object({
    network_name   = optional(string, "registry_net")
    create_network = optional(bool, true)
    bind_address   = optional(string, "0.0.0.0")
    port           = optional(number, 5432)
    db_name        = optional(string, "blitzinfra")
    user           = optional(string, "blitzinfra")
    password       = string
    volume_name    = optional(string, "postgres_data")
  })
  description = "PostgreSQL settings."
  sensitive   = true
}

variable "recreate_revision" {
  type        = string
  description = "Change this token to force replacement of PostgreSQL resources."
  default     = ""
}
