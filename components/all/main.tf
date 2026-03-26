locals {
  registry_network_name = var.registry.network_name
  backstage_base_url    = try(trimspace(var.backstage.base_url), "") != "" ? var.backstage.base_url : "https://${var.api_server_host}:${var.backstage.host_port}"
  kind_cluster_name     = try(var.kubernetes.cluster_name, "blitzinfra")
  kind_cluster_endpoint = "https://${var.api_server_host}:${var.kubernetes.api_server_port}"
  postgres_access_host  = try(trimspace(var.postgres.access_host), "") != "" ? var.postgres.access_host : module.postgres.backstage_host

  keycloak_kind_port_mapping = var.keycloak_port_mapping != null ? var.keycloak_port_mapping : (
    var.keycloak.enabled && var.keycloak.expose_public ? {
      node_port = var.keycloak.node_port
      host_port = var.keycloak.host_port
    } : null
  )

  kafka_dashboard_public_url = (
    var.kafka.enabled && var.kafka.expose_dashboard_public
    ? "http://${var.api_server_host}:${var.kafka.dashboard_host_port}"
    : null
  )
  keycloak_public_url = var.keycloak.enabled && var.keycloak.expose_public ? "http://${var.api_server_host}:${var.keycloak.host_port}/" : null
  grafana_public_url  = var.observability.enabled && var.observability.expose_public ? "http://${var.api_server_host}:${var.observability.grafana_host_port}" : null
  prometheus_public_url = (
    var.observability.enabled && var.observability.expose_public && try(var.observability.prometheus.enabled, true)
    ? "http://${var.api_server_host}:${var.observability.prometheus_host_port}"
    : null
  )

  dependencytrack_api_url = (
    var.dependencytrack.enabled && var.dependencytrack.expose_public
    ? "http://${var.api_server_host}:${var.dependencytrack.api.host_port}"
    : null
  )
  dependencytrack_frontend_url = (
    var.dependencytrack.enabled && var.dependencytrack.expose_public
    ? "http://${var.api_server_host}:${var.dependencytrack.frontend.host_port}"
    : null
  )
}

module "docker_network" {
  source = "../../modules/docker-network"

  name              = local.registry_network_name
  create            = var.registry.create_network
  recreate_revision = var.recreate_revision
}

module "postgres" {
  source = "../../modules/postgres"

  create            = var.postgres.create
  network_name      = module.docker_network.name
  bind_address      = var.postgres.bind_address
  port              = var.postgres.port
  db_name           = var.postgres.db_name
  user              = var.postgres.user
  password          = var.postgres.password
  volume_name       = var.postgres.volume_name
  recreate_revision = var.recreate_revision
}

module "docker_registry" {
  source = "../../modules/docker-registry"

  create            = var.registry.create_registry
  network_name      = module.docker_network.name
  bind_address      = var.registry.bind_address
  external_port     = var.registry.port
  recreate_revision = var.recreate_revision
}

module "docker_registry_ui" {
  source = "../../modules/docker-registry-ui"

  create                = var.registry.create_ui
  network_name          = module.docker_network.name
  bind_address          = var.registry.ui_bind
  external_port         = var.registry.ui_port
  registry_title        = var.registry.title
  registry_internal_url = "http://${module.docker_registry.container_name}:5000"
  registry_external_url = "http://${var.api_server_host}:${var.registry.ui_port}"
  image_registry        = "${var.api_server_host}:${var.registry.port}"
  recreate_revision     = var.recreate_revision
}

module "kind_cluster" {
  count  = var.kubernetes.create_cluster ? 1 : 0
  source = "../../modules/kind-cluster"

  cluster_name     = var.kubernetes.cluster_name
  api_server_port  = var.kubernetes.api_server_port
  api_server_host  = var.api_server_host
  ssh_context_host = var.ssh_context_host
  worker_count     = var.kubernetes.worker_count
  kind_node_image  = var.kubernetes.kind_node_image
  kubeconfig_path  = try(var.kubernetes.kubeconfig_path, null)
  backstage_port_mapping = var.backstage.enabled && var.backstage.expose_public ? {
    node_port = var.backstage.node_port
    host_port = var.backstage.host_port
  } : null
  headlamp_port_mapping = var.headlamp.enabled && var.headlamp.expose_public ? {
    node_port = var.headlamp.node_port
    host_port = var.headlamp.host_port
  } : null
  keycloak_port_mapping = local.keycloak_kind_port_mapping
  grafana_port_mapping = var.observability.enabled && var.observability.expose_public ? {
    node_port = var.observability.grafana_node_port
    host_port = var.observability.grafana_host_port
  } : null
  prometheus_port_mapping = (
    var.observability.enabled && var.observability.expose_public && try(var.observability.prometheus.enabled, true)
    ? {
      node_port = var.observability.prometheus_node_port
      host_port = var.observability.prometheus_host_port
    }
    : null
  )
  dependencytrack_api_port_mapping = var.dependencytrack.enabled && var.dependencytrack.expose_public ? {
    node_port = var.dependencytrack.api.node_port
    host_port = var.dependencytrack.api.host_port
  } : null
  dependencytrack_frontend_port_mapping = var.dependencytrack.enabled && var.dependencytrack.expose_public ? {
    node_port = var.dependencytrack.frontend.node_port
    host_port = var.dependencytrack.frontend.host_port
  } : null
  extra_port_mappings = try(var.kubernetes.extra_port_mappings, [])
  recreate_revision   = trimspace(try(var.kubernetes.recreate_revision, "")) != "" ? var.kubernetes.recreate_revision : var.recreate_revision

  depends_on = [module.postgres]
}

resource "terraform_data" "kind_cluster_ready" {
  input = var.kubernetes.create_cluster ? "create" : "reuse"

  depends_on = [module.kind_cluster]
}

module "bootstrap_namespace" {
  count  = trimspace(var.bootstrap_namespace) != "" ? 1 : 0
  source = "../../modules/k8s-namespace"

  name = var.bootstrap_namespace

  depends_on = [terraform_data.kind_cluster_ready]
}

module "backstage_namespace" {
  count  = var.backstage.enabled ? 1 : 0
  source = "../../modules/k8s-namespace"

  name = var.backstage.namespace

  depends_on = [terraform_data.kind_cluster_ready]
}

module "backstage" {
  count  = var.backstage.enabled ? 1 : 0
  source = "../../modules/backstage"

  namespace                  = module.backstage_namespace[0].name
  chart_version              = var.backstage.chart_version
  image_repository           = var.backstage.image_repository
  image_tag                  = var.backstage.image_tag
  base_url                   = local.backstage_base_url
  backend_auth_key           = var.backstage_backend_auth_key
  auth_provider              = var.backstage_auth_provider
  keycloak_base_url          = var.backstage_keycloak_base_url
  keycloak_realm             = var.backstage_keycloak_realm
  keycloak_client_id         = var.backstage_keycloak_client_id
  keycloak_client_secret     = var.backstage_keycloak_client_secret
  oauth2_proxy_cookie_secret = var.backstage_oauth2_proxy_cookie_secret
  public_node_port           = var.backstage.expose_public && var.backstage_auth_provider == "keycloak_proxy" ? var.backstage.node_port : null
  service_type               = var.backstage.expose_public && var.backstage_auth_provider != "keycloak_proxy" ? "NodePort" : "ClusterIP"
  node_port                  = var.backstage.expose_public && var.backstage_auth_provider != "keycloak_proxy" ? var.backstage.node_port : null
  postgres_host              = local.postgres_access_host
  postgres_port              = module.postgres.port
  postgres_db_name           = module.postgres.db_name
  postgres_user              = module.postgres.user
  postgres_password          = var.postgres.password
  recreate_revision          = trimspace(try(var.backstage.recreate_revision, "")) != "" ? var.backstage.recreate_revision : var.recreate_revision

  depends_on = [module.backstage_namespace]
}

module "headlamp_namespace" {
  count  = var.headlamp.enabled ? 1 : 0
  source = "../../modules/k8s-namespace"

  name = var.headlamp.namespace

  depends_on = [terraform_data.kind_cluster_ready]
}

module "headlamp" {
  count  = var.headlamp.enabled ? 1 : 0
  source = "../../modules/headlamp"

  namespace                   = module.headlamp_namespace[0].name
  chart_repository            = var.headlamp.chart_repository
  chart_name                  = var.headlamp.chart_name
  chart_version               = var.headlamp.chart_version
  service_type                = var.headlamp.expose_public ? "NodePort" : "ClusterIP"
  node_port                   = var.headlamp.expose_public ? var.headlamp.node_port : null
  create_service_account      = var.headlamp.create_service_account
  service_account_name        = var.headlamp.service_account_name
  create_cluster_role_binding = var.headlamp.create_cluster_role_binding
  cluster_role_name           = var.headlamp.cluster_role_name
  recreate_revision           = trimspace(try(var.headlamp.recreate_revision, "")) != "" ? var.headlamp.recreate_revision : var.recreate_revision

  depends_on = [module.headlamp_namespace]
}

module "kafka_namespace" {
  count  = var.kafka.enabled ? 1 : 0
  source = "../../modules/k8s-namespace"

  name = var.kafka.namespace

  depends_on = [terraform_data.kind_cluster_ready]
}

resource "terraform_data" "kafka_public_access" {
  input = {
    kafka     = var.kafka.expose_public
    dashboard = var.kafka.expose_dashboard_public
  }

  lifecycle {
    precondition {
      condition     = (!var.kafka.expose_public && !var.kafka.expose_dashboard_public) || trimspace(var.api_server_host) != ""
      error_message = "Set api_server_host when kafka.expose_public or kafka.expose_dashboard_public is true so public Kafka endpoints can be surfaced."
    }
  }
}

module "kafka" {
  count  = var.kafka.enabled ? 1 : 0
  source = "../../modules/kafka"

  namespace         = module.kafka_namespace[0].name
  api_server_host   = var.api_server_host
  kafka             = var.kafka
  recreate_revision = trimspace(try(var.kafka.recreate_revision, "")) != "" ? var.kafka.recreate_revision : var.recreate_revision

  depends_on = [
    module.kafka_namespace,
    terraform_data.kafka_public_access,
  ]
}

module "kafka_proxy" {
  count  = var.kafka.enabled && var.kafka.expose_public && var.kafka.create_proxy ? 1 : 0
  source = "../../modules/kafka-ui-proxy"

  create            = var.kafka.create_proxy
  target_host       = "${local.kind_cluster_name}-control-plane"
  target_port       = var.kafka.external_node_port
  external_port     = var.kafka.external_host_port
  container_name    = "${local.kind_cluster_name}-kafka-proxy"
  recreate_revision = trimspace(try(var.kafka.recreate_revision, "")) != "" ? var.kafka.recreate_revision : var.recreate_revision
}

module "kafka_ui_proxy" {
  count  = var.kafka.enabled && var.kafka.expose_dashboard_public && var.kafka.create_dashboard_proxy ? 1 : 0
  source = "../../modules/kafka-ui-proxy"

  create            = var.kafka.create_dashboard_proxy
  target_host       = "${local.kind_cluster_name}-control-plane"
  target_port       = var.kafka.dashboard_node_port
  external_port     = var.kafka.dashboard_host_port
  container_name    = "${local.kind_cluster_name}-kafka-ui-proxy"
  recreate_revision = trimspace(try(var.kafka.recreate_revision, "")) != "" ? var.kafka.recreate_revision : var.recreate_revision
}

module "keycloak_namespace" {
  count  = var.keycloak.enabled ? 1 : 0
  source = "../../modules/k8s-namespace"

  name = var.keycloak.namespace

  depends_on = [terraform_data.kind_cluster_ready]
}

module "keycloak" {
  count  = var.keycloak.enabled ? 1 : 0
  source = "../../modules/keycloak"

  name              = var.keycloak.name
  namespace         = module.keycloak_namespace[0].name
  image             = "${var.keycloak.image_repository}:${var.keycloak.image_tag}"
  replicas          = var.keycloak.replicas
  service_type      = var.keycloak.expose_public ? "NodePort" : "ClusterIP"
  node_port         = var.keycloak.expose_public ? var.keycloak.node_port : null
  admin_username    = var.keycloak.admin_username
  admin_password    = var.keycloak.admin_password
  database_host     = local.postgres_access_host
  database_port     = module.postgres.port
  database_name     = module.postgres.db_name
  database_user     = module.postgres.user
  database_password = var.postgres.password
  recreate_revision = trimspace(try(var.keycloak.recreate_revision, "")) != "" ? var.keycloak.recreate_revision : var.recreate_revision

  depends_on = [module.keycloak_namespace]
}

module "observability_namespace" {
  count  = var.observability.enabled ? 1 : 0
  source = "../../modules/k8s-namespace"

  name = var.observability.namespace

  depends_on = [terraform_data.kind_cluster_ready]
}

module "observability" {
  count  = var.observability.enabled ? 1 : 0
  source = "../../modules/observability"

  namespace = module.observability_namespace[0].name
  grafana = merge(var.observability.grafana, {
    service_type = var.observability.expose_public ? "NodePort" : "ClusterIP"
    node_port    = var.observability.expose_public ? var.observability.grafana_node_port : null
  })
  loki  = var.observability.loki
  tempo = var.observability.tempo
  prometheus = merge(var.observability.prometheus, {
    service_type = var.observability.expose_public ? "NodePort" : "ClusterIP"
    node_port    = var.observability.expose_public ? var.observability.prometheus_node_port : null
  })
  recreate_revision = var.recreate_revision

  depends_on = [module.observability_namespace]
}

module "dependencytrack_namespace" {
  count  = var.dependencytrack.enabled ? 1 : 0
  source = "../../modules/k8s-namespace"

  name = var.dependencytrack.namespace

  depends_on = [terraform_data.kind_cluster_ready]
}

module "dependencytrack" {
  count  = var.dependencytrack.enabled ? 1 : 0
  source = "../../modules/dependencytrack"

  namespace             = module.dependencytrack_namespace[0].name
  api_server_host       = var.api_server_host
  api_image             = "${var.dependencytrack.api.image_repository}:${var.dependencytrack.api.image_tag}"
  api_service_type      = var.dependencytrack.expose_public ? "NodePort" : "ClusterIP"
  api_node_port         = var.dependencytrack.expose_public ? var.dependencytrack.api.node_port : null
  api_host_port         = var.dependencytrack.api.host_port
  api_memory_request    = var.dependencytrack.api.memory_request
  api_memory_limit      = var.dependencytrack.api.memory_limit
  api_cpu_request       = var.dependencytrack.api.cpu_request
  frontend_image        = "${var.dependencytrack.frontend.image_repository}:${var.dependencytrack.frontend.image_tag}"
  frontend_service_type = var.dependencytrack.expose_public ? "NodePort" : "ClusterIP"
  frontend_node_port    = var.dependencytrack.expose_public ? var.dependencytrack.frontend.node_port : null
  frontend_host_port    = var.dependencytrack.frontend.host_port
  database_host         = local.postgres_access_host
  database_port         = module.postgres.port
  database_name         = var.dependencytrack.db_name
  database_username     = var.dependencytrack.db_username
  database_password     = coalesce(var.dependencytrack_db_password, var.postgres.password)
  recreate_revision     = trimspace(try(var.dependencytrack.recreate_revision, "")) != "" ? var.dependencytrack.recreate_revision : var.recreate_revision

  depends_on = [module.dependencytrack_namespace]
}
