locals {
  registry_network_name = var.registry.network_name
  backstage_base_url    = try(trimspace(var.backstage.base_url), "") != "" ? var.backstage.base_url : "https://${var.api_server_host}:${var.backstage.host_port}"
  kind_cluster_name     = try(var.kubernetes.cluster_name, "blitzinfra")
  kind_cluster_endpoint = "https://${var.api_server_host}:${var.kubernetes.api_server_port}"
  kibana_base_url       = "http://${var.api_server_host}:${var.observability.kibana.host_port}"
  jaeger_base_url       = "http://${var.api_server_host}:${var.observability.jaeger.query_host_port}"
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
  dashboard_port_mapping = var.dashboard.enabled && var.dashboard.expose_public ? {
    node_port = var.dashboard.node_port
    host_port = var.dashboard.host_port
  } : null
  observability_kibana_port_mapping = var.observability.enabled && var.observability.kibana.enabled && var.observability.kibana.expose_public ? {
    node_port = var.observability.kibana.node_port
    host_port = var.observability.kibana.host_port
  } : null
  observability_jaeger_port_mapping = var.observability.enabled && var.observability.jaeger.enabled && var.observability.jaeger.expose_public ? {
    node_port = var.observability.jaeger.query_node_port
    host_port = var.observability.jaeger.query_host_port
  } : null
  recreate_revision = trimspace(try(var.kubernetes.recreate_revision, "")) != "" ? var.kubernetes.recreate_revision : var.recreate_revision

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

module "dashboard_namespace" {
  count  = var.dashboard.enabled ? 1 : 0
  source = "../../modules/k8s-namespace"

  name = var.dashboard.namespace

  depends_on = [terraform_data.kind_cluster_ready]
}

module "kubernetes_dashboard" {
  count  = var.dashboard.enabled ? 1 : 0
  source = "../../modules/kubernetes-dashboard"

  namespace         = module.dashboard_namespace[0].name
  chart_url         = var.dashboard.chart_url
  service_type      = var.dashboard.expose_public ? "NodePort" : "ClusterIP"
  node_port         = var.dashboard.expose_public ? var.dashboard.node_port : null
  create_admin_user = var.dashboard.create_admin_user
  admin_user_name   = var.dashboard.admin_user_name
  recreate_revision = trimspace(try(var.dashboard.recreate_revision, "")) != "" ? var.dashboard.recreate_revision : var.recreate_revision

  depends_on = [module.dashboard_namespace]
}


module "observability_namespace" {
  count  = var.observability.enabled ? 1 : 0
  source = "../../modules/k8s-namespace"

  name = var.observability.namespace

  depends_on = [terraform_data.kind_cluster_ready]
}

module "observability" {
  count  = var.observability.enabled ? 1 : 0
  source = "../../modules/observability"

  namespace         = module.observability_namespace[0].name
  elasticsearch     = var.observability.elasticsearch
  fluentd           = var.observability.fluentd
  kibana            = var.observability.kibana
  jaeger            = var.observability.jaeger
  recreate_revision = trimspace(try(var.observability.recreate_revision, "")) != "" ? var.observability.recreate_revision : var.recreate_revision

  depends_on = [module.observability_namespace]
}
