module "dashboard_namespace" {
  source = "../../modules/k8s-namespace"

  name = var.dashboard.namespace
}

module "kubernetes_dashboard" {
  source = "../../modules/kubernetes-dashboard"

  namespace         = module.dashboard_namespace.name
  chart_url         = var.dashboard.chart_url
  service_type      = var.dashboard.expose_public ? "NodePort" : "ClusterIP"
  node_port         = var.dashboard.expose_public ? var.dashboard.node_port : null
  create_admin_user = var.dashboard.create_admin_user
  admin_user_name   = var.dashboard.admin_user_name
  recreate_revision = var.recreate_revision

  depends_on = [module.dashboard_namespace]
}
