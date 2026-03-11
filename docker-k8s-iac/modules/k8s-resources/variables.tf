# variables.tf

variable "kube_namespace" {
  type        = string
  description = "The namespace to provision for the app"
  default     = "BlitzPay-DEV"
}
