output "namespace" {
  description = "Observability namespace."
  value       = module.observability.namespace
}

output "kibana_url" {
  description = "Kibana URL when exposed publicly."
  value = (
    var.observability.kibana.enabled && var.observability.kibana.expose_public
    ? "http://localhost:${var.observability.kibana.host_port}"
    : null
  )
}

output "jaeger_query_url" {
  description = "Jaeger query URL when exposed publicly."
  value = (
    var.observability.jaeger.enabled && var.observability.jaeger.expose_public
    ? "http://localhost:${var.observability.jaeger.query_host_port}"
    : null
  )
}
