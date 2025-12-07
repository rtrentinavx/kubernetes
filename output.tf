output "cluster_name" { value = google_container_cluster.cluster.name }
output "cluster_endpoint" { value = google_container_cluster.cluster.endpoint }
output "network_name" { value = google_compute_network.vpc.name }
output "subnet_name" { value = google_compute_subnetwork.gke.name }
output "argocd_namespace" {
  value = kubernetes_namespace_v1.argocd.metadata[0].name
}
