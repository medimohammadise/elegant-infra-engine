module "observability_namespace" {
  source = "../../modules/k8s-namespace"

  name = var.observability.namespace
}

module "observability" {
  source = "../../modules/observability"

  namespace         = module.observability_namespace.name
  elasticsearch     = var.observability.elasticsearch
  fluentd           = var.observability.fluentd
  kibana            = var.observability.kibana
  jaeger            = var.observability.jaeger
  recreate_revision = var.recreate_revision

  depends_on = [module.observability_namespace]
}
