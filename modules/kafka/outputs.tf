output "namespace" {
  description = "Namespace where Kafka and the dashboard are installed."
  value       = var.namespace
}

output "kafka_release_name" {
  description = "Kafka Helm release name."
  value       = helm_release.kafka.name
}

output "dashboard_release_name" {
  description = "Kafka dashboard Helm release name."
  value       = helm_release.dashboard.name
}

output "bootstrap_servers" {
  description = "In-cluster Kafka bootstrap servers."
  value       = local.kafka_bootstrap_servers
}

output "public_bootstrap_servers" {
  description = "Externally reachable Kafka bootstrap servers when public access is enabled."
  value       = local.kafka_public_bootstrap_servers
}

output "dashboard_url" {
  description = "Configured Kafka dashboard URL when publicly exposed."
  value       = local.dashboard_url
}
