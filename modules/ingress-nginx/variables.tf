variable "namespace" {
  type        = string
  description = "Namespace where ingress-nginx is installed."
  default     = "ingress-nginx"
}

variable "release_name" {
  type        = string
  description = "Helm release name for ingress-nginx."
  default     = "ingress-nginx"
}

variable "chart_version" {
  type        = string
  description = "ingress-nginx Helm chart version."
  default     = "4.14.2"
}

variable "ingress_class_name" {
  type        = string
  description = "IngressClass name managed by this controller."
  default     = "nginx"
}

variable "default_ingress_class" {
  type        = bool
  description = "Whether this controller should become the default ingress class."
  default     = true
}

variable "http_node_port" {
  type        = number
  description = "NodePort used for HTTP ingress traffic."
  default     = 32080
}

variable "https_node_port" {
  type        = number
  description = "NodePort used for HTTPS ingress traffic."
  default     = 32443
}

variable "recreate_revision" {
  type        = string
  description = "Change this token to force replacement of the ingress-nginx release."
  default     = ""
}
