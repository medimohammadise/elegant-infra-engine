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

resource "docker_volume" "this" {
  name = var.volume_name

  lifecycle {
    replace_triggered_by = [terraform_data.recreate]
  }
}

resource "docker_image" "this" {
  name         = var.image_name
  keep_locally = true

  lifecycle {
    replace_triggered_by = [terraform_data.recreate]
  }
}

resource "docker_container" "this" {
  image   = docker_image.this.image_id
  name    = var.container_name
  restart = "unless-stopped"

  networks_advanced {
    name = var.network_name
  }

  ports {
    internal = 5432
    external = var.port
    ip       = var.bind_address
  }

  env = [
    "POSTGRES_DB=${var.db_name}",
    "POSTGRES_USER=${var.user}",
    "POSTGRES_PASSWORD=${var.password}"
  ]

  volumes {
    volume_name    = docker_volume.this.name
    container_path = "/var/lib/postgresql/data"
  }

  lifecycle {
    replace_triggered_by = [terraform_data.recreate]
  }
}
