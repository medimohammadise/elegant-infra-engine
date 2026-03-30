locals {
  postgres_access_host = try(trimspace(var.postgres.access_host), "") != "" ? var.postgres.access_host : module.postgres.backstage_host
}

module "docker_network" {
  source = "../../modules/docker-network"

  name              = var.network.name
  create            = var.network.create
  recreate_revision = var.recreate_revision
}

module "postgres" {
  source = "../../modules/postgres"

  create            = var.postgres.create
  network_name      = module.docker_network.name
  bind_address      = var.postgres.bind_address
  port              = var.postgres.port
  db_name           = var.postgres.db_name
  user              = var.postgres.user
  password          = var.postgres.password
  volume_name       = var.postgres.volume_name
  recreate_revision = var.recreate_revision
}

module "kind_cluster" {
  count  = var.kubernetes.create_cluster ? 1 : 0
  source = "../../modules/kind-cluster"

  cluster_name     = var.kubernetes.cluster_name
  api_server_port  = var.kubernetes.api_server_port
  api_server_host  = var.api_server_host
  ssh_context_host = var.ssh_context_host
  worker_count     = var.kubernetes.worker_count
  kind_node_image  = var.kubernetes.kind_node_image
  kubeconfig_path  = try(var.kubernetes.kubeconfig_path, null)

  backstage_port_mapping                = var.backstage_port_mapping
  headlamp_port_mapping                 = var.headlamp_port_mapping
  keycloak_port_mapping                 = var.keycloak_port_mapping
  grafana_port_mapping                  = var.grafana_port_mapping
  prometheus_port_mapping               = var.prometheus_port_mapping
  dependencytrack_api_port_mapping      = var.dependencytrack_api_port_mapping
  dependencytrack_frontend_port_mapping = var.dependencytrack_frontend_port_mapping
  kafka_dashboard_port_mapping          = var.kafka_dashboard_port_mapping
  extra_port_mappings                   = try(var.kubernetes.extra_port_mappings, [])

  recreate_revision = trimspace(try(var.kubernetes.recreate_revision, "")) != "" ? var.kubernetes.recreate_revision : var.recreate_revision

  depends_on = [module.postgres]
}

resource "terraform_data" "kind_cluster_ready" {
  input = var.kubernetes.create_cluster ? "create" : "reuse"

  depends_on = [module.kind_cluster]
}
