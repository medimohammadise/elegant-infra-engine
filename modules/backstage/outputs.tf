output "release_name" {
  description = "Backstage Helm release name."
  value       = helm_release.this.name
}

output "namespace" {
  description = "Namespace where Backstage is installed."
  value       = helm_release.this.namespace
}
