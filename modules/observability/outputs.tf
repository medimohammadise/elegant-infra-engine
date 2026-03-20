output "namespace" {
  description = "Namespace where observability components are installed."
  value       = var.namespace
}

output "kibana_release_name" {
  description = "Kibana Helm release name when enabled."
  value       = var.kibana.enabled ? helm_release.kibana[0].name : null
}

output "jaeger_release_name" {
  description = "Jaeger Helm release name when enabled."
  value       = var.jaeger.enabled ? helm_release.jaeger[0].name : null
}
