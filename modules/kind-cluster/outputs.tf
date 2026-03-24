output "cluster_name" {
  description = "Name of the provisioned kind cluster."
  value       = var.cluster_name
}

output "endpoint" {
  description = "Reachable Kubernetes API endpoint."
  value       = "https://${var.api_server_host}:${var.api_server_port}"
}

output "kubeconfig" {
  description = "Rendered kubeconfig content."
  value       = try(file(local.kubeconfig_path), null)
  sensitive   = true
}

output "kubeconfig_path" {
  description = "Path to the rendered kubeconfig file."
  value       = local.kubeconfig_path
}

output "client_certificate" {
  description = "Client certificate of the kind cluster."
  value       = try(yamldecode(file(local.kubeconfig_path)).users[0].user.client-certificate-data, null)
  sensitive   = true
}

output "client_key" {
  description = "Client key of the kind cluster."
  value       = try(yamldecode(file(local.kubeconfig_path)).users[0].user.client-key-data, null)
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "CA certificate of the kind cluster."
  value       = try(yamldecode(file(local.kubeconfig_path)).clusters[0].cluster.certificate-authority-data, null)
  sensitive   = true
}
