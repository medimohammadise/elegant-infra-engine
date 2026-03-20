output "registry_url" {
  description = "Docker registry endpoint."
  value       = "http://${var.api_server_host}:${var.registry.port}"
}

output "registry_ui_url" {
  description = "Docker registry UI URL."
  value = (
    contains(["127.0.0.1", "localhost"], var.registry.ui_bind)
    ? "http://${var.registry.ui_bind}:${var.registry.ui_port}"
    : "http://${var.api_server_host}:${var.registry.ui_port}"
  )
}
