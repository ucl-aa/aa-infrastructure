terraform {
  required_version = ">=1.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
  }
}

provider "kubernetes" {
  experiments {
    manifest_resource = true
  }
  config_path = "~/.kube/config"
}

resource "kubernetes_namespace" "ucl-aa-namespace" {
  metadata {
    name = "ucl-aa"
  }
}

module "webapp" {
  source = "./webapp"

  server_host = "aa.seen.wtf"
}

module "rabbitmq" {
  source = "./rabbitmq"
}

