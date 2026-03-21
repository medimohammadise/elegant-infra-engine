output "namespace" {
  description = "Headlamp namespace."
  value       = module.headlamp.namespace
}

output "service_account_name" {
  description = "Headlamp service account name when created."
  value       = module.headlamp.service_account_name
}
