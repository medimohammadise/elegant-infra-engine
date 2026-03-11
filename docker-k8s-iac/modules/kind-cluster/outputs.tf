# outputs.tf

output "kubeconfig" {
  description = "The kubeconfig of the kind cluster"
  value       = local_sensitive_file.kubeconfig.content
  sensitive   = true
}

output "kubeconfig_path" {
  description = "Path to the corrected kubeconfig file for the kind cluster"
  value       = local_sensitive_file.kubeconfig.filename
}

output "cluster_name" {
  description = "The name of the provisioned cluster"
  value       = kind_cluster.default.name
}

output "endpoint" {
  description = "The reachable endpoint of the API server"
  value       = "https://${var.api_server_host}:${var.api_server_port}"
}

output "client_certificate" {
  description = "The client certificate of the kind cluster"
  value       = kind_cluster.default.client_certificate
  sensitive   = true
}

output "client_key" {
  description = "The client key of the kind cluster"
  value       = kind_cluster.default.client_key
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "The CA certificate of the kind cluster"
  value       = kind_cluster.default.cluster_ca_certificate
  sensitive   = true
}
