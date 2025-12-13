terraform {
  required_version = ">= 1.5.0"

  required_providers {
    argocd = {
      source  = "oboukili/argocd"
      version = "~> 6.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

# Provider for ArgoCD cluster (where ArgoCD is installed)
provider "kubernetes" {
  alias          = "argocd_cluster"
  config_path    = var.argocd_kubeconfig_path
  config_context = var.argocd_kubeconfig_context
}

provider "argocd" {
  server_addr = var.auto_detect_argocd ? "${try(data.kubernetes_service.argocd_server[0].status[0].load_balancer[0].ingress[0].ip, data.kubernetes_service.argocd_server[0].status[0].load_balancer[0].ingress[0].hostname, var.argocd_server)}:443" : var.argocd_server
  username    = var.argocd_username
  password    = var.auto_detect_argocd ? try(base64decode(data.kubernetes_secret.argocd_initial_admin_secret[0].data["password"]), var.argocd_password) : var.argocd_password
  insecure    = var.argocd_insecure
}
