# locals.tf
locals {
  vpc_name     = "${var.region}-${local.hash6}-vpc"
  subnet_name  = "${var.region}-${local.hash6}-subnet"
  router_name  = "${var.region}-${local.hash6}-router"
  cluster_name = "${var.region}-${local.hash6}-cluster"
  nat_name     = "${var.region}-${local.hash6}-nat"
  hash_source  = format("%s|%s", var.project_id, var.region)
  hash6        = substr(md5(local.hash_source), 0, 4)
}


resource "google_compute_network" "vpc" {
  name                    = local.vpc_name
  project                 = var.project_id
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}


resource "google_compute_subnetwork" "gke" {
  name                     = local.subnet_name
  project                  = var.project_id
  region                   = var.region
  network                  = google_compute_network.vpc.self_link
  ip_cidr_range            = var.subnet_cidr
  private_ip_google_access = true


  secondary_ip_range {
    range_name    = "pods-range"
    ip_cidr_range = var.pods_secondary_cidr
  }

  secondary_ip_range {
    range_name    = "services-range"
    ip_cidr_range = var.services_secondary_cidr
  }

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }

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

resource "google_compute_router" "router" {
  name    = local.router_name
  region  = var.region
  network = google_compute_network.vpc.self_link
  project = var.project_id
}

resource "google_compute_router_nat" "nat" {
  name                               = local.nat_name
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

resource "google_service_account" "nodes" {
  account_id   = "gke-nodes"
  display_name = "GKE Nodes Service Account"
  project      = var.project_id
}

resource "google_container_cluster" "cluster" {
  name     = local.cluster_name
  location = var.region
  project  = var.project_id

  network    = google_compute_network.vpc.self_link
  subnetwork = google_compute_subnetwork.gke.self_link

  release_channel { channel = var.gke_release_channel }

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods-range"
    services_secondary_range_name = "services-range"
  }

  private_cluster_config {
    enable_private_nodes    = var.private_cluster
    enable_private_endpoint = var.enable_private_endpoint
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }

  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.master_authorized_networks
      content {
        cidr_block   = cidr_blocks.value.cidr_block
        display_name = cidr_blocks.value.display_name
      }
    }
  }

  networking_mode          = "VPC_NATIVE"
  remove_default_node_pool = true

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  cost_management_config { enabled = true }

  initial_node_count = 1

  depends_on = [google_compute_router_nat.nat]
}

resource "google_container_node_pool" "default" {
  name     = "np-default"
  project  = var.project_id
  cluster  = google_container_cluster.cluster.name
  location = var.region

  node_count = var.node_count

  autoscaling {
    min_node_count = var.node_pool_min_count
    max_node_count = var.node_pool_max_count
  }

  node_config {
    machine_type    = var.node_machine_type
    service_account = google_service_account.nodes.email

    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]

    shielded_instance_config {
      enable_secure_boot = true
    }

    tags = ["${local.cluster_name}-node-pool"]
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

resource "google_gke_backup_backup_plan" "plan" {
  count    = var.enable_backup ? 1 : 0
  name     = "${local.cluster_name}-backup-plan"
  project  = var.project_id
  location = var.region

  cluster = google_container_cluster.cluster.id

  backup_schedule {
    rpo_config {
      target_rpo_minutes = 1440
    }
  }

  retention_policy {
    backup_delete_lock_days = 0
    backup_retain_days      = var.backup_retention_days
  }

  backup_config {
    include_secrets     = true
    include_volume_data = true
    selected_applications {
      namespaced_names {
        namespace = var.backup_namespace
        name      = var.backup_name
      }
    }
  }
}