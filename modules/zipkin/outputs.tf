output "name" {
  description = "Zipkin deployment name."
  value       = kubernetes_deployment.this.metadata[0].name
}

output "namespace" {
  description = "Namespace where Zipkin is installed."
  value       = kubernetes_deployment.this.metadata[0].namespace
}

output "service_name" {
  description = "Zipkin service name."
  value       = kubernetes_service.this.metadata[0].name
}
