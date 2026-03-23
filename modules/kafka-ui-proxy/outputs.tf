output "container_name" {
  description = "Name of the Kafka UI proxy container."
  value       = docker_container.this.name
}

output "external_port" {
  description = "Kafka UI proxy host port."
  value       = var.external_port
}
