# outputs.tf

output "registry_container_id" {
  description = "The ID of the registry container"
  value       = docker_container.registry.id
}

output "postgres_container_id" {
  description = "The ID of the PostgreSQL container"
  value       = docker_container.postgres.id
}
