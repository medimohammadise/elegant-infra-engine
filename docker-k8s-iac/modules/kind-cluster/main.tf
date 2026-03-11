# main.tf

terraform {
  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "~> 0.5.0"
    }
  }
}

resource "kind_cluster" "default" {
  name           = var.cluster_name
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
    }

    dynamic "node" {
      for_each = range(var.worker_count)
      content {
        role = "worker"
      }
    }
  }
}
