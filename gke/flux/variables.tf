variable "kubeconfig_path" {
  type        = string
  default     = "~/.kube/config"
  description = "Path to kubeconfig used by providers"
}

variable "config_context" {
  type        = string
  default     = ""
  description = "Kubeconfig context to use"
}

variable "project" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "GCP region"
}

variable "flux_namespace" {
  type        = string
  default     = "flux-system"
  description = "Kubernetes namespace for Flux components"
}

variable "weave_namespace" {
  type        = string
  default     = "weave-gitops"
  description = "Kubernetes namespace for Weave GitOps UI"
}

variable "flux_chart_version" {
  type        = string
  default     = "2.2.0"
  description = "Version of the Flux v2 Helm chart"
}

variable "weave_chart_version" {
  type        = string
  default     = "4.0.0"
  description = "Version of the Weave GitOps Helm chart"
}

variable "github_token" {
  type        = string
  sensitive   = true
  description = "GitHub Personal Access Token for Git authentication"
}

variable "github_owner" {
  type        = string
  description = "GitHub repository owner/organization"
}

variable "github_repo" {
  type        = string
  description = "GitHub repository name"
}

variable "gitops_repo_path" {
  type        = string
  default     = "./"
  description = "Path within the repository where Flux should look for GitOps configurations"
}

variable "gitops_repo_branch" {
  type        = string
  default     = "main"
  description = "Git branch to use for reconciliation"
}

variable "weave_admin_password_length" {
  type        = number
  default     = 16
  description = "Length of the auto-generated admin password for Weave GitOps UI"
}

variable "enable_notifications" {
  type        = bool
  default     = false
  description = "Enable Flux notifications for delivery status and alerts"
}
