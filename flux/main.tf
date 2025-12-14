# Get AKS cluster info from parent directory
data "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-eus-9ff5"
  resource_group_name = "rg-eus-9ff5-aks"
}

# Get GitHub token from Key Vault
data "azurerm_key_vault_secret" "github_token" {
  name         = "flux-github-token"
  key_vault_id = data.azurerm_key_vault.kv.id
}

data "azurerm_key_vault" "kv" {
  name                = "kveus9ff5"
  resource_group_name = "rg-eus-9ff5-core"
}

# Create flux-system namespace
resource "kubernetes_namespace" "flux_system" {
  metadata {
    name = "flux-system"
  }
}

# Create weave-gitops namespace
resource "kubernetes_namespace" "weave_gitops" {
  metadata {
    name = "weave-gitops"
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
    password = data.azurerm_key_vault_secret.github_token.value
  }

  type = "kubernetes.io/basic-auth"
}

# Install Flux v2 using Helm
resource "helm_release" "flux2" {
  name       = "flux2"
  repository = "https://fluxcd.io"
  chart      = "flux2"
  namespace  = kubernetes_namespace.flux_system.metadata[0].name
  version    = "2.2.0"

  set {
    name  = "gitRepository.url"
    value = "https://github.com/rtrentinavx/k8sfluxops"
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

# Generate admin password for Weave
resource "random_password" "admin_password" {
  length  = 16
  special = true
}

# Install Weave GitOps using Helm
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

  set_sensitive {
    name  = "adminUser.passwordHash"
    value = random_password.admin_password.result
  }

  depends_on = [
    kubernetes_namespace.weave_gitops,
    helm_release.flux2
  ]
}

# Output
output "flux_namespace" {
  value       = kubernetes_namespace.flux_system.metadata[0].name
  description = "Flux namespace"
}

output "weave_gitops_namespace" {
  value       = kubernetes_namespace.weave_gitops.metadata[0].name
  description = "Weave GitOps namespace"
}

output "weave_admin_password" {
  value       = random_password.admin_password.result
  sensitive   = true
  description = "Weave GitOps admin password"
}

output "access_weave_gitops" {
  value = "kubectl port-forward -n weave-gitops svc/weave-gitops 3000:3000"
  description = "Command to access Weave GitOps dashboard at http://localhost:3000"
}
