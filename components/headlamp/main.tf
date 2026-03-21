module "headlamp_namespace" {
  source = "../../modules/k8s-namespace"

  name = var.headlamp.namespace
}

module "headlamp" {
  source = "../../modules/headlamp"

  namespace                   = module.headlamp_namespace.name
  chart_repository            = var.headlamp.chart_repository
  chart_name                  = var.headlamp.chart_name
  chart_version               = var.headlamp.chart_version
  service_type                = var.headlamp.expose_public ? "NodePort" : "ClusterIP"
  node_port                   = var.headlamp.expose_public ? var.headlamp.node_port : null
  create_service_account      = var.headlamp.create_service_account
  service_account_name        = var.headlamp.service_account_name
  create_cluster_role_binding = var.headlamp.create_cluster_role_binding
  cluster_role_name           = var.headlamp.cluster_role_name
  recreate_revision           = var.recreate_revision

  depends_on = [module.headlamp_namespace]
}
