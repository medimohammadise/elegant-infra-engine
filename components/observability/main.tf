module "observability_namespace" {
  source = "../../modules/k8s-namespace"

  name = var.observability.namespace
}

module "ingress_nginx" {
  count  = var.ingress_nginx.enabled ? 1 : 0
  source = "../../modules/ingress-nginx"

  namespace             = var.ingress_nginx.namespace
  chart_version         = var.ingress_nginx.chart_version
  ingress_class_name    = var.ingress_nginx.ingress_class_name
  default_ingress_class = var.ingress_nginx.default_ingress_class
  http_node_port        = var.ingress_nginx.http_node_port
  https_node_port       = var.ingress_nginx.https_node_port
  recreate_revision     = trimspace(try(var.ingress_nginx.recreate_revision, "")) != "" ? var.ingress_nginx.recreate_revision : var.recreate_revision
}

module "observability" {
  source = "../../modules/observability"

  namespace         = module.observability_namespace.name
  elasticsearch     = var.observability.elasticsearch
  fluentd           = var.observability.fluentd
  kibana            = var.observability.kibana
  jaeger            = var.observability.jaeger
  recreate_revision = var.recreate_revision

  depends_on = [module.observability_namespace, module.ingress_nginx]
}
