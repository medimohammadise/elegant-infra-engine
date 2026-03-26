locals {
  network_id   = length(docker_network.this) > 0 ? docker_network.this[0].id : try(data.external.network_exists.result.id, "")
  network_name = var.name
}

output "id" {
  description = "ID of the Docker network."
  value       = local.network_id
}

output "name" {
  description = "Name of the Docker network."
  value       = local.network_name
}
