output "name" {
  description = "Keycloak deployment name."
  value       = module.keycloak.name
}

output "namespace" {
  description = "Keycloak namespace."
  value       = module.keycloak.namespace
}

output "service_name" {
  description = "Keycloak service name."
  value       = module.keycloak.service_name
}

output "keycloak_url" {
  description = "Configured Keycloak URL when publicly exposed."
  value       = var.keycloak.expose_public && try(local.infra.api_server_host, "") != "" ? "http://${local.infra.api_server_host}:${var.keycloak.host_port}/" : null
}

output "exposed_urls" {
  description = "Consolidated Keycloak endpoints."
  value = {
    keycloak = var.keycloak.expose_public && try(local.infra.api_server_host, "") != "" ? "http://${local.infra.api_server_host}:${var.keycloak.host_port}/" : null
  }
}
