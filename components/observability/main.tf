data "terraform_remote_state" "infra" {
  backend = "local"
  config = {
    path = "${path.module}/../infra/terraform.tfstate"
  }
}

locals {
  infra = data.terraform_remote_state.infra.outputs
}

module "observability_namespace" {
  source = "../../modules/k8s-namespace"

  name = var.observability.namespace
}

module "observability" {
  source = "../../modules/observability"

  namespace = module.observability_namespace.name
  grafana = merge(var.observability.grafana, {
    service_type = var.observability.expose_public ? "NodePort" : "ClusterIP"
    node_port    = var.observability.expose_public ? var.observability.grafana_node_port : null
  })
  loki  = var.observability.loki
  tempo = var.observability.tempo
  alloy = var.observability.alloy
  prometheus = merge(var.observability.prometheus, {
    service_type = var.observability.expose_public ? "NodePort" : "ClusterIP"
    node_port    = var.observability.expose_public ? var.observability.prometheus_node_port : null
  })
  recreate_revision = var.recreate_revision

  depends_on = [module.observability_namespace]
}
