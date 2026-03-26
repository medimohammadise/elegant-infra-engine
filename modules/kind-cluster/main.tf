terraform {
  required_providers {
    external = {
      source  = "hashicorp/external"
      version = "~> 2.0"
    }
  }
}

locals {
  kubeconfig_path = var.kubeconfig_path != null ? var.kubeconfig_path : "${path.root}/${var.cluster_name}-kubeconfig"

  extra_port_mappings = concat(
    [
      for mapping in [
        var.backstage_port_mapping,
        var.headlamp_port_mapping,
        var.kafka_dashboard_port_mapping,
        var.keycloak_port_mapping,
        var.dependencytrack_api_port_mapping,
        var.dependencytrack_frontend_port_mapping,
        var.grafana_port_mapping,
        var.prometheus_port_mapping,
      ] : mapping if mapping != null
    ],
    [
      for mapping in var.extra_port_mappings : {
        node_port = mapping.node_port
        host_port = mapping.host_port
      }
    ]
  )

  control_plane_node = merge(
    {
      role = "control-plane"
      kubeadmConfigPatches = [
        <<-EOT
        kind: ClusterConfiguration
        apiServer:
          certSANs:
            - "${var.api_server_host}"
            - "${var.ssh_context_host}"
            - "localhost"
        EOT
      ]
    },
    length(local.extra_port_mappings) > 0 ? {
      extraPortMappings = [
        for mapping in local.extra_port_mappings : {
          containerPort = mapping.node_port
          hostPort      = mapping.host_port
          listenAddress = "0.0.0.0"
          protocol      = "TCP"
        }
      ]
    } : {}
  )

  kind_config = yamlencode({
    kind       = "Cluster"
    apiVersion = "kind.x-k8s.io/v1alpha4"
    networking = {
      apiServerAddress = "0.0.0.0"
      apiServerPort    = var.api_server_port
    }
    nodes = concat(
      [local.control_plane_node],
      [for _ in range(var.worker_count) : { role = "worker" }]
    )
  })
}

data "external" "cluster_status" {
  program = [
    "bash", "-c",
    "DOCKER_HOST=ssh://${var.ssh_context_host} '${path.module}/../../scripts/kind-cluster-manager.sh' status",
  ]

  query = {
    cluster_name = var.cluster_name
  }
}

resource "terraform_data" "cluster" {
  triggers_replace = {
    cluster_name      = var.cluster_name
    ssh_context_host  = var.ssh_context_host
    kind_node_image   = var.kind_node_image
    kind_config_sha   = sha256(local.kind_config)
    recreate_revision = var.recreate_revision
    cluster_exists    = try(data.external.cluster_status.result.exists, "false")
  }

  provisioner "local-exec" {
    command = "${path.module}/../../scripts/kind-cluster-manager.sh create"

    environment = {
      DOCKER_HOST                = "ssh://${var.ssh_context_host}"
      KIND_CLUSTER_NAME          = var.cluster_name
      KIND_NODE_IMAGE            = var.kind_node_image
      KIND_CLUSTER_CONFIG_BASE64 = base64encode(local.kind_config)
      KIND_KUBECONFIG_PATH       = local.kubeconfig_path
      KIND_API_SERVER_HOST       = var.api_server_host
      KIND_API_SERVER_PORT       = tostring(var.api_server_port)
    }
  }

  provisioner "local-exec" {
    when    = destroy
    command = "${path.module}/../../scripts/kind-cluster-manager.sh delete"

    environment = {
      DOCKER_HOST       = "ssh://${self.triggers_replace.ssh_context_host}"
      KIND_CLUSTER_NAME = self.triggers_replace.cluster_name
    }
  }
}
