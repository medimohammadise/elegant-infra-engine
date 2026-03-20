terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

resource "terraform_data" "recreate" {
  input = var.recreate_revision
}

resource "helm_release" "this" {
  name             = var.release_name
  repository       = "https://backstage.github.io/charts"
  chart            = "backstage"
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = false
  timeout          = 900

  values = [
    yamlencode({
      backstage = {
        image = {
          tag        = var.image_tag
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
            title    = var.app_title
            baseUrl  = var.base_url
            packages = "all"
            extensions = [
              { "nav-item:search" = false },
              { "nav-item:user-settings" = false },
              { "nav-item:catalog" = false },
              { "nav-item:scaffolder" = false },
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
            name = var.organization_name
          }
          auth = {
            environment = "development"
            experimentalExtraAllowedOrigins = [
              "https://localhost:7007",
              "http://localhost:7007",
              var.base_url
            ]
            providers = {
              guest = {
                dangerouslyAllowOutsideDevelopment = true
              }
            }
          }
          backend = {
            baseUrl = var.base_url
            https   = true
            cors = {
              origin = [
                "https://localhost:7007",
                "http://localhost:7007",
                var.base_url
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
        type = var.service_type
        nodePorts = {
          backend = var.service_type == "NodePort" ? var.node_port : null
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

  lifecycle {
    replace_triggered_by = [terraform_data.recreate]
  }
}
