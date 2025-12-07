
# -------- Core --------
variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "Default region for regional resources"
  type        = string
  default     = "us-central1"
}

# -------- Network --------
variable "network_name" {
  description = "VPC name"
  type        = string
  default     = "vpc-gke"
}

variable "subnet_name" {
  description = "Subnet for GKE nodes"
  type        = string
  default     = "subnet-gke"
}

variable "subnet_cidr" {
  description = "Primary subnet CIDR for nodes"
  type        = string
  default     = "10.10.0.0/20"

  validation {
    condition     = can(cidrnetmask(var.subnet_cidr))
    error_message = "subnet_cidr must be a valid CIDR (e.g., 10.10.0.0/20)."
  }
}

variable "pods_secondary_cidr" {
  description = "Secondary range for GKE Pods (alias IP)"
  type        = string
  default     = "10.20.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.pods_secondary_cidr))
    error_message = "pods_secondary_cidr must be a valid CIDR."
  }
}

variable "services_secondary_cidr" {
  description = "Secondary range for GKE Services (alias IP)"
  type        = string
  default     = "10.30.0.0/20"

  validation {
    condition     = can(cidrnetmask(var.services_secondary_cidr))
    error_message = "services_secondary_cidr must be a valid CIDR."
  }
}

# -------- GKE --------
variable "cluster_name" {
  description = "GKE cluster name"
  type        = string
  default     = "gke-primary"
}

variable "cluster_location" {
  description = "Region (for regional cluster) or zone"
  type        = string
  default     = "us-central1" # regional HA cluster
}

variable "gke_release_channel" {
  description = "GKE release channel (RAPID | REGULAR | STABLE)"
  type        = string
  default     = "REGULAR"
}

variable "node_machine_type" {
  description = "Node pool machine type"
  type        = string
  default     = "e2-standard-4"
}

variable "node_count" {
  description = "Initial node count per zone"
  type        = number
  default     = 2
}

variable "private_cluster" {
  description = "Enable private nodes & private control plane endpoint"
  type        = bool
  default     = true
}

variable "master_authorized_networks" {
  description = "CIDRs allowed to access the control plane"
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = [
    { cidr_block = "10.0.0.0/8", display_name = "corp" }
  ]
}
