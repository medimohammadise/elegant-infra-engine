output "container_id" {
  description = "ID of the registry container."
  value       = try(docker_container.this[0].id, null)
}

output "container_name" {
  description = "Name of the registry container."
  value       = try(docker_container.this[0].name, var.container_name)
}

output "external_port" {
  description = "Registry host port."
  value       = var.external_port
}
