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

resource "docker_network" "this" {
  count = var.create ? 1 : 0
  name  = var.name

  lifecycle {
    replace_triggered_by = [terraform_data.recreate]
  }
}

data "docker_network" "existing" {
  count = var.create ? 0 : 1
  name  = var.name
}
