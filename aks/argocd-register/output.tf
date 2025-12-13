output "cluster_name" {
  description = "Name of the cluster registered in ArgoCD"
  value       = argocd_cluster.aks.name
}

output "cluster_server" {
  description = "Kubernetes API server URL"
  value       = argocd_cluster.aks.server
}

output "argocd_server_detected" {
  description = "Detected ArgoCD server address"
  value       = var.auto_detect_argocd ? try("${coalesce(data.kubernetes_service.argocd_server[0].status[0].load_balancer[0].ingress[0].ip, data.kubernetes_service.argocd_server[0].status[0].load_balancer[0].ingress[0].hostname)}:443", "pending") : "not detected"
}

output "argocd_password_detected" {
  description = "ArgoCD password was detected from secret"
  value       = var.auto_detect_argocd ? (length(data.kubernetes_secret.argocd_initial_admin_secret) > 0 ? "yes" : "no") : "not detected"
  sensitive   = false
}
