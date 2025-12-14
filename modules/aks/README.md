# AKS Module

This module deploys a complete Azure Kubernetes Service (AKS) cluster with supporting infrastructure.

## Features

- AKS cluster with configurable SKU tier
- System and user node pools with auto-scaling support
- Container Registry (ACR) integration
- Key Vault with CSI driver support
- Private endpoints for Key Vault
- Jumpbox VM with pre-installed tools
- Azure Bastion for secure access
- VPN Gateway with Point-to-Site configuration
- Cost analysis tracking
- Bootstrap profile support

## Usage

```hcl
module "aks" {
  for_each = var.clusters
  
  source = "./modules/aks"
  
  location            = var.location
  subscription_name   = var.subscription_name
  region_codes        = var.region_codes
  tags                = var.tags
  
  # Network configuration
  address_space     = each.value.address_space
  network_subnets   = each.value.network_subnets
  
  # AKS configuration
  enable_aks            = each.value.enable_aks
  aks_sku_tier          = each.value.aks_sku_tier
  aks_identity_type     = each.value.aks_identity_type
  aks_network           = each.value.aks_network
  aks_node_pool         = each.value.aks_node_pool
  aks_user_node_pools   = each.value.aks_user_node_pools
  
  # Additional features
  enable_container_registry          = each.value.enable_container_registry
  enable_key_vault                   = each.value.enable_key_vault
  enable_jumpbox_vm                  = each.value.enable_jumpbox_vm
  enable_bastion                     = each.value.enable_bastion
  enable_aks_kv_csi_driver           = each.value.enable_aks_kv_csi_driver
  aks_cost_analysis_enabled          = each.value.aks_cost_analysis_enabled
  aks_bootstrap_profile              = each.value.aks_bootstrap_profile
}
```
