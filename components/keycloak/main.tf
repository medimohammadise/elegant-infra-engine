data "terraform_remote_state" "infra" {
  backend = "local"
  config = {
    path = "${path.module}/../infra/terraform.tfstate"
  }
}

locals {
  infra = data.terraform_remote_state.infra.outputs
}

module "keycloak_namespace" {
  source = "../../modules/k8s-namespace"

  name = var.keycloak.namespace
}

module "keycloak" {
  source = "../../modules/keycloak"

  name              = var.keycloak.name
  namespace         = module.keycloak_namespace.name
  image             = "${var.keycloak.image_repository}:${var.keycloak.image_tag}"
  replicas          = var.keycloak.replicas
  service_type      = var.keycloak.expose_public ? "NodePort" : "ClusterIP"
  node_port         = var.keycloak.expose_public ? var.keycloak.node_port : null
  admin_username    = var.keycloak.admin_username
  admin_password    = var.keycloak.admin_password
  database_host     = data.terraform_remote_state.infra.outputs.postgres_host
  database_port     = data.terraform_remote_state.infra.outputs.postgres_port
  database_name     = data.terraform_remote_state.infra.outputs.postgres_db_name
  database_user     = data.terraform_remote_state.infra.outputs.postgres_user
  database_password = var.postgres_password
  recreate_revision = var.recreate_revision

  depends_on = [module.keycloak_namespace]
}
