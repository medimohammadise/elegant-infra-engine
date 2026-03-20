output "release_name" {
  description = "Kubernetes Dashboard Helm release name."
  value       = helm_release.this.name
}

output "namespace" {
  description = "Namespace where Kubernetes Dashboard is installed."
  value       = helm_release.this.namespace
}

output "admin_user_name" {
  description = "Dashboard admin service account name when created."
  value       = var.create_admin_user ? kubernetes_service_account.admin_user[0].metadata[0].name : null
}
