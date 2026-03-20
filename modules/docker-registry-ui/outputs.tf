output "container_id" {
  description = "ID of the registry UI container."
  value       = docker_container.this.id
}

output "external_port" {
  description = "Registry UI host port."
  value       = var.external_port
}
