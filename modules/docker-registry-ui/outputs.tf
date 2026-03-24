output "container_id" {
  description = "ID of the registry UI container."
  value       = try(docker_container.this[0].id, null)
}

output "external_port" {
  description = "Registry UI host port."
  value       = var.external_port
}
