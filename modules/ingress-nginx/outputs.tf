output "namespace" {
  description = "Namespace where ingress-nginx is installed."
  value       = helm_release.this.namespace
}

output "release_name" {
  description = "Helm release name for ingress-nginx."
  value       = helm_release.this.name
}

output "ingress_class_name" {
  description = "IngressClass name managed by the controller."
  value       = var.ingress_class_name
}
