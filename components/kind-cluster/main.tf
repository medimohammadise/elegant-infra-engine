module "kind_cluster" {
  source = "../../modules/kind-cluster"

  cluster_name           = var.kubernetes.cluster_name
  api_server_port        = var.kubernetes.api_server_port
  api_server_host        = var.api_server_host
  ssh_context_host       = var.ssh_context_host
  worker_count           = var.kubernetes.worker_count
  kind_node_image        = var.kubernetes.kind_node_image
  kubeconfig_path        = try(var.kubernetes.kubeconfig_path, null)
  backstage_port_mapping = var.backstage_port_mapping
  headlamp_port_mapping  = var.headlamp_port_mapping
  keycloak_port_mapping  = var.keycloak_port_mapping
  recreate_revision      = var.recreate_revision
}
