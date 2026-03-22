output "namespace" {
  description = "Namespace where observability stack is installed."
  value       = var.namespace
}

output "grafana_release_name" {
  description = "Grafana Helm release name."
  value       = helm_release.grafana.name
}

output "loki_release_name" {
  description = "Loki Helm release name."
  value       = try(helm_release.loki[0].name, null)
}

output "tempo_release_name" {
  description = "Tempo Helm release name."
  value       = try(helm_release.tempo[0].name, null)
}

output "prometheus_release_name" {
  description = "Prometheus Helm release name when enabled."
  value       = try(helm_release.prometheus[0].name, null)
}
