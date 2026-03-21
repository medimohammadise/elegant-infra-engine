output "release_name" {
  description = "Headlamp Helm release name."
  value       = helm_release.this.name
}

output "namespace" {
  description = "Namespace where Headlamp is installed."
  value       = helm_release.this.namespace
}

output "service_account_name" {
  description = "Headlamp service account name when created."
  value       = var.create_service_account ? var.service_account_name : null
}
