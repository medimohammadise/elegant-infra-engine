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

data "external" "network_exists" {
  program = ["python3", "${path.module}/../../scripts/docker-network-check.py"]

  query = {
    name = var.name
  }
}

resource "docker_network" "this" {
  count = (var.create && try(data.external.network_exists.result.exists, "false") == "false") ? 1 : 0
  name  = var.name

  lifecycle {
    replace_triggered_by = [terraform_data.recreate]
  }
}
