# main.tf

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

resource "terraform_data" "recreate" {
  input = var.recreate_revision
}

resource "kind_cluster" "default" {
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
        for_each = var.expose_dashboard_public ? [1] : []
        content {
          container_port = var.dashboard_node_port
          host_port      = var.dashboard_host_port
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
  filename = "${path.root}/blitzinfra-kubeconfig"
  content = replace(
    kind_cluster.default.kubeconfig,
    "https://0.0.0.0:${var.api_server_port}",
    "https://${var.api_server_host}:${var.api_server_port}"
  )
}
