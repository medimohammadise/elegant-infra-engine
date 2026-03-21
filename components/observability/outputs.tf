output "namespace" {
  description = "Observability namespace."
  value       = module.observability.namespace
}

output "kibana_url" {
  description = "Kibana URL when exposed publicly or through ingress."
  value = (
    var.observability.kibana.enabled && try(var.observability.kibana.ingress.enabled, false)
    ? "http://${var.observability.kibana.ingress.host}"
    : var.observability.kibana.enabled && var.observability.kibana.expose_public
    ? "http://${var.api_server_host}:${var.observability.kibana.host_port}"
    : null
  )
}

output "jaeger_query_url" {
  description = "Jaeger query URL when exposed publicly or through ingress."
  value = (
    var.observability.jaeger.enabled && try(var.observability.jaeger.ingress.enabled, false)
    ? "http://${var.observability.jaeger.ingress.host}"
    : var.observability.jaeger.enabled && var.observability.jaeger.expose_public
    ? "http://${var.api_server_host}:${var.observability.jaeger.query_host_port}"
    : null
  )
}
