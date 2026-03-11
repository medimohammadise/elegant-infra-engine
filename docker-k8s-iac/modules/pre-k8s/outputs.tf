# outputs.tf

output "registry_container_id" {
  description = "The ID of the registry container"
  value       = docker_container.registry.id
}
