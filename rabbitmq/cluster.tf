resource "kubernetes_manifest" "rabbitmq-cluster" {
  manifest = {
    "apiVersion" = "rabbitmq.com/v1beta1"
    "kind"       = "RabbitmqCluster"
    "metadata" = {
      "name"      = "ucl-aa-rabbitmq-cluster",
      "namespace" = "ucl-aa",
    }
    "spec" = {
      "override" = {
        "statefulSet" = {
          "spec" = {
            "template" = {
              "spec" = {
                "containers" = []
                "topologySpreadConstraints" = [
                  {
                    "labelSelector" = {
                      "matchLabels" = {
                        "app.kubernetes.io/name" = "ucl-aa-rabbitmq-cluster"
                      }
                    }
                    "maxSkew"           = 1
                    "topologyKey"       = "topology.kubernetes.io/zone"
                    "whenUnsatisfiable" = "DoNotSchedule"
                  },
                ]
              }
            }
          }
        }
      }
      "persistence" = {
        "storage"          = "10Gi"
        "storageClassName" = "local-path"
      }
      "rabbitmq" = {
        "additionalConfig" = <<-EOT
      cluster_partition_handling = pause_minority
      vm_memory_high_watermark_paging_ratio = 0.99
      disk_free_limit.relative = 1.0
      collect_statistics_interval = 10000

      EOT
      }
      "replicas" = 3
      "resources" = {
        "limits" = {
          "cpu"    = 4
          "memory" = "10Gi"
        }
      }
    }
  }
}

resource "kubernetes_manifest" "rabbitmq-cluster-disruption-budget" {
  manifest = {
    "apiVersion" = "policy/v1beta1"
    "kind"       = "PodDisruptionBudget"
    "metadata" = {
      "name"      = "ucl-aa-rabbitmq-cluster"
      "namespace" = "ucl-aa"
    }
    "spec" = {
      "maxUnavailable" = 1
      "selector" = {
        "matchLabels" = {
          "app.kubernetes.io/name" = "ucl-aa-rabbitmq-cluster"
        }
      }
    }
  }
}
