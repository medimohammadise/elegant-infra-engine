output "namespace" {
  description = "Headlamp namespace."
  value       = module.headlamp.namespace
}

output "service_account_name" {
  description = "Headlamp service account name when created."
  value       = module.headlamp.service_account_name
}

output "headlamp_url" {
  description = "Externally reachable Headlamp URL when public exposure is enabled."
  value = var.headlamp.expose_public && try(local.infra.api_server_host, "") != "" ?
    "http://${local.infra.api_server_host}:${var.headlamp.host_port}" : null
}
