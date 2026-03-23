output "namespace" {
  description = "Kafka namespace."
  value       = module.kafka.namespace
}

output "kafka_release_name" {
  description = "Kafka Helm release name."
  value       = module.kafka.kafka_release_name
}

output "dashboard_release_name" {
  description = "Kafka dashboard Helm release name."
  value       = module.kafka.dashboard_release_name
}

output "bootstrap_servers" {
  description = "In-cluster Kafka bootstrap servers."
  value       = module.kafka.bootstrap_servers
}

output "public_bootstrap_servers" {
  description = "Externally reachable Kafka bootstrap servers when public access is enabled."
  value       = module.kafka.public_bootstrap_servers
}

output "dashboard_url" {
  description = "Configured Kafka dashboard URL when publicly exposed."
  value       = module.kafka.dashboard_url
}

output "exposed_urls" {
  description = "Consolidated Kafka endpoints."
  value = {
    kafka           = module.kafka.public_bootstrap_servers
    kafka_dashboard = module.kafka.dashboard_url
  }
}
