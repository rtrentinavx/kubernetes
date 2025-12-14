variable "kubeconfig_path" {
  description = "Path to kubeconfig file"
  type        = string
}

variable "kubeconfig_context" {
  description = "Kubernetes context to use"
  type        = string
  default     = ""
}

variable "flux_namespace" {
  description = "Namespace for Flux"
  type        = string
  default     = "flux-system"
}

variable "weave_namespace" {
  description = "Namespace for Weave GitOps"
  type        = string
  default     = "weave-gitops"
}

variable "github_token" {
  description = "GitHub personal access token for Flux"
  type        = string
  sensitive   = true
}

variable "github_owner" {
  description = "GitHub owner/organization"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name for GitOps config"
  type        = string
}

# Create flux-system namespace
resource "kubernetes_namespace" "flux_system" {
  metadata {
    name = var.flux_namespace
  }
}

# Create weave-gitops namespace
resource "kubernetes_namespace" "weave_gitops" {
  metadata {
    name = var.weave_namespace
  }
}

# Create Flux namespace secret for GitHub
resource "kubernetes_secret" "flux_github" {
  metadata {
    name      = "flux-github-token"
    namespace = kubernetes_namespace.flux_system.metadata[0].name
  }

  data = {
    username = "git"
    password = var.github_token
  }

  type = "kubernetes.io/basic-auth"

  depends_on = [kubernetes_namespace.flux_system]
}

# Install Flux using Helm
resource "helm_release" "flux2" {
  name       = "flux2"
  repository = "https://fluxcd.io"
  chart      = "flux2"
  namespace  = kubernetes_namespace.flux_system.metadata[0].name
  version    = "2.2.0"

  set {
    name  = "gitRepository.url"
    value = "https://github.com/${var.github_owner}/${var.github_repo}"
  }

  set {
    name  = "gitRepository.secretRef"
    value = "flux-github-token"
  }

  depends_on = [
    kubernetes_namespace.flux_system,
    kubernetes_secret.flux_github
  ]
}

# Install Weave GitOps
resource "helm_release" "weave_gitops" {
  name       = "weave-gitops"
  repository = "https://charts.weave.works"
  chart      = "weave-gitops"
  namespace  = kubernetes_namespace.weave_gitops.metadata[0].name
  version    = "4.0.0"

  set {
    name  = "flux.enabled"
    value = "true"
  }

  set {
    name  = "adminUser.create"
    value = "true"
  }

  set {
    name  = "adminUser.username"
    value = "admin"
  }

  # Use the plain password - Weave GitOps will handle hashing internally
  set_sensitive {
    name  = "adminUser.passwordHash"
    value = random_password.admin_password.result
  }

  depends_on = [
    kubernetes_namespace.weave_gitops,
    helm_release.flux2
  ]
}

# Generate admin password for Weave
resource "random_password" "admin_password" {
  length  = 16
  special = true
}

# Output
output "weave_gitops_admin_password" {
  value       = random_password.admin_password.result
  sensitive   = true
  description = "Weave GitOps admin password"
}

output "weave_gitops_namespace" {
  value       = kubernetes_namespace.weave_gitops.metadata[0].name
  description = "Weave GitOps namespace"
}

output "flux_namespace" {
  value       = kubernetes_namespace.flux_system.metadata[0].name
  description = "Flux namespace"
}
