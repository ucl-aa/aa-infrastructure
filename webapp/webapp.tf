variable "server_host" {
  type        = string
  description = "(required)"
}

resource "kubernetes_deployment" "aa-webapp-deployment" {
  metadata {
    name      = "aa-webapp"
    namespace = "ucl-aa"
    labels = {
      "app.kubernetes.io/component" = "server"
      "app.kubernetes.io/instance"  = "aa-webapp"
      "app.kubernetes.io/name"      = "aa-webapp"
    }
  }
  spec {
    replicas = 3
    selector {
      match_labels = {
        "app.kubernetes.io/component" = "server"
        "app.kubernetes.io/instance"  = "aa-webapp"
        "app.kubernetes.io/name"      = "aa-webapp"
      }
    }
    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_surge       = "25%"
        max_unavailable = "25%"
      }
    }
    template {
      metadata {
        labels = {
          "app.kubernetes.io/component" = "server"
          "app.kubernetes.io/instance"  = "aa-webapp"
          "app.kubernetes.io/name"      = "aa-webapp"
        }
        annotations = {
          "linkerd.io/inject" = "enabled"
        }
      }
      spec {
        container {
          name  = "aa-webapp"
          image = "cr.seen.wtf/aa-webapp:latest"
          liveness_probe {
            http_get {
              path = "/"
              port = "http"
            }
          }
          port {
            container_port = 80
            name           = "http"
            protocol       = "TCP"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "aa-webapp-service" {
  metadata {
    name      = "aa-webapp"
    namespace = "ucl-aa"
    labels = {
      "app.kubernetes.io/component" = "server"
      "app.kubernetes.io/instance"  = "aa-webapp"
      "app.kubernetes.io/name"      = "aa-webapp"
    }
  }
  spec {
    type = "ClusterIP"
    port {
      name     = "http"
      port     = 80
      protocol = "TCP"
    }
    selector = {
      "app.kubernetes.io/component" = "server"
      "app.kubernetes.io/instance"  = "aa-webapp"
      "app.kubernetes.io/name"      = "aa-webapp"
    }
  }
}


resource "kubernetes_manifest" "aa-webapp-ingressroute-tls" {
  manifest = {
    "apiVersion" = "traefik.containo.us/v1alpha1"
    "kind"       = "IngressRoute"
    "metadata" = {
      "name"      = "aa-webapp-ingressroutetls"
      "namespace" = "ucl-aa"
    }
    "spec" = {
      "entryPoints" = [
        "websecure",
      ]
      "routes" = [
        {
          "kind"  = "Rule"
          "match" = "Host(`${var.server_host}`) && PathPrefix(`/`)"
          "services" = [
            {
              "name" = "aa-webapp"
              "port" = 80
            },
          ]
        },
      ]
      "tls" = {
        "certResolver" = "myresolver"
      }
    }
  }
}
