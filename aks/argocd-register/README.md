# Register AKS Cluster to ArgoCD

This Terraform configuration registers your AKS cluster to an existing ArgoCD instance using kubeconfig.

## Features

- **Auto-detection**: Automatically retrieves ArgoCD server address and admin password from the cluster where ArgoCD is installed
- **Manual mode**: Option to provide credentials manually if needed
- **Multi-cluster support**: Can register clusters from different cloud providers to ArgoCD

## Prerequisites

1. AKS cluster is deployed and running
2. Kubeconfig is configured with AKS credentials (run `az aks get-credentials`)
3. ArgoCD is installed and accessible (e.g., on GKE)
4. Kubeconfig has context for ArgoCD cluster

## Usage

### Option 1: Auto-detect ArgoCD credentials (Recommended)

1. Get AKS credentials:
```bash
az aks get-credentials --resource-group rg-eastus-9ff5-aks --name aks-eastus-9ff5
```

2. Get GKE credentials (where ArgoCD is installed):
```bash
gcloud container clusters get-credentials <gke-cluster> --region <region> --project <project>
```

3. Copy and edit the tfvars file:
```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:
```hcl
auto_detect_argocd        = true
argocd_kubeconfig_context = "gke_project_region_cluster"  # Your GKE context
kubeconfig_context        = "aks-eastus-9ff5"             # Your AKS context
cluster_name_in_argocd    = "aks-eastus"
```

4. Initialize and apply:
```bash
terraform init
terraform plan
terraform apply
```

### Option 2: Manual credentials

Set `auto_detect_argocd = false` in terraform.tfvars and provide:
```hcl
auto_detect_argocd = false
argocd_server      = "35.123.45.67:443"
argocd_username    = "admin"
argocd_password    = "your-password"
```

## Get ArgoCD Credentials

### Option 1: Use the helper script
```bash
./get-argocd-credentials.sh
```

### Option 2: Manual retrieval

**Username:** `admin` (default)

**Password:** Get from Kubernetes secret:
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

**Server Address:** Get LoadBalancer IP/hostname:
```bash
kubectl get svc argocd-server -n argocd
```

### If ArgoCD is on GKE
Switch to your GKE cluster context first:
```bash
kubectl config use-context <gke-context-name>
./get-argocd-credentials.sh
```

## Verify Registration

After applying, verify in ArgoCD UI or CLI:
```bash
argocd cluster list
```
