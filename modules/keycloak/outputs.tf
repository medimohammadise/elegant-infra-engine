output "name" {
  description = "Keycloak deployment name."
  value       = kubernetes_deployment.this.metadata[0].name
}

output "namespace" {
  description = "Keycloak namespace."
  value       = kubernetes_deployment.this.metadata[0].namespace
}

output "service_name" {
  description = "Keycloak service name."
  value       = kubernetes_service.this.metadata[0].name
}
