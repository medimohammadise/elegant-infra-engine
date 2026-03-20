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
    internal = 80
    external = var.external_port
    ip       = var.bind_address
  }

  env = [
    "SINGLE_REGISTRY=true",
    "REGISTRY_TITLE=${var.registry_title}",
    "REGISTRY_URL=${var.registry_external_url}",
    "NGINX_PROXY_PASS_URL=${var.registry_internal_url}",
    "NGINX_RESOLVER=127.0.0.11",
    "PULL_URL=${var.image_registry}"
  ]

  lifecycle {
    replace_triggered_by = [terraform_data.recreate]
  }
}
