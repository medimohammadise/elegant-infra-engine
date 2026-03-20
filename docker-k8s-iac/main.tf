# main.tf

locals {
  backstage_base_url = trimspace(var.backstage_base_url) != "" ? var.backstage_base_url : "https://${var.api_server_host}:${var.backstage_host_port}"
}

module "pre-k8s" {
  source = "./modules/pre-k8s"

  registry_bind_address = var.registry_bind_address
  ui_bind_address       = var.ui_bind_address
  registry_title        = var.registry_title
  registry_ui_url       = "http://${var.api_server_host}:8081"
  image_registry        = "${var.api_server_host}:5000"
  postgres_bind_address = var.postgres_bind_address
  postgres_port         = var.postgres_port
  postgres_db_name      = var.postgres_db_name
  postgres_user         = var.postgres_user
  postgres_password     = var.postgres_password
  recreate_revision     = var.recreate_revision
}

module "kind-cluster" {
  source = "./modules/kind-cluster"

  cluster_name            = var.cluster_name
  kind_node_image         = var.kind_node_image
  worker_count            = var.worker_count
  ssh_context_host        = var.ssh_context_host
  api_server_host         = var.api_server_host
  api_server_port         = 6443
  expose_backstage_public = var.expose_backstage_public
  backstage_node_port     = var.backstage_node_port
  backstage_host_port     = var.backstage_host_port
  expose_dashboard_public = var.expose_dashboard_public
  dashboard_node_port     = var.dashboard_node_port
  dashboard_host_port     = var.dashboard_host_port
  recreate_revision       = var.recreate_revision

  depends_on = [module.pre-k8s]
}

module "k8s-resources" {
  source = "./modules/k8s-resources"

  kube_namespace              = var.kube_namespace
  enable_backstage            = var.enable_backstage
  backstage_namespace         = var.backstage_namespace
  backstage_chart_version     = var.backstage_chart_version
  backstage_image_tag         = var.backstage_image_tag
  backstage_base_url          = local.backstage_base_url
  expose_backstage_public     = var.expose_backstage_public
  backstage_node_port         = var.backstage_node_port
  postgres_host               = "host.docker.internal"
  postgres_port               = var.postgres_port
  postgres_db_name            = var.postgres_db_name
  postgres_user               = var.postgres_user
  postgres_password           = var.postgres_password
  enable_k8s_dashboard        = var.enable_k8s_dashboard
  dashboard_namespace         = var.dashboard_namespace
  k8s_dashboard_chart_url     = var.k8s_dashboard_chart_url
  expose_dashboard_public     = var.expose_dashboard_public
  dashboard_node_port         = var.dashboard_node_port
  create_dashboard_admin_user = var.create_dashboard_admin_user
  dashboard_admin_user_name   = var.dashboard_admin_user_name
  recreate_revision           = var.recreate_revision

  depends_on = [module.kind-cluster]
}
