data "terraform_remote_state" "infra" {
  backend = "local"
  config = {
    path = "${path.module}/../infra/terraform.tfstate"
  }
}

locals {
  infra            = data.terraform_remote_state.infra.outputs
  cluster_name     = try(local.infra.cluster_name, "") != "" ? local.infra.cluster_name : var.cluster_name
  api_server_host  = try(local.infra.api_server_host, null) != null ? local.infra.api_server_host : var.api_server_host
  kafka_recreate_revision = trimspace(try(var.kafka.recreate_revision, "")) != "" ? var.kafka.recreate_revision : var.recreate_revision
  docker_network_name = try(local.infra.docker_network_name, "kind")
}

module "kafka_namespace" {
  source = "../../modules/k8s-namespace"

  name = var.kafka.namespace
}

resource "terraform_data" "public_access" {
  input = {
    kafka     = var.kafka.expose_public
    dashboard = var.kafka.expose_dashboard_public
  }

  lifecycle {
    precondition {
      condition     = (!var.kafka.expose_public && !var.kafka.expose_dashboard_public) || try(local.api_server_host, null) != null
      error_message = "Apply the infra component first so api_server_host and the node-port mappings are available via remote state before exposing Kafka endpoints."
    }
  }
}

module "kafka" {
  source = "../../modules/kafka"

  namespace         = module.kafka_namespace.name
  api_server_host   = local.api_server_host
  kafka             = var.kafka
  recreate_revision = var.recreate_revision

  depends_on = [
    module.kafka_namespace,
    terraform_data.public_access,
  ]
}

resource "terraform_data" "kafka_proxy_recreate" {
  input = local.kafka_recreate_revision
}

resource "docker_image" "kafka_proxy" {
  count        = var.kafka.expose_public && var.kafka.create_proxy ? 1 : 0
  name         = "alpine/socat:1.8.0.0"
  keep_locally = true

  lifecycle {
    replace_triggered_by = [terraform_data.kafka_proxy_recreate]
  }
}

resource "docker_container" "kafka_proxy" {
  count   = var.kafka.expose_public && var.kafka.create_proxy ? 1 : 0
  image   = docker_image.kafka_proxy[0].image_id
  name    = "${local.cluster_name}-kafka-proxy"
  restart = "unless-stopped"

  command = [
    "tcp-listen:8080,fork,reuseaddr",
    format("tcp-connect:%s:%d", "${local.cluster_name}-control-plane", var.kafka.external_node_port),
  ]

  networks_advanced {
    name = local.docker_network_name
  }

  ports {
    internal = 8080
    external = var.kafka.external_host_port
    ip       = "0.0.0.0"
  }

  lifecycle {
    replace_triggered_by = [terraform_data.kafka_proxy_recreate]
  }

  depends_on = [module.kafka]
}

resource "docker_image" "kafka_ui_proxy" {
  count        = var.kafka.expose_dashboard_public && var.kafka.create_dashboard_proxy ? 1 : 0
  name         = "alpine/socat:1.8.0.0"
  keep_locally = true

  lifecycle {
    replace_triggered_by = [terraform_data.kafka_proxy_recreate]
  }
}

resource "docker_container" "kafka_ui_proxy" {
  count   = var.kafka.expose_dashboard_public && var.kafka.create_dashboard_proxy ? 1 : 0
  image   = docker_image.kafka_ui_proxy[0].image_id
  name    = "${local.cluster_name}-kafka-ui-proxy"
  restart = "unless-stopped"

  command = [
    "tcp-listen:8080,fork,reuseaddr",
    format("tcp-connect:%s:%d", "${local.cluster_name}-control-plane", var.kafka.dashboard_node_port),
  ]

  networks_advanced {
    name = local.docker_network_name
  }

  ports {
    internal = 8080
    external = var.kafka.dashboard_host_port
    ip       = "0.0.0.0"
  }

  lifecycle {
    replace_triggered_by = [terraform_data.kafka_proxy_recreate]
  }

  depends_on = [module.kafka]
}
