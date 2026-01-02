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
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9.0"
    }
    flux = {
      source  = "fluxcd/flux"
      version = ">= 1.0.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.0"
    }
  }

  backend "gcs" {
    bucket = "test-lab-tf-state"
    prefix = "gke-gitops-flux"
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

provider "flux" {
  kubernetes = {
    config_path    = var.kubeconfig_path
    config_context = var.config_context
  }
  git = {
    url = "https://github.com/${var.github_owner}/${var.github_repo}"
    http = {
      username = "git"
      password = var.github_token
    }
  }
}

provider "google" {
  project = var.project
  region  = var.region
}
