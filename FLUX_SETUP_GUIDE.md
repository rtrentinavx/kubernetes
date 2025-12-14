# Flux + Weave GitOps Setup Guide

This guide walks you through setting up Flux and Weave GitOps on your AKS cluster using the GitHub token stored securely in Azure Key Vault.

## Prerequisites

- AKS cluster deployed (via `terraform apply`)
- GitHub account with token creation access
- Azure CLI installed and authenticated
- Terraform configured for your AKS workspace

## Step 1: Create GitHub Token

1. Go to https://github.com/settings/tokens
2. Click "Generate new token" → "Generate new token (classic)"
3. Give it a name like `flux-gitops`
4. Grant these scopes:
   - `repo` (full control of private repositories)
   - `read:user` (read user data)
5. Copy the token (you won't see it again)

## Step 2: Create GitHub Repository for GitOps

Create a new GitHub repository for your Kubernetes configuration files:
- Name: `your-gitops-repo` (update in main.tf)
- Visibility: Private recommended
- Initialize with README

Example structure:
```
your-gitops-repo/
├── README.md
└── clusters/
    └── production/
        ├── apps/
        └── infrastructure/
```

## Step 3: Store GitHub Token in Key Vault

Get your Key Vault name from the Terraform output:

```bash
terraform output production
```

Store the GitHub token:

```bash
VAULT_NAME=$(terraform output -raw production | grep -oP 'key_vault_name = "\K[^"]*')
GITHUB_TOKEN="your-github-token-here"

az keyvault secret set \
  --vault-name $VAULT_NAME \
  --name github-token \
  --value $GITHUB_TOKEN
```

Verify it was stored:

```bash
az keyvault secret show \
  --vault-name $VAULT_NAME \
  --name github-token
```

## Step 4: Update Configuration

Edit `/Users/ricardotrentin/Documents/2025/kuburnetes/aks/main.tf`:

Find the `locals` block and update:

```terraform
locals {
  # ... other config ...
  
  # GitHub configuration for Flux
  github_owner = "your-actual-github-org"      # Your GitHub org/user
  github_repo  = "your-actual-gitops-repo"      # Your repo name
  github_token_secret_name = "github-token"     # Keep as is (secret in KV)
}
```

## Step 5: Deploy Flux and Weave GitOps

```bash
cd /Users/ricardotrentin/Documents/2025/kuburnetes/aks

# Initialize Terraform (if needed)
terraform init

# Plan the deployment
terraform plan

# Apply - this will deploy Flux and Weave GitOps to your AKS cluster
terraform apply
```

## Step 6: Access Weave GitOps Dashboard

Wait for the deployment to complete, then:

```bash
# Get the admin password from Terraform output
ADMIN_PASSWORD=$(terraform output -json flux_weave_info | jq -r '.weave_gitops_admin_password')

# Port forward to the Weave GitOps service
kubectl port-forward -n weave-gitops svc/weave-gitops 3000:3000 &

# Open browser
open http://localhost:3000
```

**Login with:**
- Username: `admin`
- Password: (from output above)

## Step 7: Configure Flux to Sync Your Repository

In Weave GitOps dashboard or via CLI:

```bash
# Verify Flux is running
kubectl get pods -n flux-system

# Check Flux source (GitHub repo)
flux get sources git

# View reconciliation status
flux get kustomizations
```

## Using Flux for GitOps

Now you can manage your Kubernetes resources by:

1. Creating YAML files in your GitHub repo
2. Pushing to main branch
3. Flux automatically detects and applies changes to your cluster
4. Monitor sync status in Weave GitOps dashboard

Example: Create `clusters/production/apps/nginx.yaml`:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: nginx
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  namespace: nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
```

Then create a Flux `Kustomization` in your repo to deploy it:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: apps
  namespace: flux-system
spec:
  interval: 10m0s
  path: ./clusters/production/apps
  prune: true
  sourceRef:
    kind: GitRepository
    name: flux-system
    namespace: flux-system
```

Push and Flux will auto-deploy!

## Troubleshooting

### GitHub token not syncing
```bash
# Check if secret was created
kubectl get secret -n flux-system flux-github-token

# View sync error
flux get sources git -n flux-system
flux describe source git flux-system -n flux-system
```

### Weave GitOps not accessible
```bash
# Check if pod is running
kubectl get pods -n weave-gitops

# Check logs
kubectl logs -n weave-gitops deploy/weave-gitops
```

### Flux reconciliation failing
```bash
# View detailed status
flux get all -n flux-system

# Check specific resource
flux describe kustomization <name> -n flux-system
```

## References

- [Flux Documentation](https://fluxcd.io/docs/)
- [Weave GitOps Documentation](https://docs.gitops.weave.works/)
- [GitHub Token Permissions](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)
