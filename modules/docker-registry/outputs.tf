output "container_id" {
  description = "ID of the registry container."
  value       = docker_container.this.id
}

output "container_name" {
  description = "Name of the registry container."
  value       = docker_container.this.name
}

output "external_port" {
  description = "Registry host port."
  value       = var.external_port
}
