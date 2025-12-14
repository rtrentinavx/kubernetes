#!/bin/bash
set -e

# Log output
exec > >(tee /var/log/jumpbox_init.log)
exec 2>&1

echo "Starting jumpbox initialization..."

# Update system packages
apt-get update
apt-get upgrade -y

# Install prerequisites
apt-get install -y \
  curl \
  wget \
  git \
  vim \
  htop \
  jq \
  unzip \
  ca-certificates \
  apt-transport-https \
  gnupg \
  lsb-release

# Install Azure CLI
echo "Installing Azure CLI..."
curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Install kubectl
echo "Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/

# Install Helm
echo "Installing Helm..."
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install kubelogin
echo "Installing kubelogin..."
KUBELOGIN_VERSION=$(curl -s https://api.github.com/repos/Azure/kubelogin/releases/latest | jq -r '.tag_name' | sed 's/v//')
wget "https://github.com/Azure/kubelogin/releases/download/v${KUBELOGIN_VERSION}/kubelogin-linux-amd64.zip"
unzip kubelogin-linux-amd64.zip
chmod +x ./kubelogin
mv ./kubelogin /usr/local/bin/
rm kubelogin-linux-amd64.zip

# Install Terraform (optional but useful)
echo "Installing Terraform..."
TERRAFORM_VERSION=$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | jq -r '.tag_name' | sed 's/v//')
wget "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
unzip "terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
chmod +x terraform
mv terraform /usr/local/bin/
rm "terraform_${TERRAFORM_VERSION}_linux_amd64.zip"

# Install az aks install-cli (adds kubectl via az)
echo "Installing AKS CLI tools..."
az aks install-cli

echo "Jumpbox initialization completed successfully!"

