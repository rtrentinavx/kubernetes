#!/bin/bash
# Deploy Flux to AKS cluster
# Run this AFTER: terraform apply (from aks directory)

set -e

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$SCRIPT_DIR"

echo "🚀 Deploying Flux + Weave GitOps to AKS cluster..."

# Get AKS cluster credentials
echo "📝 Getting AKS cluster credentials..."
CLUSTER_NAME=$(cd ../aks && terraform output -json production | jq -r '.aks_cluster_name')
RESOURCE_GROUP=$(az resource show --ids /subscriptions/47ab116c-8c15-4453-b06a-3fecd09ebda9/resourceGroups/rg-eus-9ff5-aks --query name -o tsv 2>/dev/null || echo "rg-eus-9ff5-aks")

az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --overwrite-existing

# Verify cluster connection
echo "✅ Verifying cluster connection..."
kubectl cluster-info || { echo "❌ Failed to connect to cluster"; exit 1; }

# Initialize Terraform
echo "📦 Initializing Terraform..."
terraform init

# Plan deployment
echo "📋 Planning Flux deployment..."
terraform plan -out=tfplan

# Apply deployment
echo "🔧 Deploying Flux and Weave GitOps..."
terraform apply tfplan

echo "✅ Flux deployment complete!"
echo ""
echo "📊 Access Weave GitOps dashboard:"
echo "   kubectl port-forward -n weave-gitops svc/weave-gitops 3000:3000"
echo "   Then open: http://localhost:3000"
echo ""
echo "📝 Check Flux status:"
echo "   flux get all -n flux-system"
echo ""
