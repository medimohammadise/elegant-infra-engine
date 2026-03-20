output "namespace" {
  description = "Backstage namespace."
  value       = module.backstage.namespace
}

output "release_name" {
  description = "Backstage Helm release name."
  value       = module.backstage.release_name
}
