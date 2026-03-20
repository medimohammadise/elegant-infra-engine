output "cluster_name" {
  description = "Provisioned kind cluster name."
  value       = module.kind_cluster.cluster_name
}

output "kubernetes_api_endpoint" {
  description = "Reachable Kubernetes API endpoint."
  value       = module.kind_cluster.endpoint
}

output "kubeconfig_path" {
  description = "Path to the generated kubeconfig file."
  value       = module.kind_cluster.kubeconfig_path
}
