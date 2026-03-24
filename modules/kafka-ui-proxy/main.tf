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

  command = [
    "tcp-listen:8080,fork,reuseaddr",
    format("tcp-connect:%s:%d", var.target_host, var.target_port),
  ]

  networks_advanced {
    name = var.network_name
  }

  ports {
    internal = 8080
    external = var.external_port
    ip       = var.bind_address
  }

  lifecycle {
    replace_triggered_by = [terraform_data.recreate]
  }
}
