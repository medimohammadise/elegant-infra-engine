variable "name" {
  type        = string
  description = "Name of the Docker network."
  default     = "blitzinfra"
}

variable "create" {
  type        = bool
  description = "Whether Terraform should create the Docker network or look up an existing one by name."
  default     = true
}

variable "recreate_revision" {
  type        = string
  description = "Change this token to force replacement of the Docker network."
  default     = ""
}
