output "postgres_port" {
  description = "PostgreSQL host port."
  value       = module.postgres.port
}

output "backstage_host" {
  description = "Hostname kind workloads can use to reach PostgreSQL on the Docker host."
  value       = module.postgres.backstage_host
}
