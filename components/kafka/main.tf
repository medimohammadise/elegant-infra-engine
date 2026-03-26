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
      condition     = (!var.kafka.expose_public && !var.kafka.expose_dashboard_public) || var.api_server_host != null
      error_message = "Set api_server_host when kafka.expose_public or kafka.expose_dashboard_public is true so public Kafka endpoints can be surfaced."
    }
  }
}

module "kafka" {
  source = "../../modules/kafka"

  namespace         = module.kafka_namespace.name
  api_server_host   = var.api_server_host
  kafka             = var.kafka
  recreate_revision = var.recreate_revision

  depends_on = [
    module.kafka_namespace,
    terraform_data.public_access,
  ]
}

module "kafka_proxy" {
  count  = var.kafka.expose_public && var.kafka.create_proxy ? 1 : 0
  source = "../../modules/kafka-ui-proxy"

  create            = var.kafka.create_proxy
  target_host       = "${var.cluster_name}-control-plane"
  target_port       = var.kafka.external_node_port
  external_port     = var.kafka.external_host_port
  container_name    = "${var.cluster_name}-kafka-proxy"
  recreate_revision = var.recreate_revision
}

module "kafka_ui_proxy" {
  count  = var.kafka.expose_dashboard_public && var.kafka.create_dashboard_proxy ? 1 : 0
  source = "../../modules/kafka-ui-proxy"

  create            = var.kafka.create_dashboard_proxy
  target_host       = "${var.cluster_name}-control-plane"
  target_port       = var.kafka.dashboard_node_port
  external_port     = var.kafka.dashboard_host_port
  container_name    = "${var.cluster_name}-kafka-ui-proxy"
  recreate_revision = var.recreate_revision
}
