output "namespace" {
  description = "Kubernetes Dashboard namespace."
  value       = module.kubernetes_dashboard.namespace
}

output "admin_user_name" {
  description = "Dashboard admin service account name when created."
  value       = module.kubernetes_dashboard.admin_user_name
}
