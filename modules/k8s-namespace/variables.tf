variable "name" {
  type        = string
  description = "Namespace name."
}

variable "labels" {
  type        = map(string)
  description = "Labels applied to the namespace."
  default     = {}
}

variable "annotations" {
  type        = map(string)
  description = "Annotations applied to the namespace."
  default     = {}
}
