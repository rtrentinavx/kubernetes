locals {
  kubeconfig = yamldecode(file(var.kubeconfig_path))
  
  # Find the context and cluster info
  context_name = var.kubeconfig_context != "" ? var.kubeconfig_context : local.kubeconfig.current-context
  
  # Get context details
  context = [for ctx in local.kubeconfig.contexts : ctx if ctx.name == local.context_name][0]
  
  # Get cluster details
  cluster = [for c in local.kubeconfig.clusters : c.cluster if c.name == local.context.context.cluster][0]
  
  # Get user details
  user = [for u in local.kubeconfig.users : u.user if u.name == local.context.context.user][0]
}

# Data source to get ArgoCD server address from ArgoCD cluster
data "kubernetes_service" "argocd_server" {
  count = var.auto_detect_argocd ? 1 : 0
  
  metadata {
    name      = "argocd-server"
    namespace = var.argocd_namespace
  }
}

# Data source to get ArgoCD admin password
data "kubernetes_secret" "argocd_initial_admin_secret" {
  count = var.auto_detect_argocd ? 1 : 0
  
  metadata {
    name      = "argocd-initial-admin-secret"
    namespace = var.argocd_namespace
  }
}

resource "argocd_cluster" "aks" {
  name   = var.cluster_name_in_argocd
  server = local.cluster.server

  config {
    tls_client_config {
      ca_data   = local.cluster.certificate-authority-data
      cert_data = local.user.client-certificate-data
      key_data  = local.user.client-key-data
    }
  }

  project = var.argocd_project
}
