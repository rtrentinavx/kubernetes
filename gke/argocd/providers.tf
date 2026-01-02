
terraform {
  required_version = ">= 1.5.0"

  required_providers {

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.27.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.12.1"
    }
  }

  backend "gcs" {
    bucket = "test-lab-tf-state"
    prefix = "gke-gitops"
  }
}

provider "kubernetes" {
  config_path    = var.kubeconfig_path
  config_context = var.config_context
}

provider "helm" {
  kubernetes = {
    config_path    = var.kubeconfig_path
    config_context = var.config_context
  }
}