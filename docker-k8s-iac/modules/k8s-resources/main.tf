# main.tf

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

resource "terraform_data" "recreate" {
  input = var.recreate_revision
}

resource "kubernetes_namespace" "blitzpay" {
  metadata {
    name = var.kube_namespace
    labels = {
      name = var.kube_namespace
    }
  }

  lifecycle {
    replace_triggered_by = [terraform_data.recreate]
  }
}

resource "kubernetes_namespace" "backstage" {
  count = var.enable_backstage ? 1 : 0

  metadata {
    name = var.backstage_namespace
    labels = {
      name = var.backstage_namespace
    }
  }

  lifecycle {
    replace_triggered_by = [terraform_data.recreate]
  }
}

resource "helm_release" "backstage" {
  count = var.enable_backstage ? 1 : 0

  name             = "backstage"
  repository       = "https://backstage.github.io/charts"
  chart            = "backstage"
  version          = var.backstage_chart_version
  namespace        = var.backstage_namespace
  create_namespace = false
  timeout          = 900

  values = [
    yamlencode({
      backstage = {
        image = {
          tag        = var.backstage_image_tag
          pullPolicy = "IfNotPresent"
        }
        readinessProbe = {
          httpGet = {
            path   = "/.backstage/health/v1/readiness"
            port   = 7007
            scheme = "HTTPS"
          }
          initialDelaySeconds = 15
          periodSeconds       = 10
          timeoutSeconds      = 3
          failureThreshold    = 12
        }
        livenessProbe = {
          httpGet = {
            path   = "/.backstage/health/v1/liveness"
            port   = 7007
            scheme = "HTTPS"
          }
          initialDelaySeconds = 30
          periodSeconds       = 10
          timeoutSeconds      = 3
          failureThreshold    = 6
        }
        startupProbe = {
          httpGet = {
            path   = "/.backstage/health/v1/liveness"
            port   = 7007
            scheme = "HTTPS"
          }
          periodSeconds    = 10
          timeoutSeconds   = 3
          failureThreshold = 30
        }
        appConfig = {
          app = {
            title    = "Backstage"
            baseUrl  = var.backstage_base_url
            packages = "all"
            extensions = [
              {
                "nav-item:search" = false
              },
              {
                "nav-item:user-settings" = false
              },
              {
                "nav-item:catalog" = false
              },
              {
                "nav-item:scaffolder" = false
              },
              {
                "page:catalog" = {
                  config = {
                    path = "/"
                  }
                }
              }
            ]
          }
          organization = {
            name = "BlitzInfra"
          }
          auth = {
            environment = "development"
            experimentalExtraAllowedOrigins = [
              "https://localhost:7007",
              "http://localhost:7007",
              var.backstage_base_url
            ]
            providers = {
              guest = {
                dangerouslyAllowOutsideDevelopment = true
              }
            }
          }
          backend = {
            baseUrl = var.backstage_base_url
            https   = true
            cors = {
              origin = [
                "https://localhost:7007",
                "http://localhost:7007",
                var.backstage_base_url
              ]
              methods     = ["GET", "HEAD", "PATCH", "POST", "PUT", "DELETE"]
              credentials = true
            }
            database = {
              client = "pg"
              connection = {
                host     = var.postgres_host
                port     = var.postgres_port
                database = var.postgres_db_name
                user     = var.postgres_user
                password = var.postgres_password
              }
            }
          }
          proxy = {}
          techdocs = {
            builder = "local"
            generator = {
              runIn = "docker"
            }
            publisher = {
              type = "local"
            }
          }
          scaffolder = {}
          catalog = {
            import = {
              entityFilename        = "catalog-info.yaml"
              pullRequestBranchName = "backstage-integration"
            }
            rules = [
              {
                allow = ["Component", "System", "API", "Resource", "Location", "Template", "User", "Group"]
              }
            ]
            locations = [
              {
                type   = "file"
                target = "./examples/entities.yaml"
              },
              {
                type   = "file"
                target = "./examples/template/template.yaml"
                rules = [
                  {
                    allow = ["Template"]
                  }
                ]
              },
              {
                type   = "file"
                target = "./examples/org.yaml"
                rules = [
                  {
                    allow = ["User", "Group"]
                  }
                ]
              }
            ]
          }
          kubernetes = {
            serviceLocatorMethod = {
              type = "multiTenant"
            }
            clusterLocatorMethods = [
              {
                type     = "config"
                clusters = []
              }
            ]
          }
          permission = {
            enabled = true
          }
        }
      }
      service = {
        type = var.expose_backstage_public ? "NodePort" : "ClusterIP"
        nodePorts = {
          backend = var.expose_backstage_public ? var.backstage_node_port : null
        }
      }
      postgresql = {
        enabled = false
      }
    })
  ]

  postrender {
    binary_path = "${path.module}/../../scripts/backstage-postrender.sh"
  }

  depends_on = [kubernetes_namespace.backstage]

  lifecycle {
    replace_triggered_by = [terraform_data.recreate]
  }
}

resource "helm_release" "kubernetes_dashboard" {
  count = var.enable_k8s_dashboard ? 1 : 0

  name             = "kubernetes-dashboard"
  chart            = var.k8s_dashboard_chart_url
  namespace        = var.dashboard_namespace
  create_namespace = true
  values = [
    yamlencode({
      kong = {
        proxy = {
          type = var.expose_dashboard_public ? "NodePort" : "ClusterIP"
          http = {
            enabled = false
          }
          tls = var.expose_dashboard_public ? {
            nodePort = var.dashboard_node_port
          } : {}
        }
      }
    })
  ]

  depends_on = [kubernetes_namespace.blitzpay]

  lifecycle {
    replace_triggered_by = [terraform_data.recreate]
  }
}

resource "kubernetes_service_account" "dashboard_admin_user" {
  count = var.enable_k8s_dashboard && var.create_dashboard_admin_user ? 1 : 0

  metadata {
    name      = var.dashboard_admin_user_name
    namespace = var.dashboard_namespace
  }

  depends_on = [helm_release.kubernetes_dashboard]

  lifecycle {
    replace_triggered_by = [terraform_data.recreate]
  }
}

resource "kubernetes_cluster_role_binding" "dashboard_admin_user" {
  count = var.enable_k8s_dashboard && var.create_dashboard_admin_user ? 1 : 0

  metadata {
    name = var.dashboard_admin_user_name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    api_group = ""
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.dashboard_admin_user[0].metadata[0].name
    namespace = kubernetes_service_account.dashboard_admin_user[0].metadata[0].namespace
  }

  lifecycle {
    replace_triggered_by = [terraform_data.recreate]
  }
}
