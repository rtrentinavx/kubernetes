############################################
# Data source: Current GKE Cluster Context
############################################
data "kubernetes_service_account_v1" "terraform" {
  metadata {
    name      = "default"
    namespace = "kube-system"
  }

  depends_on = [kubernetes_namespace_v1.flux_system]
}

############################################
# Local for tracking deployment info
############################################
locals {
  flux_deployed_at = timestamp()
  deployment_info = {
    flux_version          = var.flux_chart_version
    weave_gitops_version  = var.weave_chart_version
    github_repo           = "https://github.com/${var.github_owner}/${var.github_repo}"
    flux_namespace        = var.flux_namespace
    weave_namespace       = var.weave_namespace
  }
}
