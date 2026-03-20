output "cluster_name" {
  description = "Name of the provisioned kind cluster."
  value       = kind_cluster.this.name
}

output "endpoint" {
  description = "Reachable Kubernetes API endpoint."
  value       = "https://${var.api_server_host}:${var.api_server_port}"
}

output "kubeconfig" {
  description = "Rendered kubeconfig content."
  value       = local_sensitive_file.kubeconfig.content
  sensitive   = true
}

output "kubeconfig_path" {
  description = "Path to the rendered kubeconfig file."
  value       = local_sensitive_file.kubeconfig.filename
}

output "client_certificate" {
  description = "Client certificate of the kind cluster."
  value       = kind_cluster.this.client_certificate
  sensitive   = true
}

output "client_key" {
  description = "Client key of the kind cluster."
  value       = kind_cluster.this.client_key
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "CA certificate of the kind cluster."
  value       = kind_cluster.this.cluster_ca_certificate
  sensitive   = true
}
