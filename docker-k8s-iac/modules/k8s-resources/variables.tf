# variables.tf

variable "kube_namespace" {
  type        = string
  description = "The namespace to provision for the app"
  default     = "BlitzPay-DEV"
}

variable "recreate_revision" {
  type        = string
  description = "Change this token to force replacement of Kubernetes resources"
  default     = ""
}
