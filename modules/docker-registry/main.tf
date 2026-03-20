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
    internal = 5000
    external = var.external_port
    ip       = var.bind_address
  }

  env = [
    "REGISTRY_STORAGE_DELETE_ENABLED=true"
  ]

  lifecycle {
    replace_triggered_by = [terraform_data.recreate]
  }
}
