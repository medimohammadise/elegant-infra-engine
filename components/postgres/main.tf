module "docker_network" {
  source = "../../modules/docker-network"

  name              = var.postgres.network_name
  create            = var.postgres.create_network
  recreate_revision = var.recreate_revision
}

module "postgres" {
  source = "../../modules/postgres"

  create            = var.postgres.create
  network_name      = module.docker_network.name
  bind_address      = var.postgres.bind_address
  port              = var.postgres.port
  db_name           = var.postgres.db_name
  user              = var.postgres.user
  password          = var.postgres.password
  volume_name       = var.postgres.volume_name
  recreate_revision = var.recreate_revision
}
