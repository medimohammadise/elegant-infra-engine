output "namespace" {
  description = "Observability namespace."
  value       = module.observability.namespace
}

output "grafana_release_name" {
  description = "Grafana Helm release name."
  value       = module.observability.grafana_release_name
}

output "grafana_url" {
  description = "Configured Grafana URL when publicly exposed."
  value = var.observability.expose_public && try(local.infra.api_server_host, "") != ""
    ? "http://${local.infra.api_server_host}:${var.observability.grafana_host_port}"
    : null
}

output "prometheus_url" {
  description = "Configured Prometheus URL when publicly exposed."
  value = (
    var.observability.expose_public && try(var.observability.prometheus.enabled, true) && try(local.infra.api_server_host, "") != ""
    ? "http://${local.infra.api_server_host}:${var.observability.prometheus_host_port}"
    : null
  )
}

output "exposed_urls" {
  description = "Consolidated observability endpoints."
  value = {
    grafana = var.observability.expose_public && try(local.infra.api_server_host, "") != "" ? "http://${local.infra.api_server_host}:${var.observability.grafana_host_port}" : null
    prometheus = (
      var.observability.expose_public && try(var.observability.prometheus.enabled, true) && try(local.infra.api_server_host, "") != ""
      ? "http://${local.infra.api_server_host}:${var.observability.prometheus_host_port}"
      : null
    )
  }
}
