#!/bin/bash
# Script to retrieve ArgoCD admin credentials

set -e

echo "=== ArgoCD Credentials Retrieval ==="
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl not found. Please install kubectl first."
    exit 1
fi

# Check ArgoCD namespace
ARGOCD_NS="argocd"
if ! kubectl get namespace $ARGOCD_NS &> /dev/null; then
    echo "Error: ArgoCD namespace '$ARGOCD_NS' not found."
    echo "Please ensure ArgoCD is installed or specify the correct namespace."
    exit 1
fi

echo "Found ArgoCD namespace: $ARGOCD_NS"
echo ""

# Get ArgoCD server address
echo "1. ArgoCD Server Address:"
ARGOCD_SERVER=$(kubectl get svc argocd-server -n $ARGOCD_NS -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
if [ -z "$ARGOCD_SERVER" ]; then
    ARGOCD_SERVER=$(kubectl get svc argocd-server -n $ARGOCD_NS -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
fi

if [ -n "$ARGOCD_SERVER" ]; then
    echo "   Server: $ARGOCD_SERVER:443"
else
    echo "   LoadBalancer IP not yet assigned. Check with:"
    echo "   kubectl get svc argocd-server -n $ARGOCD_NS"
fi
echo ""

# Get admin username (always 'admin')
echo "2. Admin Username: admin"
echo ""

# Get admin password
echo "3. Admin Password:"
PASSWORD=$(kubectl get secret argocd-initial-admin-secret -n $ARGOCD_NS -o jsonpath="{.data.password}" 2>/dev/null | base64 -d 2>/dev/null || echo "")

if [ -n "$PASSWORD" ]; then
    echo "   $PASSWORD"
else
    echo "   Secret not found. The password may have been changed or deleted."
    echo "   To reset the password, run:"
    echo "   argocd account update-password"
fi
echo ""

# Export as environment variable
if [ -n "$PASSWORD" ]; then
    echo "4. To use with Terraform:"
    echo "   export TF_VAR_argocd_password='$PASSWORD'"
    echo "   export TF_VAR_argocd_server='$ARGOCD_SERVER:443'"
fi
echo ""

echo "=== Done ==="
