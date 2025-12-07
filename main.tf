
########################
# Network (flat root)  #
########################

resource "google_compute_network" "vpc" {
  name                    = var.network_name
  project                 = var.project_id
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL" # recommended for multi-region control
}

resource "google_compute_subnetwork" "gke" {
  name          = var.subnet_name
  project       = var.project_id
  region        = var.region
  network       = google_compute_network.vpc.self_link
  ip_cidr_range = var.subnet_cidr

  private_ip_google_access = true

  # VPC-native GKE requires alias IPs via secondary ranges
  secondary_ip_range {
    range_name    = "pods-range"
    ip_cidr_range = var.pods_secondary_cidr
  }

  secondary_ip_range {
    range_name    = "services-range"
    ip_cidr_range = var.services_secondary_cidr
  }

  # Observability: VPC Flow Logs (tune to your needs)
  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }

  # Optional: guardrail to ensure all CIDRs are valid and distinct
  lifecycle {
    precondition {
      condition     = can(cidrnetmask(var.subnet_cidr)) && can(cidrnetmask(var.pods_secondary_cidr)) && can(cidrnetmask(var.services_secondary_cidr))
      error_message = "One or more CIDRs are invalid (subnet/pods/services)."
    }
    precondition {
      condition = (
        var.subnet_cidr != var.pods_secondary_cidr &&
        var.subnet_cidr != var.services_secondary_cidr &&
        var.pods_secondary_cidr != var.services_secondary_cidr
      )
      error_message = "CIDR ranges must be distinct (subnet/pods/services)."
    }
  }
}

# Cloud Router + NAT to allow private nodes to pull images/updates
resource "google_compute_router" "router" {
  name    = "${var.network_name}-router"
  region  = var.region
  network = google_compute_network.vpc.self_link
  project = var.project_id
}

resource "google_compute_router_nat" "nat" {
  name                               = "${var.network_name}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  project                            = var.project_id
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.gke.self_link
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

########################
# GKE (flat root)      #
########################

# Always create a dedicated node service account (no locals / no ternary)
resource "google_service_account" "nodes" {
  account_id   = "gke-nodes"
  display_name = "GKE Nodes Service Account"
  project      = var.project_id
}

resource "google_container_cluster" "cluster" {
  name     = var.cluster_name
  location = var.cluster_location
  project  = var.project_id

  network    = google_compute_network.vpc.self_link
  subnetwork = google_compute_subnetwork.gke.self_link

  release_channel { channel = var.gke_release_channel }

  # VPC-native (alias IP) with secondary ranges
  ip_allocation_policy {
    cluster_secondary_range_name  = "pods-range"
    services_secondary_range_name = "services-range"
  }

  # Private cluster configuration
  private_cluster_config {
    enable_private_nodes    = var.private_cluster
    enable_private_endpoint = var.private_cluster
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  # Restrict access to the control plane
  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.master_authorized_networks
      content {
        cidr_block   = cidr_blocks.value.cidr_block
        display_name = cidr_blocks.value.display_name
      }
    }
  }

  # Cluster hardening & telemetry
  networking_mode          = "VPC_NATIVE"
  remove_default_node_pool = true
  enable_autopilot         = false

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  enable_shielded_nodes = true

  depends_on = [
    google_compute_router_nat.nat, # ensure NAT is ready for private nodes
  ]
}

resource "google_container_node_pool" "default" {
  name     = "np-default"
  project  = var.project_id
  cluster  = google_container_cluster.cluster.name
  location = var.cluster_location

  node_count = var.node_count

  node_config {
    machine_type    = var.node_machine_type
    service_account = google_service_account.nodes.email

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    shielded_instance_config {
      enable_secure_boot = true
    }

    tags = ["gke-nodes"]
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }
}
