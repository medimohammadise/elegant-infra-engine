output "namespace" {
  description = "Backstage namespace."
  value       = module.backstage.namespace
}

output "release_name" {
  description = "Backstage Helm release name."
  value       = module.backstage.release_name
}

output "backstage_url" {
  description = "Configured Backstage URL."
  value       = var.backstage.base_url
}

output "keycloak_url" {
  description = "Configured external Keycloak URL."
  value       = var.keycloak_url
}

output "exposed_urls" {
  description = "Consolidated Backstage-related endpoints, including optional external dependencies."
  value = {
    backstage = var.backstage.base_url
    keycloak  = var.keycloak_url
  }
}
