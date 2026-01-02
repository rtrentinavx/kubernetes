# Flux v2 + Weave GitOps Deployment for GKE

This directory contains Terraform configurations to deploy **Flux v2** and **Weave GitOps** as an alternative to ArgoCD on Google Kubernetes Engine (GKE).

## Overview

**Flux v2** is a modern, declarative GitOps solution that keeps your cluster configuration synchronized with your Git repository. **Weave GitOps** provides a beautiful web UI for managing and monitoring Flux deployments.

### Key Features

- ✅ **Flux v2** - Lightweight, extensible GitOps toolkit
- ✅ **Weave GitOps** - Web UI for Flux management and visualization
- ✅ **Automatic Git Sync** - Continuously synchronize cluster state with Git
- ✅ **GitHub Token Auth** - Secure Git repository access
- ✅ **Kustomization Support** - Native support for Kustomize-based deployments
- ✅ **Static Load Balancer IP** - Reserved external IP for Weave GitOps UI
- ✅ **GCS State Backend** - Terraform state stored in Google Cloud Storage

## Prerequisites

1. **GKE Cluster**: An existing, running GKE cluster
2. **kubectl**: Configured to access your GKE cluster
3. **Terraform**: Version 1.5.0 or higher
4. **GitHub**: A repository containing your GitOps configurations
5. **GitHub PAT**: Personal Access Token with `repo` and `read:org` scopes
6. **gcloud CLI**: Authenticated with your GCP project

## Quick Start

### 1. Copy and Configure Variables

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your specific values:

```hcl
# Kubernetes context from your kubeconfig
config_context = "gke_YOUR_PROJECT_us-east1_CLUSTER_NAME"

# GCP settings
project = "your-gcp-project-id"
region  = "us-east1"

# GitHub configuration
github_token = "ghp_your_personal_access_token"
github_owner = "your-github-org"
github_repo  = "your-gitops-repo"

# Repository path where Flux will look for manifests
gitops_repo_path = "applications/"
gitops_repo_branch = "main"
```

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Plan Deployment

```bash
terraform plan -out=tfplan
```

### 4. Apply Configuration

```bash
terraform apply tfplan
```

### 5. Wait for Deployment

Monitor the deployment:

```bash
# Watch Flux deployment
kubectl -n flux-system get pods -w

# Watch Weave GitOps deployment
kubectl -n weave-gitops get pods -w
```

### 6. Access Weave GitOps UI

After successful deployment, retrieve the access URL and admin password:

```bash
# Get the Weave GitOps URL
terraform output weave_access_url

# Get the admin password (save this securely!)
terraform output -raw weave_admin_password
```

**Default username**: `admin`

Then visit the URL in your browser and log in with your admin credentials.

## Directory Structure

```
gke/flux/
├── main.tf                      # Flux v2 and Weave GitOps deployment
├── variables.tf                 # Input variables
├── output.tf                    # Output values
├── data.tf                      # Data sources and locals
├── providers.tf                 # Terraform and provider configuration
├── terraform.tfvars.example     # Example variable values
├── terraform.tfstate            # Terraform state (generated after apply)
├── terraform.tfstate.backup     # Backup of Terraform state
└── .terraform/                  # Terraform working directory
```

## Configuration Details

### Input Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `kubeconfig_path` | `~/.kube/config` | Path to kubeconfig file |
| `config_context` | `""` | Kubernetes context to use |
| `project` | Required | GCP project ID |
| `region` | Required | GCP region |
| `flux_namespace` | `flux-system` | Namespace for Flux components |
| `weave_namespace` | `weave-gitops` | Namespace for Weave GitOps |
| `flux_chart_version` | `2.2.0` | Flux Helm chart version |
| `weave_chart_version` | `4.0.0` | Weave GitOps Helm chart version |
| `github_token` | Required | GitHub Personal Access Token (sensitive) |
| `github_owner` | Required | GitHub organization/user |
| `github_repo` | Required | GitHub repository name |
| `gitops_repo_path` | `./` | Path within repo for configurations |
| `gitops_repo_branch` | `main` | Git branch to sync from |
| `weave_admin_password_length` | `16` | Length of auto-generated password |
| `enable_notifications` | `false` | Enable Flux notifications |

### Outputs

| Output | Description |
|--------|-------------|
| `flux_namespace` | Kubernetes namespace where Flux is installed |
| `weave_namespace` | Kubernetes namespace where Weave GitOps is installed |
| `weave_admin_password` | Auto-generated admin password (sensitive) |
| `weave_lb_ip` | Static external IP for Weave GitOps LoadBalancer |
| `weave_access_url` | URL to access Weave GitOps UI |
| `flux_git_repo_name` | Name of the Flux GitRepository source |
| `flux_git_repo_url` | GitHub repository URL |
| `flux_kustomization_name` | Name of the Flux Kustomization |
| `next_steps` | Post-deployment instructions |

## Managing Flux

### Monitor Flux Reconciliation

```bash
# Check GitRepository synchronization status
kubectl -n flux-system get gitrepository

# Check Kustomization reconciliation status
kubectl -n flux-system get kustomization

# View detailed status
kubectl -n flux-system describe gitrepository
kubectl -n flux-system describe kustomization
```

### View Flux Events

```bash
kubectl -n flux-system get events --sort-by='.lastTimestamp'
```

### Force Reconciliation

```bash
# Manually trigger Flux to reconcile
flux reconcile source git <repo-name> -n flux-system
flux reconcile kustomization <kustomization-name> -n flux-system
```

### Check Flux Status

```bash
# Get overall Flux status
flux status

# Detailed status with all resources
flux status --verbose
```

### Update Flux Configuration

To update configurations in your Git repository:

1. Push changes to your GitHub repository
2. Flux will automatically detect and apply changes (within 1 minute)
3. Monitor progress in Weave GitOps UI or via `kubectl`

## Troubleshooting

### Pods Not Starting

```bash
# Check Flux system logs
kubectl -n flux-system logs -l app=source-controller
kubectl -n flux-system logs -l app=kustomize-controller

# Check Weave GitOps logs
kubectl -n weave-gitops logs -l app=weave-gitops
```

### Git Authentication Issues

Verify the GitHub token is configured correctly:

```bash
# Check the secret in the cluster
kubectl -n flux-system get secret flux-system -o yaml

# Ensure the token has correct permissions:
# - repo: Read and write access to repositories
# - read:org: Read organization data
```

### Reconciliation Not Working

```bash
# Check GitRepository status
kubectl -n flux-system describe gitrepository

# Check Kustomization status
kubectl -n flux-system describe kustomization

# View events for more details
kubectl -n flux-system get events --field-selector involvedObject.name=<repo-name>
```

### Weave GitOps Not Accessible

```bash
# Verify the service is running
kubectl -n weave-gitops get service weave-gitops

# Check for external IP assignment
kubectl -n weave-gitops describe service weave-gitops

# View pod status
kubectl -n weave-gitops get pods
```

## Comparing with ArgoCD

| Aspect | Flux v2 | ArgoCD |
|--------|---------|--------|
| **Architecture** | Decentralized, stateless | Centralized with state |
| **UI** | Weave GitOps (optional add-on) | Built-in web UI |
| **Learning Curve** | Lighter, more Kubernetes-native | Steeper learning curve |
| **Package Management** | Helm Charts via Flux/Helm controller | Helm integration |
| **Customization** | Kustomize, Helm, raw manifests | Kustomize, Helm, jsonnet |
| **Resource Overhead** | Minimal (~100m CPU, 64Mi RAM) | Higher (~500m CPU, 256Mi RAM) |
| **Community** | CNCF graduated project | Vibrant community, ArgoprojectCI/CD |

Both are excellent GitOps solutions. Choose based on your team's preference and requirements.

## Updating Flux and Weave GitOps

To update the Helm chart versions:

```bash
# Edit terraform.tfvars
flux_chart_version = "2.3.0"
weave_chart_version = "4.1.0"

# Plan and apply changes
terraform plan
terraform apply
```

## Cleanup

To remove Flux v2 and Weave GitOps from your cluster:

```bash
terraform destroy
```

This will:
- Remove all Flux components from `flux-system` namespace
- Remove Weave GitOps from `weave-gitops` namespace
- Delete the reserved static IP address
- Remove Terraform state

**Note**: This does NOT delete deployed applications. Applications created by Flux will remain on the cluster.

## Additional Resources

- [Flux v2 Documentation](https://fluxcd.io/docs/)
- [Weave GitOps Documentation](https://docs.weave.works/docs/gitops/)
- [GitHub Token Management](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens)
- [GKE Networking](https://cloud.google.com/kubernetes-engine/docs/concepts/network)

## Support

For issues or questions:

1. Check [Flux GitHub Issues](https://github.com/fluxcd/flux2/issues)
2. Check [Weave GitOps Issues](https://github.com/weaveworks/weave-gitops/issues)
3. Review Terraform error messages and check provider documentation
4. Check Kubernetes events: `kubectl get events -A --sort-by='.lastTimestamp'`

## License

This Terraform configuration is provided as-is for use with GKE and Flux v2.
