locals {
  cluster_name            = try(var.kubernetes.cluster_name, "blitzinfra")
  kubeconfig_default_path = "${path.root}/../kubeconfigs/${local.cluster_name}-kubeconfig"
  kubeconfig_path = var.kubernetes.create_cluster ? (
    module.kind_cluster[0].kubeconfig_path
    ) : (
    try(trimspace(var.kubernetes.kubeconfig_path), "") != "" ? var.kubernetes.kubeconfig_path : (
      fileexists(local.kubeconfig_default_path) ? local.kubeconfig_default_path : "${path.root}/../kubeconfigs/blitzinfra-kubeconfig"
    )
  )
}

output "kubeconfig_path" {
  description = "Path to the generated kubeconfig file."
  value       = local.kubeconfig_path
}

output "cluster_name" {
  description = "Provisioned kind cluster name."
  value       = var.kubernetes.create_cluster ? module.kind_cluster[0].cluster_name : local.cluster_name
}

output "kubernetes_api_endpoint" {
  description = "Reachable Kubernetes API endpoint."
  value       = var.kubernetes.create_cluster ? module.kind_cluster[0].endpoint : "https://${var.api_server_host}:${var.kubernetes.api_server_port}"
}

output "api_server_host" {
  description = "Host name or IP exposed by the kind API server and public services."
  value       = var.api_server_host
}

output "ssh_context_host" {
  description = "Target SSH host for Docker access."
  value       = var.ssh_context_host
}

output "postgres_host" {
  description = "Hostname for kind workloads to reach PostgreSQL on the Docker host."
  value       = local.postgres_access_host
}

output "postgres_port" {
  description = "PostgreSQL host port."
  value       = module.postgres.port
}

output "postgres_db_name" {
  description = "PostgreSQL database name."
  value       = module.postgres.db_name
}

output "postgres_user" {
  description = "PostgreSQL application user."
  value       = module.postgres.user
}

output "docker_network_name" {
  description = "Docker network name used by infrastructure containers."
  value       = module.docker_network.name
}
