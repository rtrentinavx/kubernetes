
variable "project_id" {
  description = "GCP project ID"
  type        = string
}
variable "region" {
  description = "Default region"
  type        = string
}

variable "subnet_cidr" {
  description = "Primary subnet CIDR for nodes"
  type        = string
  validation {
    condition     = can(cidrnetmask(var.subnet_cidr))
    error_message = "subnet_cidr must be a valid CIDR (e.g., 10.10.0.0/20)."
  }
}

variable "pods_secondary_cidr" {
  description = "Secondary range for Pods (alias IP)"
  type        = string
  validation {
    condition     = can(cidrnetmask(var.pods_secondary_cidr))
    error_message = "pods_secondary_cidr must be a valid CIDR."
  }
}

variable "services_secondary_cidr" {
  description = "Secondary range for Services (alias IP)"
  type        = string
  validation {
    condition     = can(cidrnetmask(var.services_secondary_cidr))
    error_message = "services_secondary_cidr must be a valid CIDR."
  }
}

variable "master_ipv4_cidr_block" {
  description = "CIDR block for GKE master authorized networks"
  type        = string
  default     = "172.16.0.0/28"
}

variable "gke_release_channel" {
  description = "GKE release channel for the cluster."
  type        = string
  default     = "REGULAR"
}

variable "node_machine_type" {
  description = "Machine type for the GKE nodes."
  type        = string
}
variable "node_count" {
  description = "Initial number of nodes for the default node pool."
  type        = number
  default     = 1
}
variable "private_cluster" {
  description = "Whether to create a private GKE cluster."
  type        = bool
  default     = true
}

variable "enable_private_endpoint" {
  description = "Whether to create a private endpoint for the GKE cluster master."
  type        = bool
  default     = true
}

variable "master_authorized_networks" {
  description = "List of authorized networks for the GKE master."
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
}

variable "node_pool_min_count" {
  description = "Minimum number of nodes for the default node pool autoscaling."
  type        = number
  default     = 1
}

variable "node_pool_max_count" {
  description = "Maximum number of nodes for the default node pool autoscaling."
  type        = number
  default     = 3
}

variable "enable_backup" {
  description = "Whether to enable GKE Backup for the cluster."
  type        = bool
  default     = true
}

variable "backup_namespace" {
  description = "The namespace to include in the GKE backup."
  type        = string
  default     = "default"
}

variable "backup_name" {
  description = "The name of the application to include in the GKE backup."
  type        = string
  default     = "default"
}

variable "backup_retention_days" {
  description = "Number of days to retain backups."
  type        = number
  default     = 7
}
