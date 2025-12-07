
variable "project_id" {
  description = "GCP project ID"
  type        = string
}
variable "region" {
  description = "Default region"
  type        = string
}

variable "network_name" {
  type = string
}
variable "subnet_name" {
  type = string
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

variable "cluster_name" {
  type = string
}
variable "cluster_location" {
  type = string
}

variable "gke_release_channel" {
  type    = string
  default = "REGULAR"
}

variable "node_machine_type" {
  type = string
}
variable "node_count" {
  type    = number
  default = 1
}
variable "private_cluster" {
  type    = bool
  default = true
}

variable "master_authorized_networks" {
  description = "CIDRs allowed to access the control plane"
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
}

variable "node_pool_min_count" {
  type    = number
  default = 1
}
variable "node_pool_max_count" {
  type    = number
  default = 3
}

variable "kubeconfig_path" {
  type        = string
  default     = "~/.kube/config"
  description = "Path to kubeconfig used by providers"
}

variable "argocd_namespace" {
  type    = string
  default = "argocd"
}
variable "argocd_chart_version" {
  type        = string
  default     = "5.51.6" # update as needed
  description = "Version of argo/argo-cd Helm chart"
}

variable "gitops_repo_url" {
  type        = string
  description = "Git URL for the repo that contains your Argo CD root application (HTTPS or SSH)"
}

variable "gitops_repo_path" {
  type        = string
  default     = "clusters/prod"
  description = "Path within the repo to manifests (Kustomize/Helm) for the root app"
}

variable "gitops_repo_revision" {
  type        = string
  default     = "main"
  description = "Git revision (branch/tag) for the root app"
}

variable "root_app_name" {
  type        = string
  default     = "root-app"
  description = "Name of the Argo CD Application used as App-of-Apps"
}

variable "enable_backup" {
  type        = bool
  default     = true
  description = "Create a basic Backup for GKE plan for the cluster (namespace-wide example)"
}

variable "backup_namespace" {
  type        = string
  default     = "default"
  description = "Namespace to include in the example backup plan"
}

variable "backup_name" {
  type        = string
  default     = "default"
  description = "Name of the backup plan"
}

variable "backup_retention_days" {
  type        = number
  default     = 7
  description = "Retention for backups created by the plan"
}


