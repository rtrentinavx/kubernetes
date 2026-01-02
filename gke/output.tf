output "cluster_name" { value = google_container_cluster.cluster.name }
output "cluster_endpoint" { value = google_container_cluster.cluster.endpoint }
output "bastion_host_ip" { value = google_compute_instance.bastion.network_interface[0].access_config[0].nat_ip }