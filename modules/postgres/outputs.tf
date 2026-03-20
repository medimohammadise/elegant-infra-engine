output "container_id" {
  description = "ID of the PostgreSQL container."
  value       = docker_container.this.id
}

output "container_name" {
  description = "Name of the PostgreSQL container."
  value       = docker_container.this.name
}

output "port" {
  description = "Host port exposed by PostgreSQL."
  value       = nonsensitive(var.port)
}

output "db_name" {
  description = "Configured PostgreSQL database name."
  value       = nonsensitive(var.db_name)
}

output "user" {
  description = "Configured PostgreSQL application user."
  value       = nonsensitive(var.user)
}

output "backstage_host" {
  description = "Hostname kind workloads can use to reach PostgreSQL on the Docker host."
  value       = "host.docker.internal"
}
