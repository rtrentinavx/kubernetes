
output "network_name" { value = google_compute_network.vpc.name }
output "subnet_name" { value = google_compute_subnetwork.gke.name }
output "cluster_name" { value = google_container_cluster.cluster.name }
output "cluster_endpoint" { value = google_container_cluster.cluster.endpoint }
output "node_pool_name" { value = google_container_node_pool.default.name }

