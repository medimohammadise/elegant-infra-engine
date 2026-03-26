output "registry_url" {
  description = "Docker registry endpoint."
  value       = "http://${var.api_server_host}:${var.registry.port}"
}

output "registry_ui_url" {
  description = "Docker registry UI URL."
  value = (
    contains(["127.0.0.1", "localhost"], var.registry.ui_bind)
    ? "http://${var.registry.ui_bind}:${var.registry.ui_port}"
    : "http://${var.api_server_host}:${var.registry.ui_port}"
  )
}

output "postgres_port" {
  description = "PostgreSQL host port."
  value       = module.postgres.port
}

output "cluster_name" {
  description = "Provisioned kind cluster name."
  value       = var.kubernetes.create_cluster ? module.kind_cluster[0].cluster_name : local.kind_cluster_name
}

output "kubernetes_api_endpoint" {
  description = "Reachable Kubernetes API endpoint."
  value       = var.kubernetes.create_cluster ? module.kind_cluster[0].endpoint : local.kind_cluster_endpoint
}

output "kubeconfig_path" {
  description = "Path to the generated kubeconfig file."
  value       = local.kubeconfig_path
}

output "backstage_url" {
  description = "Configured Backstage URL."
  value       = var.backstage.enabled ? local.backstage_base_url : null
}

output "headlamp_url" {
  description = "Configured Headlamp URL when publicly exposed."
  value       = var.headlamp.enabled && var.headlamp.expose_public ? "http://${var.api_server_host}:${var.headlamp.host_port}" : null
}

output "kafka_bootstrap_servers" {
  description = "In-cluster Kafka bootstrap servers."
  value       = var.kafka.enabled ? module.kafka[0].bootstrap_servers : null
}

output "kafka_public_bootstrap_servers" {
  description = "Externally reachable Kafka bootstrap servers when public access is enabled."
  value       = var.kafka.enabled ? module.kafka[0].public_bootstrap_servers : null
}

output "kafka_dashboard_url" {
  description = "Configured Kafka dashboard URL when publicly exposed."
  value       = local.kafka_dashboard_public_url
}

output "keycloak_url" {
  description = "Configured external Keycloak URL."
  value       = var.keycloak.enabled && var.keycloak.expose_public ? local.keycloak_public_url : var.keycloak_url
}

output "grafana_url" {
  description = "Configured Grafana URL when publicly exposed."
  value       = local.grafana_public_url
}

output "prometheus_url" {
  description = "Configured Prometheus URL when publicly exposed."
  value       = local.prometheus_public_url
}

output "dependencytrack_api_url" {
  description = "Dependency-Track API server URL when publicly exposed."
  value       = local.dependencytrack_api_url
}

output "dependencytrack_frontend_url" {
  description = "Dependency-Track frontend URL when publicly exposed."
  value       = local.dependencytrack_frontend_url
}

output "exposed_urls" {
  description = "Consolidated platform endpoints, including optional external dependencies."
  value = {
    kubernetes_api = var.kubernetes.create_cluster ? module.kind_cluster[0].endpoint : local.kind_cluster_endpoint
    registry       = "http://${var.api_server_host}:${var.registry.port}"
    registry_ui = (
      contains(["127.0.0.1", "localhost"], var.registry.ui_bind)
      ? "http://${var.registry.ui_bind}:${var.registry.ui_port}"
      : "http://${var.api_server_host}:${var.registry.ui_port}"
    )
    backstage                = var.backstage.enabled ? local.backstage_base_url : null
    headlamp                 = var.headlamp.enabled && var.headlamp.expose_public ? "http://${var.api_server_host}:${var.headlamp.host_port}" : null
    kafka                    = var.kafka.enabled ? module.kafka[0].public_bootstrap_servers : null
    kafka_dashboard          = local.kafka_dashboard_public_url
    keycloak                 = var.keycloak.enabled && var.keycloak.expose_public ? local.keycloak_public_url : var.keycloak_url
    grafana                  = local.grafana_public_url
    prometheus               = local.prometheus_public_url
    dependencytrack_api      = local.dependencytrack_api_url
    dependencytrack_frontend = local.dependencytrack_frontend_url
  }
}
