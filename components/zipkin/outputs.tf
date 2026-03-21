output "namespace" {
  description = "Zipkin namespace."
  value       = module.zipkin.namespace
}

output "service_name" {
  description = "Zipkin Kubernetes service name."
  value       = module.zipkin.service_name
}
