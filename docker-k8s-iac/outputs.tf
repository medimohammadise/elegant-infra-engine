# outputs.tf

output "registry_container_id" {
  description = "The ID of the registry container"
  value       = module.pre-k8s.registry_container_id
}

output "postgres_container_id" {
  description = "The ID of the PostgreSQL container"
  value       = module.pre-k8s.postgres_container_id
}

output "cluster_name" {
  description = "The name of the provisioned kind cluster"
  value       = module.kind-cluster.cluster_name
}

output "kubernetes_api_endpoint" {
  description = "The endpoint of the Kubernetes API Server"
  value       = module.kind-cluster.endpoint
}

output "backstage_url" {
  description = "The configured Backstage base URL"
  value       = var.enable_backstage ? local.backstage_base_url : null
}
