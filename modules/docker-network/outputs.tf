output "id" {
  description = "ID of the Docker network."
  value       = one(concat(docker_network.this[*].id, data.docker_network.existing[*].id))
}

output "name" {
  description = "Name of the Docker network."
  value       = one(concat(docker_network.this[*].name, data.docker_network.existing[*].name))
}
