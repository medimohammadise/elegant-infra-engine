module "keycloak_namespace" {
  source = "../../modules/k8s-namespace"

  name = var.keycloak.namespace
}

module "keycloak" {
  source = "../../modules/keycloak"

  namespace         = module.keycloak_namespace.name
  image_repository  = var.keycloak.image_repository
  image_tag         = var.keycloak.image_tag
  replicas          = var.keycloak.replicas
  service_type      = var.keycloak.expose_public ? "NodePort" : "ClusterIP"
  node_port         = var.keycloak.expose_public ? var.keycloak.node_port : null
  admin_username    = var.keycloak.admin_username
  admin_password    = var.keycloak.admin_password
  recreate_revision = trimspace(try(var.keycloak.recreate_revision, "")) != "" ? var.keycloak.recreate_revision : var.recreate_revision

  depends_on = [module.keycloak_namespace]
}
