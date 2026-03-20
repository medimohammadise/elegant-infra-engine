module "backstage_namespace" {
  source = "../../modules/k8s-namespace"

  name = var.backstage.namespace
}

module "backstage" {
  source = "../../modules/backstage"

  namespace         = module.backstage_namespace.name
  chart_version     = var.backstage.chart_version
  image_tag         = var.backstage.image_tag
  base_url          = var.backstage.base_url
  service_type      = var.backstage.expose_public ? "NodePort" : "ClusterIP"
  node_port         = var.backstage.expose_public ? var.backstage.node_port : null
  postgres_host     = var.postgres.host
  postgres_port     = var.postgres.port
  postgres_db_name  = var.postgres.db_name
  postgres_user     = var.postgres.user
  postgres_password = var.postgres.password
  recreate_revision = var.recreate_revision

  depends_on = [module.backstage_namespace]
}
