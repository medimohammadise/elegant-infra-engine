locals {
  registry_network_name = var.registry.network_name
  backstage_base_url    = try(trimspace(var.backstage.base_url), "") != "" ? var.backstage.base_url : "https://${var.api_server_host}:${var.backstage.host_port}"
  kind_cluster_name     = try(var.kubernetes.cluster_name, "blitzinfra")
  kind_cluster_endpoint = "https://${var.api_server_host}:${var.kubernetes.api_server_port}"
}

module "docker_network" {
  source = "../../modules/docker-network"

  name              = local.registry_network_name
  create            = var.registry.create_network
  recreate_revision = var.recreate_revision
}

module "postgres" {
  source = "../../modules/postgres"

  network_name      = module.docker_network.name
  bind_address      = var.postgres.bind_address
  port              = var.postgres.port
  db_name           = var.postgres.db_name
  user              = var.postgres.user
  password          = var.postgres.password
  volume_name       = var.postgres.volume_name
  recreate_revision = var.recreate_revision
}

module "docker_registry" {
  source = "../../modules/docker-registry"

  network_name      = module.docker_network.name
  bind_address      = var.registry.bind_address
  external_port     = var.registry.port
  recreate_revision = var.recreate_revision
}

module "docker_registry_ui" {
  source = "../../modules/docker-registry-ui"

  network_name          = module.docker_network.name
  bind_address          = var.registry.ui_bind
  external_port         = var.registry.ui_port
  registry_title        = var.registry.title
  registry_internal_url = "http://${module.docker_registry.container_name}:5000"
  registry_external_url = "http://${var.api_server_host}:${var.registry.ui_port}"
  image_registry        = "${var.api_server_host}:${var.registry.port}"
  recreate_revision     = var.recreate_revision

  depends_on = [module.docker_registry]
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
  backstage_port_mapping = var.backstage.enabled && var.backstage.expose_public ? {
    node_port = var.backstage.node_port
    host_port = var.backstage.host_port
  } : null
  headlamp_port_mapping = var.headlamp.enabled && var.headlamp.expose_public ? {
    node_port = var.headlamp.node_port
    host_port = var.headlamp.host_port
  } : null
  keycloak_port_mapping = var.keycloak_port_mapping
  recreate_revision     = trimspace(try(var.kubernetes.recreate_revision, "")) != "" ? var.kubernetes.recreate_revision : var.recreate_revision

  depends_on = [module.postgres]
}

resource "terraform_data" "kind_cluster_ready" {
  input = var.kubernetes.create_cluster ? "create" : "reuse"

  depends_on = [module.kind_cluster]
}

module "bootstrap_namespace" {
  count  = trimspace(var.bootstrap_namespace) != "" ? 1 : 0
  source = "../../modules/k8s-namespace"

  name = var.bootstrap_namespace

  depends_on = [terraform_data.kind_cluster_ready]
}

module "backstage_namespace" {
  count  = var.backstage.enabled ? 1 : 0
  source = "../../modules/k8s-namespace"

  name = var.backstage.namespace

  depends_on = [terraform_data.kind_cluster_ready]
}

module "backstage" {
  count  = var.backstage.enabled ? 1 : 0
  source = "../../modules/backstage"

  namespace         = module.backstage_namespace[0].name
  chart_version     = var.backstage.chart_version
  image_tag         = var.backstage.image_tag
  base_url          = local.backstage_base_url
  service_type      = var.backstage.expose_public ? "NodePort" : "ClusterIP"
  node_port         = var.backstage.expose_public ? var.backstage.node_port : null
  postgres_host     = module.postgres.backstage_host
  postgres_port     = module.postgres.port
  postgres_db_name  = module.postgres.db_name
  postgres_user     = module.postgres.user
  postgres_password = var.postgres.password
  recreate_revision = trimspace(try(var.backstage.recreate_revision, "")) != "" ? var.backstage.recreate_revision : var.recreate_revision

  depends_on = [module.backstage_namespace]
}

module "headlamp_namespace" {
  count  = var.headlamp.enabled ? 1 : 0
  source = "../../modules/k8s-namespace"

  name = var.headlamp.namespace

  depends_on = [terraform_data.kind_cluster_ready]
}

module "headlamp" {
  count  = var.headlamp.enabled ? 1 : 0
  source = "../../modules/headlamp"

  namespace                   = module.headlamp_namespace[0].name
  chart_repository            = var.headlamp.chart_repository
  chart_name                  = var.headlamp.chart_name
  chart_version               = var.headlamp.chart_version
  service_type                = var.headlamp.expose_public ? "NodePort" : "ClusterIP"
  node_port                   = var.headlamp.expose_public ? var.headlamp.node_port : null
  create_service_account      = var.headlamp.create_service_account
  service_account_name        = var.headlamp.service_account_name
  create_cluster_role_binding = var.headlamp.create_cluster_role_binding
  cluster_role_name           = var.headlamp.cluster_role_name
  recreate_revision           = trimspace(try(var.headlamp.recreate_revision, "")) != "" ? var.headlamp.recreate_revision : var.recreate_revision

  depends_on = [module.headlamp_namespace]
}
