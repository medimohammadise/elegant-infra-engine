output "namespace" {
  description = "Keycloak namespace."
  value       = module.keycloak.namespace
}

output "name" {
  description = "Keycloak workload name."
  value       = module.keycloak.name
}

output "service_name" {
  description = "Keycloak Service name."
  value       = module.keycloak.service_name
}
