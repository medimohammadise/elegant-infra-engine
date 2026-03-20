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

output "dashboard_url" {
  description = "Configured Kubernetes Dashboard URL when publicly exposed."
  value       = var.dashboard.enabled && var.dashboard.expose_public ? "https://${var.api_server_host}:${var.dashboard.host_port}" : null
}


output "kibana_url" {
  description = "Configured Kibana URL when publicly exposed."
  value       = var.observability.enabled && var.observability.kibana.enabled && var.observability.kibana.expose_public ? local.kibana_base_url : null
}

output "jaeger_query_url" {
  description = "Configured Jaeger query URL when publicly exposed."
  value       = var.observability.enabled && var.observability.jaeger.enabled && var.observability.jaeger.expose_public ? local.jaeger_base_url : null
}
