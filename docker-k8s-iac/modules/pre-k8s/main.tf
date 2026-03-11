# main.tf

terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

resource "terraform_data" "recreate" {
  input = var.recreate_revision
}

resource "docker_network" "registry_net" {
  name = "registry_net"

  lifecycle {
    replace_triggered_by = [terraform_data.recreate]
  }
}

resource "docker_volume" "postgres_data" {
  name = "postgres_data"

  lifecycle {
    replace_triggered_by = [terraform_data.recreate]
  }
}

resource "docker_image" "registry" {
  name         = "registry:2"
  keep_locally = true

  lifecycle {
    replace_triggered_by = [terraform_data.recreate]
  }
}

resource "docker_container" "registry" {
  image   = docker_image.registry.image_id
  name    = "registry"
  restart = "unless-stopped"

  networks_advanced {
    name = docker_network.registry_net.name
  }

  ports {
    internal = 5000
    external = 5000
    ip       = var.registry_bind_address
  }

  env = [
    "REGISTRY_STORAGE_DELETE_ENABLED=true"
  ]

  lifecycle {
    replace_triggered_by = [terraform_data.recreate]
  }
}

resource "docker_image" "registry_ui" {
  name         = "joxit/docker-registry-ui:2.5.7"
  keep_locally = true

  lifecycle {
    replace_triggered_by = [terraform_data.recreate]
  }
}

resource "docker_container" "registry_ui" {
  image   = docker_image.registry_ui.image_id
  name    = "registry-ui"
  restart = "unless-stopped"

  networks_advanced {
    name = docker_network.registry_net.name
  }

  ports {
    internal = 80
    external = 8081
    ip       = var.ui_bind_address
  }

  env = [
    "SINGLE_REGISTRY=true",
    "REGISTRY_TITLE=${var.registry_title}",
    "REGISTRY_URL=${var.registry_ui_url}",
    "NGINX_PROXY_PASS_URL=http://registry:5000",
    "NGINX_RESOLVER=127.0.0.11",
    "PULL_URL=${var.image_registry}"
  ]

  depends_on = [docker_container.registry]

  lifecycle {
    replace_triggered_by = [terraform_data.recreate]
  }
}

resource "docker_image" "postgres" {
  name         = "postgres:16.2"
  keep_locally = true

  lifecycle {
    replace_triggered_by = [terraform_data.recreate]
  }
}

resource "docker_container" "postgres" {
  image   = docker_image.postgres.image_id
  name    = "postgres"
  restart = "unless-stopped"

  networks_advanced {
    name = docker_network.registry_net.name
  }

  ports {
    internal = 5432
    external = var.postgres_port
    ip       = var.postgres_bind_address
  }

  env = [
    "POSTGRES_DB=${var.postgres_db_name}",
    "POSTGRES_USER=${var.postgres_user}",
    "POSTGRES_PASSWORD=${var.postgres_password}"
  ]

  volumes {
    volume_name    = docker_volume.postgres_data.name
    container_path = "/var/lib/postgresql/data"
  }

  lifecycle {
    replace_triggered_by = [terraform_data.recreate]
  }
}
