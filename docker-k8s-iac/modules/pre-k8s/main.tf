# main.tf

terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

resource "docker_network" "registry_net" {
  name = "registry_net"
}

resource "docker_image" "registry" {
  name         = "registry:2"
  keep_locally = true
}

resource "docker_container" "registry" {
  image = docker_image.registry.image_id
  name  = "registry"
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
}

resource "docker_image" "registry_ui" {
  name         = "joxit/docker-registry-ui:2.5.7"
  keep_locally = true
}

resource "docker_container" "registry_ui" {
  image = docker_image.registry_ui.image_id
  name  = "registry-ui"
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
}
