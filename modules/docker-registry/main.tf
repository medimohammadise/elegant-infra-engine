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

data "external" "container_exists" {
  count = var.create ? 1 : 0

  program = ["python3", "${path.module}/../../scripts/docker-container-check.py"]

  query = {
    name = var.container_name
  }
}

resource "docker_image" "this" {
  count        = var.create ? 1 : 0
  name         = var.image_name
  keep_locally = true

  lifecycle {
    replace_triggered_by = [terraform_data.recreate]
  }
}

resource "docker_container" "this" {
  count   = var.create && try(data.external.container_exists[0].result.exists, "false") == "false" ? 1 : 0
  image   = docker_image.this[0].image_id
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
