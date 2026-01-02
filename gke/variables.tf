variable "backup_name" {
  description = "The name of the application to include in the GKE backup."
  type        = string
  default     = "default"
}

variable "backup_namespace" {
  description = "The namespace to include in the GKE backup."
  type        = string
  default     = "default"
}

variable "backup_retention_days" {
  description = "Number of days to retain backups."
  type        = number
  default     = 7
}

variable "bastion_machine_type" {
  description = "Bastion machine type"
  type        = string
  default     = "e2-micro"
}

variable "bastion_subnet_cidr" {
  description = "CIDR for bastion subnet (e.g., 10.20.0.0/28)"
  type        = string
}

variable "enable_backup" {
  description = "Whether to enable GKE Backup for the cluster."
  type        = bool
  default     = true
}

variable "enable_external_ip" {
  description = "Enable external IP for bastion"
  type        = bool
  default     = false
}

variable "enable_private_endpoint" {
  description = "Whether to create a private endpoint for the GKE cluster master."
  type        = bool
  default     = true
}

variable "gke_release_channel" {
  description = "GKE release channel for the cluster."
  type        = string
  default     = "REGULAR"
}

variable "additional_authorized_networks" {
  description = "Additional authorized networks for the GKE master (besides bastion and terraform runner IP)."
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = []
}

variable "master_ipv4_cidr_block" {
  description = "CIDR block for GKE master authorized networks"
  type        = string
  default     = "172.16.0.0/28"
}

variable "node_count" {
  description = "Initial number of nodes for the default node pool."
  type        = number
  default     = 1
}

variable "node_machine_type" {
  description = "Machine type for the GKE nodes."
  type        = string
}

variable "node_pool_max_count" {
  description = "Maximum number of nodes for the default node pool autoscaling."
  type        = number
  default     = 3
}

variable "node_pool_min_count" {
  description = "Minimum number of nodes for the default node pool autoscaling."
  type        = number
  default     = 1
}

variable "pods_secondary_cidr" {
  description = "Secondary range for Pods (alias IP)"
  type        = string
  validation {
    condition     = can(cidrnetmask(var.pods_secondary_cidr))
    error_message = "pods_secondary_cidr must be a valid CIDR."
  }
}

variable "private_cluster" {
  description = "Whether to create a private GKE cluster."
  type        = bool
  default     = true
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "Default region"
  type        = string
}

variable "services_secondary_cidr" {
  description = "Secondary range for Services (alias IP)"
  type        = string
  validation {
    condition     = can(cidrnetmask(var.services_secondary_cidr))
    error_message = "services_secondary_cidr must be a valid CIDR."
  }
}

variable "ssh_allowed_cidrs" {
  description = "List of CIDR blocks allowed to access the bastion via SSH"
  type        = list(string)
  default     = []
}

variable "ssh_authorized_keys" {
  description = "List of authorized SSH keys in 'username:ssh-rsa ...' format"
  type        = list(string)
  default     = []
}

variable "startup_script" {
  description = "Startup script for bastion"
  type        = string
  default     = <<-EOT
#!/bin/bash
set -e

# Configure non-interactive frontend for apt
export DEBIAN_FRONTEND=noninteractive

# Update packages and install dependencies
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gnupg

# Install gcloud SDK non-interactively
curl https://sdk.cloud.google.com | bash -s -- --disable-prompts
export PATH=$PATH:/root/google-cloud-sdk/bin
gcloud --version

# Install kubectl
KUBECTL_VERSION=$(curl -s https://dl.k8s.io/release/stable.txt)
curl -LO "https://dl.k8s.io/release/$${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl # clean up downloaded binary
kubectl version --client

# Install Argo CD CLI
ARGOCD_VERSION=$(curl --silent "https://api.github.com/repos/argoproj/argo-cd/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/download/$${ARGOCD_VERSION}/argocd-linux-amd64
chmod +x /usr/local/bin/argocd
argocd version --client
EOT
}

variable "subnet_cidr" {
  description = "Primary subnet CIDR for nodes"
  type        = string
  validation {
    condition     = can(cidrnetmask(var.subnet_cidr))
    error_message = "subnet_cidr must be a valid CIDR (e.g., 10.10.0.0/20)."
  }
}

variable "zone" {
  description = "Default zone"
  type        = string
  default     = ""
}

variable "deletion_protection" {
  description = "Enable deletion protection for the GKE cluster."
  type        = bool
  default     = false
}

variable "additional_node_pools" {
  description = "Map of additional node pools to create"
  type = map(object({
    node_count     = number
    min_node_count = number
    max_node_count = number
    machine_type   = string
    disk_size_gb   = optional(number, 100)
    disk_type      = optional(string, "pd-standard")
    preemptible    = optional(bool, false)
    spot           = optional(bool, false)
    labels         = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])
  }))
  default = {}
}

# Node Auto-Provisioning (NAP) variables
variable "enable_nap" {
  description = "Enable Node Auto-Provisioning (NAP) for automatic node pool creation"
  type        = bool
  default     = false
}

# Vertical Pod Autoscaling (VPA) variable
variable "enable_vpa" {
  description = "Enable Vertical Pod Autoscaling (VPA) for resource recommendations"
  type        = bool
  default     = true
}

variable "nap_min_cpu" {
  description = "Minimum total CPU cores for NAP"
  type        = number
  default     = 0
}

variable "nap_max_cpu" {
  description = "Maximum total CPU cores for NAP"
  type        = number
  default     = 100
}

variable "nap_min_memory" {
  description = "Minimum total memory (GB) for NAP"
  type        = number
  default     = 0
}

variable "nap_max_memory" {
  description = "Maximum total memory (GB) for NAP"
  type        = number
  default     = 200
}

# Dataplane V2 Observability
variable "enable_dataplane_v2_metrics" {
  description = "Enable Dataplane V2 metrics and observability"
  type        = bool
  default     = true
}

variable "enable_managed_prometheus" {
  description = "Enable GKE Managed Prometheus for metrics collection"
  type        = bool
  default     = true
}

# Network Service Tier / gVNIC
variable "enable_gvnic" {
  description = "Enable gVNIC (Google Virtual NIC) for better network performance and higher bandwidth"
  type        = bool
  default     = true
}