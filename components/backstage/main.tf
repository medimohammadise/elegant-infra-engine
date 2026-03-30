data "terraform_remote_state" "infra" {
  backend = "local"
  config = {
    path = "${path.module}/../infra/terraform.tfstate"
  }
}

module "backstage_namespace" {
  source = "../../modules/k8s-namespace"

  name = var.backstage.namespace
}

module "backstage" {
  source = "../../modules/backstage"

  namespace                  = module.backstage_namespace.name
  chart_version              = var.backstage.chart_version
  image_repository           = var.backstage.image_repository
  image_tag                  = var.backstage.image_tag
  base_url                   = var.backstage.base_url
  backend_auth_key           = var.backstage_backend_auth_key
  auth_provider              = var.backstage_auth_provider
  keycloak_base_url          = var.backstage_keycloak_base_url
  keycloak_realm             = var.backstage_keycloak_realm
  keycloak_client_id         = var.backstage_keycloak_client_id
  keycloak_client_secret     = var.backstage_keycloak_client_secret
  oauth2_proxy_cookie_secret = var.backstage_oauth2_proxy_cookie_secret
  public_node_port           = var.backstage.expose_public && var.backstage_auth_provider == "keycloak_proxy" ? var.backstage.node_port : null
  service_type               = var.backstage.expose_public && var.backstage_auth_provider != "keycloak_proxy" ? "NodePort" : "ClusterIP"
  node_port                  = var.backstage.expose_public && var.backstage_auth_provider != "keycloak_proxy" ? var.backstage.node_port : null
  postgres_host              = data.terraform_remote_state.infra.outputs.postgres_host
  postgres_port              = data.terraform_remote_state.infra.outputs.postgres_port
  postgres_db_name           = data.terraform_remote_state.infra.outputs.postgres_db_name
  postgres_user              = data.terraform_remote_state.infra.outputs.postgres_user
  postgres_password          = var.postgres.password
  recreate_revision          = var.recreate_revision

  depends_on = [module.backstage_namespace]
}
