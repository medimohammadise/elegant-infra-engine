output "name" {
  description = "Keycloak workload name."
  value       = kubernetes_deployment.this.metadata[0].name
}

output "namespace" {
  description = "Namespace where Keycloak is installed."
  value       = kubernetes_deployment.this.metadata[0].namespace
}

output "service_name" {
  description = "Kubernetes Service name exposing Keycloak."
  value       = kubernetes_service.this.metadata[0].name
}
