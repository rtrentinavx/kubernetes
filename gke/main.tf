# locals.tf
locals {

  vpc_name             = "${var.region}-${local.hash6}-vpc"
  subnet_name          = "${var.region}-${local.hash6}-subnet"
  router_name          = "${var.region}-${local.hash6}-router"
  cluster_name         = "${var.region}-${local.hash6}-cluster"
  nat_name             = "${var.region}-${local.hash6}-nat"
  bastion_machine_name = "${var.region}-${local.hash6}-bastion"
  hash_source          = format("%s|%s", var.project_id, var.region)
  hash6                = substr(md5(local.hash_source), 0, 4)

  ssh_keys_concat = length(var.ssh_authorized_keys) > 0 ? join("\n", var.ssh_authorized_keys) : ""

  # Auto-populate with current machine's IP
  my_public_ip = "${data.http.current_ip.response_body}/32"

  master_authorized_networks = concat(
    [
      {
        cidr_block   = local.my_public_ip
        display_name = "current-machine"
      },
      {
        cidr_block   = var.bastion_subnet_cidr
        display_name = "bastion-subnet"
      }
    ],
    var.additional_authorized_networks
  )

  ssh_allowed_cidrs = [local.my_public_ip]

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

resource "google_compute_subnetwork" "bastion" {
  name                     = "${var.region}-${local.hash6}-bastion-subnet"
  project                  = var.project_id
  region                   = var.region
  network                  = google_compute_network.vpc.self_link
  ip_cidr_range            = var.bastion_subnet_cidr
  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }

  lifecycle {
    precondition {
      condition     = can(cidrnetmask(var.bastion_subnet_cidr))
      error_message = "Invalid CIDR for bastion subnet."
    }
    precondition {
      condition = (
        var.bastion_subnet_cidr != var.subnet_cidr &&
        var.bastion_subnet_cidr != var.pods_secondary_cidr &&
        var.bastion_subnet_cidr != var.services_secondary_cidr
      )
      error_message = "Bastion subnet CIDR must be distinct from GKE subnets."
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

  deletion_protection = var.deletion_protection

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
    master_ipv4_cidr_block  = var.private_cluster ? var.master_ipv4_cidr_block : null
  }

  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = local.master_authorized_networks
      content {
        cidr_block   = cidr_blocks.value.cidr_block
        display_name = cidr_blocks.value.display_name
      }
    }
  }

  networking_mode          = "VPC_NATIVE"
  datapath_provider        = "ADVANCED_DATAPATH"
  remove_default_node_pool = true

  # Dataplane V2 Observability (metrics)
  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS", "STORAGE", "HPA", "POD", "DAEMONSET", "DEPLOYMENT", "STATEFULSET", "CADVISOR", "KUBELET"]
    managed_prometheus {
      enabled = var.enable_managed_prometheus
    }
    advanced_datapath_observability_config {
      enable_metrics = var.enable_dataplane_v2_metrics
      enable_relay   = var.enable_dataplane_v2_metrics
    }
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Using monitoring_config and logging_config blocks instead of deprecated *_service options
  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }

  cost_management_config { enabled = true }

  # Vertical Pod Autoscaling
  vertical_pod_autoscaling {
    enabled = var.enable_vpa
  }

  # Node Auto-Provisioning (NAP)
  cluster_autoscaling {
    enabled = var.enable_nap

    dynamic "resource_limits" {
      for_each = var.enable_nap ? [1] : []
      content {
        resource_type = "cpu"
        minimum       = var.nap_min_cpu
        maximum       = var.nap_max_cpu
      }
    }

    dynamic "resource_limits" {
      for_each = var.enable_nap ? [1] : []
      content {
        resource_type = "memory"
        minimum       = var.nap_min_memory
        maximum       = var.nap_max_memory
      }
    }

    dynamic "auto_provisioning_defaults" {
      for_each = var.enable_nap ? [1] : []
      content {
        service_account = google_service_account.nodes.email
        oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]

        management {
          auto_upgrade = true
          auto_repair  = true
        }

        shielded_instance_config {
          enable_secure_boot = true
        }
      }
    }
  }

  initial_node_count = 1

  depends_on = [google_compute_router_nat.nat]
}

resource "google_container_node_pool" "default" {
  name     = "np-default-${local.hash6}"
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

    # Enable gVNIC for better network performance (required for TIER_1)
    gvnic {
      enabled = var.enable_gvnic
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
  depends_on = [google_compute_router_nat.nat]
}

# Additional node pools
resource "google_container_node_pool" "additional" {
  for_each = var.additional_node_pools

  name     = "${each.key}-${local.hash6}"
  project  = var.project_id
  cluster  = google_container_cluster.cluster.name
  location = var.region

  node_count = each.value.node_count

  # Distribute across zones (1 node per zone initially)
  node_locations = [
    "${var.region}-b",
    "${var.region}-c",
    "${var.region}-d"
  ]

  autoscaling {
    min_node_count = each.value.min_node_count
    max_node_count = each.value.max_node_count
  }

  node_config {
    machine_type    = each.value.machine_type
    service_account = google_service_account.nodes.email
    disk_size_gb    = each.value.disk_size_gb
    disk_type       = each.value.disk_type
    preemptible     = each.value.preemptible
    spot            = each.value.spot
    labels          = each.value.labels

    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]

    shielded_instance_config {
      enable_secure_boot = true
    }

    dynamic "taint" {
      for_each = each.value.taints
      content {
        key    = taint.value.key
        value  = taint.value.value
        effect = taint.value.effect
      }
    }

    tags = ["${local.cluster_name}-${each.key}"]
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }

  depends_on = [google_compute_router_nat.nat]
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


resource "google_compute_instance" "bastion" {
  name         = local.bastion_machine_name
  machine_type = var.bastion_machine_type
  project      = var.project_id
  zone         = var.zone

  network_interface {
    network    = google_compute_network.vpc.self_link
    subnetwork = google_compute_subnetwork.bastion.self_link


    dynamic "access_config" {
      for_each = var.enable_external_ip ? [1] : []
      content {}
    }

  }

  metadata = merge(
    {
      enable-oslogin         = "FALSE"
      block-project-ssh-keys = "FALSE"
      startup-script         = var.startup_script
    },
    length(local.ssh_keys_concat) > 0 ? { "ssh-keys" = local.ssh_keys_concat } : {}
  )

  boot_disk {
    initialize_params {
      image = "projects/debian-cloud/global/images/family/debian-12"
      size  = 20
      type  = "pd-balanced"
    }
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = false
    enable_integrity_monitoring = false
  }

  tags = ["bastion"]

  service_account {
    email  = google_service_account.nodes.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}

resource "google_compute_firewall" "ssh_public_iap" {
  count         = var.enable_external_ip && length(local.ssh_allowed_cidrs) > 0 ? 1 : 0
  name          = "allow-ssh-iap"
  network       = google_compute_network.vpc.self_link
  direction     = "INGRESS"
  source_ranges = concat(["35.235.240.0/20"], local.ssh_allowed_cidrs)
  target_tags   = ["bastion"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}
