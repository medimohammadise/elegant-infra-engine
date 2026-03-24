output "container_name" {
  description = "Name of the Kafka UI proxy container."
  value       = try(docker_container.this[0].name, var.container_name)
}

output "external_port" {
  description = "Kafka UI proxy host port."
  value       = var.external_port
}
