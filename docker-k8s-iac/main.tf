# main.tf

module "pre-k8s" {
  source = "./modules/pre-k8s"

  registry_bind_address = var.registry_bind_address
  ui_bind_address       = var.ui_bind_address
  registry_title        = var.registry_title
  registry_ui_url       = "http://${var.api_server_host}:8081"
  image_registry        = "${var.api_server_host}:5000"
  postgres_bind_address = var.postgres_bind_address
  postgres_port         = var.postgres_port
  postgres_db_name      = var.postgres_db_name
  postgres_user         = var.postgres_user
  postgres_password     = var.postgres_password
  recreate_revision     = var.recreate_revision
}

module "kind-cluster" {
  source = "./modules/kind-cluster"

  cluster_name      = var.cluster_name
  kind_node_image   = var.kind_node_image
  worker_count      = var.worker_count
  ssh_context_host  = var.ssh_context_host
  api_server_host   = var.api_server_host
  api_server_port   = 6443
  recreate_revision = var.recreate_revision

  depends_on = [module.pre-k8s]
}

module "k8s-resources" {
  source = "./modules/k8s-resources"

  kube_namespace    = var.kube_namespace
  recreate_revision = var.recreate_revision

  depends_on = [module.kind-cluster]
}
