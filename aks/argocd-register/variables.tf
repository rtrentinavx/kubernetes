variable "kubeconfig_path" {
  description = "Path to kubeconfig file for AKS cluster"
  type        = string
  default     = "~/.kube/config"
}

variable "kubeconfig_context" {
  description = "Kubeconfig context to use for AKS cluster (empty for current-context)"
  type        = string
  default     = ""
}

variable "cluster_name_in_argocd" {
  description = "Name to use for the cluster in ArgoCD"
  type        = string
}

variable "auto_detect_argocd" {
  description = "Automatically detect ArgoCD server and password from Kubernetes cluster"
  type        = bool
  default     = true
}

variable "argocd_kubeconfig_path" {
  description = "Path to kubeconfig file for ArgoCD cluster (where ArgoCD is installed)"
  type        = string
  default     = "~/.kube/config"
}

variable "argocd_kubeconfig_context" {
  description = "Kubeconfig context for ArgoCD cluster (where ArgoCD is installed)"
  type        = string
  default     = ""
}

variable "argocd_namespace" {
  description = "Namespace where ArgoCD is installed"
  type        = string
  default     = "argocd"
}

variable "argocd_server" {
  description = "ArgoCD server address (e.g., argocd.example.com:443) - only used if auto_detect_argocd is false"
  type        = string
  default     = ""
}

variable "argocd_username" {
  description = "ArgoCD admin username"
  type        = string
  default     = "admin"
}

variable "argocd_password" {
  description = "ArgoCD admin password - only used if auto_detect_argocd is false"
  type        = string
  sensitive   = true
  default     = ""
}

variable "argocd_insecure" {
  description = "Skip TLS verification for ArgoCD server"
  type        = bool
  default     = false
}

variable "argocd_project" {
  description = "ArgoCD project to assign the cluster to"
  type        = string
  default     = "default"
}
