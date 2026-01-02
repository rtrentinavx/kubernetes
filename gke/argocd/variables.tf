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
  default     = "/"
  description = "Path within the repo to manifests (Kustomize/Helm) for the root app"
}

variable "gitops_repo_revision" {
  type        = string
  default     = "main"
  description = "Git revision (branch/tag) for the root app"
}

variable "region" {
  type        = string
  default     = "us-east1"
  description = "Region where GKE cluster and resources are deployed"
}

variable "root_app_name" {
  type        = string
  default     = "root-app"
  description = "Name of the Argo CD Application used as App-of-Apps"
}

variable "project" {
  type        = string
  description = "Project ID where GKE cluster and resources are deployed"
}