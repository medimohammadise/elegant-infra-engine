terraform {
  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "~> 0.5.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

locals {
  kubeconfig_path = var.kubeconfig_path != null ? var.kubeconfig_path : "${path.root}/${var.cluster_name}-kubeconfig"
}

resource "terraform_data" "recreate" {
  input = var.recreate_revision
}

resource "kind_cluster" "this" {
  name           = var.cluster_name
  node_image     = var.kind_node_image
  wait_for_ready = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    networking {
      api_server_address = "0.0.0.0"
      api_server_port    = var.api_server_port
    }

    node {
      role = "control-plane"
      kubeadm_config_patches = [
        <<-EOF
        kind: ClusterConfiguration
        apiServer:
          certSANs:
          - "${var.api_server_host}"
          - "${var.ssh_context_host}"
          - "localhost"
        EOF
      ]

      dynamic "extra_port_mappings" {
        for_each = var.backstage_port_mapping != null ? [var.backstage_port_mapping] : []
        content {
          container_port = extra_port_mappings.value.node_port
          host_port      = extra_port_mappings.value.host_port
          listen_address = "0.0.0.0"
          protocol       = "TCP"
        }
      }

      dynamic "extra_port_mappings" {
        for_each = var.dashboard_port_mapping != null ? [var.dashboard_port_mapping] : []
        content {
          container_port = extra_port_mappings.value.node_port
          host_port      = extra_port_mappings.value.host_port
          listen_address = "0.0.0.0"
          protocol       = "TCP"
        }
      }

      dynamic "extra_port_mappings" {
        for_each = var.keycloak_port_mapping != null ? [var.keycloak_port_mapping] : []
        content {
          container_port = extra_port_mappings.value.node_port
          host_port      = extra_port_mappings.value.host_port
          listen_address = "0.0.0.0"
          protocol       = "TCP"
        }
      }
    }

    dynamic "node" {
      for_each = range(var.worker_count)
      content {
        role = "worker"
      }
    }
  }

  lifecycle {
    replace_triggered_by = [terraform_data.recreate]
  }
}

resource "local_sensitive_file" "kubeconfig" {
  filename = local.kubeconfig_path
  content = replace(
    kind_cluster.this.kubeconfig,
    "https://0.0.0.0:${var.api_server_port}",
    "https://${var.api_server_host}:${var.api_server_port}"
  )
}
