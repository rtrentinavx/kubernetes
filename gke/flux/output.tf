output "flux_namespace" {
  value       = kubernetes_namespace_v1.flux_system.metadata[0].name
  description = "Kubernetes namespace where Flux is installed"
}

output "weave_namespace" {
  value       = kubernetes_namespace_v1.weave_gitops.metadata[0].name
  description = "Kubernetes namespace where Weave GitOps is installed"
}

output "weave_admin_password" {
  value       = random_password.weave_admin_password.result
  sensitive   = true
  description = "Auto-generated admin password for Weave GitOps UI (username: admin)"
}

output "weave_access_instructions" {
  value = "kubectl port-forward -n ${kubernetes_namespace_v1.weave_gitops.metadata[0].name} svc/weave-gitops 9001:80"
  description = "Command to access Weave GitOps UI via port-forward"
}

# output "flux_git_repo_name" {
#   value       = kubernetes_manifest.flux_git_repo.manifest.metadata.name
#   description = "Name of the Flux GitRepository source"
# }

output "flux_git_repo_url" {
  value       = "https://github.com/${var.github_owner}/${var.github_repo}.git"
  description = "GitHub repository URL configured for Flux synchronization"
}

# output "flux_kustomization_name" {
#   value       = kubernetes_manifest.flux_kustomization.manifest.metadata.name
#   description = "Name of the Flux Kustomization for GitOps"
# }

output "next_steps" {
  value = <<-EOT
Flux v2 and Weave GitOps have been deployed successfully!

1. Access Weave GitOps UI:
   kubectl port-forward -n ${kubernetes_namespace_v1.weave_gitops.metadata[0].name} svc/weave-gitops 9001:80
   URL:      http://localhost:9001
   Username: admin
   Password: (shown in 'weave_admin_password' output - save this securely!)

2. Flux will begin syncing from:
   Repository: https://github.com/${var.github_owner}/${var.github_repo}.git
   Branch:     ${var.gitops_repo_branch}
   Path:       ${var.gitops_repo_path}

3. Monitor Flux reconciliation:
   kubectl -n ${kubernetes_namespace_v1.flux_system.metadata[0].name} get gitrepository
   kubectl -n ${kubernetes_namespace_v1.flux_system.metadata[0].name} get kustomization

4. View Flux events:
   kubectl -n ${kubernetes_namespace_v1.flux_system.metadata[0].name} get events --sort-by='.lastTimestamp'

5. Check Weave GitOps service status:
   kubectl -n ${kubernetes_namespace_v1.weave_gitops.metadata[0].name} get service weave-gitops
  EOT
  description = "Instructions for accessing and managing Flux and Weave GitOps"
}
