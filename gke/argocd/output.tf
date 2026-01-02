output "argocd_lb_ip" {
  value       = google_compute_address.argocd_lb_ip.address
  description = "Static external IP for Argo CD LoadBalancer (GCP External Network LB)"
}

output "argocd_namespace" {
  value       = kubernetes_namespace_v1.argocd.metadata[0].name
  description = "Namespace where Argo CD is installed"
}

output "argocd_service_name" {
  value       = "argocd-argocd-server" # default service name from the chart
  description = "Service name created by the Helm chart"
}