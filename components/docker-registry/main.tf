module "docker_network" {
  source = "../../modules/docker-network"

  name              = var.registry.network_name
  create            = var.registry.create_network
  recreate_revision = var.recreate_revision
}

module "docker_registry" {
  source = "../../modules/docker-registry"

  network_name      = module.docker_network.name
  bind_address      = var.registry.bind_address
  external_port     = var.registry.port
  recreate_revision = var.recreate_revision
}

module "docker_registry_ui" {
  source = "../../modules/docker-registry-ui"

  network_name          = module.docker_network.name
  bind_address          = var.registry.ui_bind
  external_port         = var.registry.ui_port
  registry_title        = var.registry.title
  registry_internal_url = "http://${module.docker_registry.container_name}:5000"
  registry_external_url = "http://${var.api_server_host}:${var.registry.ui_port}"
  image_registry        = "${var.api_server_host}:${var.registry.port}"
  recreate_revision     = var.recreate_revision

  depends_on = [module.docker_registry]
}
