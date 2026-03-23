terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

resource "terraform_data" "recreate" {
  input = var.recreate_revision
}

locals {
  keycloak_proxy_enabled = var.auth_provider == "keycloak_proxy"
  base_url_is_https      = startswith(lower(var.base_url), "https://")
  base_url_no_scheme     = replace(replace(var.base_url, "https://", ""), "http://", "")
  base_url_host_port     = split("/", local.base_url_no_scheme)[0]
  base_url_host          = split(":", local.base_url_host_port)[0]
  probe_scheme           = "HTTP"

  auth_providers = merge(
    {},
    local.keycloak_proxy_enabled ? {
      proxy = {
        development = {
          signIn = {
            resolvers = [
              {
                resolver = "dangerouslyAllowSignInWithoutUserInCatalog"
              }
            ]
          }
        }
      }
    } : {},
  )

  backend_auth = merge(
    {},
    var.auth_provider == "none" || local.keycloak_proxy_enabled ? {
      dangerouslyDisableDefaultAuthPolicy = true
    } : {},
  )

  permission_enabled = false
}

resource "tls_private_key" "oauth2_proxy" {
  count = local.keycloak_proxy_enabled && local.base_url_is_https ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "oauth2_proxy" {
  count = local.keycloak_proxy_enabled && local.base_url_is_https ? 1 : 0

  private_key_pem       = tls_private_key.oauth2_proxy[0].private_key_pem
  validity_period_hours = 24 * 365

  subject {
    common_name = local.base_url_host
  }

  dns_names = [local.base_url_host]

  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "server_auth",
  ]
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
          repository = var.image_repository
          tag        = var.image_tag
          pullPolicy = "IfNotPresent"
        }
        readinessProbe = {
          httpGet = {
            path   = "/.backstage/health/v1/readiness"
            port   = 7007
            scheme = local.probe_scheme
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
            scheme = local.probe_scheme
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
            scheme = local.probe_scheme
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
            providers = local.auth_providers
          }
          backend = {
            baseUrl = var.base_url
            auth    = local.backend_auth
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
            enabled = local.permission_enabled
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

resource "terraform_data" "keycloak_proxy_validation" {
  input = local.keycloak_proxy_enabled ? "keycloak_proxy" : "disabled"

  lifecycle {
    precondition {
      condition     = !local.keycloak_proxy_enabled || local.base_url_is_https
      error_message = "keycloak_proxy mode requires base_url to start with https://."
    }

    precondition {
      condition = !local.keycloak_proxy_enabled || (
        try(trimspace(var.keycloak_base_url), "") != "" &&
        try(trimspace(var.keycloak_realm), "") != "" &&
        try(trimspace(var.keycloak_client_id), "") != "" &&
        try(trimspace(var.keycloak_client_secret), "") != "" &&
        try(trimspace(var.oauth2_proxy_cookie_secret), "") != "" &&
        var.public_node_port != null
      )
      error_message = "keycloak_proxy mode requires keycloak_base_url, keycloak_realm, keycloak_client_id, keycloak_client_secret, oauth2_proxy_cookie_secret, and public_node_port."
    }
  }
}

resource "kubernetes_secret" "oauth2_proxy_credentials" {
  count = local.keycloak_proxy_enabled ? 1 : 0

  metadata {
    name      = "${var.release_name}-oauth2-proxy"
    namespace = var.namespace
  }

  data = {
    OAUTH2_PROXY_CLIENT_SECRET = var.keycloak_client_secret
    OAUTH2_PROXY_COOKIE_SECRET = var.oauth2_proxy_cookie_secret
  }

  type = "Opaque"
}

resource "kubernetes_secret" "oauth2_proxy_tls" {
  count = local.keycloak_proxy_enabled && local.base_url_is_https ? 1 : 0

  metadata {
    name      = "${var.release_name}-oauth2-proxy-tls"
    namespace = var.namespace
  }

  data = {
    "tls.crt" = tls_self_signed_cert.oauth2_proxy[0].cert_pem
    "tls.key" = tls_private_key.oauth2_proxy[0].private_key_pem
  }

  type = "kubernetes.io/tls"
}

resource "kubernetes_deployment" "oauth2_proxy" {
  count = local.keycloak_proxy_enabled ? 1 : 0

  metadata {
    name      = "${var.release_name}-oauth2-proxy"
    namespace = var.namespace
    labels = {
      app = "${var.release_name}-oauth2-proxy"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "${var.release_name}-oauth2-proxy"
      }
    }

    template {
      metadata {
        labels = {
          app = "${var.release_name}-oauth2-proxy"
        }
      }

      spec {
        container {
          name  = "oauth2-proxy"
          image = "quay.io/oauth2-proxy/oauth2-proxy:v7.12.0"

          args = concat(
            [
              "--http-address=0.0.0.0:4180",
              "--provider=oidc",
              "--oidc-issuer-url=${trim(var.keycloak_base_url, "/")}/realms/${var.keycloak_realm}",
              "--skip-oidc-discovery=true",
              "--login-url=${trim(var.keycloak_base_url, "/")}/realms/${var.keycloak_realm}/protocol/openid-connect/auth",
              "--redeem-url=http://keycloak.keycloak.svc.cluster.local/realms/${var.keycloak_realm}/protocol/openid-connect/token",
              "--oidc-jwks-url=http://keycloak.keycloak.svc.cluster.local/realms/${var.keycloak_realm}/protocol/openid-connect/certs",
              "--client-id=${var.keycloak_client_id}",
              "--upstream=http://${var.release_name}:7007",
              "--redirect-url=${trim(var.base_url, "/")}/oauth2/callback",
              "--cookie-secure=${local.base_url_is_https ? "true" : "false"}",
              "--cookie-samesite=lax",
              "--email-domain=*",
              "--reverse-proxy=true",
              "--set-authorization-header=false",
              "--pass-authorization-header=false",
              "--pass-user-headers=true",
              "--skip-provider-button=true",
            ],
            local.base_url_is_https ? [
              "--https-address=0.0.0.0:4443",
              "--tls-cert-file=/etc/oauth2-proxy/tls/tls.crt",
              "--tls-key-file=/etc/oauth2-proxy/tls/tls.key",
            ] : [],
          )

          env {
            name = "OAUTH2_PROXY_CLIENT_SECRET"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.oauth2_proxy_credentials[0].metadata[0].name
                key  = "OAUTH2_PROXY_CLIENT_SECRET"
              }
            }
          }

          env {
            name = "OAUTH2_PROXY_COOKIE_SECRET"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.oauth2_proxy_credentials[0].metadata[0].name
                key  = "OAUTH2_PROXY_COOKIE_SECRET"
              }
            }
          }

          port {
            name           = "http"
            container_port = 4180
          }

          dynamic "port" {
            for_each = local.base_url_is_https ? [1] : []
            content {
              name           = "https"
              container_port = 4443
            }
          }

          dynamic "volume_mount" {
            for_each = local.base_url_is_https ? [1] : []
            content {
              name       = "oauth2-proxy-tls"
              mount_path = "/etc/oauth2-proxy/tls"
              read_only  = true
            }
          }
        }

        dynamic "volume" {
          for_each = local.base_url_is_https ? [1] : []
          content {
            name = "oauth2-proxy-tls"
            secret {
              secret_name = kubernetes_secret.oauth2_proxy_tls[0].metadata[0].name
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.this, terraform_data.keycloak_proxy_validation]
}

resource "kubernetes_service" "oauth2_proxy" {
  count = local.keycloak_proxy_enabled ? 1 : 0

  metadata {
    name      = "${var.release_name}-oauth2-proxy"
    namespace = var.namespace
    labels = {
      app = "${var.release_name}-oauth2-proxy"
    }
  }

  spec {
    selector = {
      app = "${var.release_name}-oauth2-proxy"
    }
    type = "NodePort"

    port {
      name        = "http"
      port        = 80
      target_port = local.base_url_is_https ? 4443 : 4180
      node_port   = var.public_node_port
    }
  }

  depends_on = [kubernetes_deployment.oauth2_proxy]
}
