module "zipkin_namespace" {
  source = "../../modules/k8s-namespace"

  name = var.zipkin.namespace
}

module "zipkin" {
  source = "../../modules/zipkin"

  namespace         = module.zipkin_namespace.name
  release_name      = var.zipkin.release_name
  image             = var.zipkin.image
  service_type      = var.zipkin.expose_public ? "NodePort" : "ClusterIP"
  service_port      = var.zipkin.service_port
  node_port         = var.zipkin.expose_public ? var.zipkin.node_port : null
  recreate_revision = trimspace(try(var.zipkin.recreate_revision, "")) != "" ? var.zipkin.recreate_revision : var.recreate_revision

  depends_on = [module.zipkin_namespace]
}
