#################################################################################
# DATA SOURCES
#################################################################################

data "azurerm_subscription" "current" {}

data "azurerm_client_config" "current" {}

# Get the public IP of the machine running Terraform
data "http" "terraform_runner_ip" {
  url = "https://api.ipify.org"
}

#################################################################################
# LOCALS
#################################################################################

locals {
  subscription_id = "47ab116c-8c15-4453-b06a-3fecd09ebda9"
  location          = "eastus"
  region_codes = {
    eastus      = "eus"
    westus      = "wus"
    westeurope  = "weu"
    eastus2     = "eus2"
    centralus   = "cus"
    southcentralus = "scs"
  }
  common_tags = {
    environment = "production"
    managed_by  = "terraform"
  }
  
  # GitHub configuration for Flux
  github_owner = "rtrentinavx" 
  github_repo  = "k8sfluxops"
  github_token_secret_name = "flux-github-token"
  
  # Get Terraform runner's public IP and add /32 CIDR
  terraform_runner_ip = "${chomp(data.http.terraform_runner_ip.response_body)}/32"
  
  # API server authorized IP ranges: include Terraform runner + Bastion subnet
  api_server_authorized_ips = concat(
    ["${local.terraform_runner_ip}"],
    ["10.10.100.0/27"]
  )
}

module "aks_production" {
  source = "../modules/aks"

  location          = local.location
  subscription_id   = local.subscription_id
  region_codes      = local.region_codes
  tags              = merge(local.common_tags, { cluster_name = "production" })

  # Network configuration
  address_space = ["10.10.0.0/16"]
  network_subnets = {
    standard = {
      mgmt     = "10.10.0.0/24"
      workload = "10.10.1.0/24"
    }
    aks = {
      nodes      = "10.10.8.0/22"
      user_pools = {}
    }
    bastion   = "10.10.100.0/27"
    gateway   = "10.10.200.0/27"
    endpoints = "10.10.250.0/27"
  }

  # AKS configuration
  enable_aks            = true
  aks_sku_tier          = "Free"
  aks_identity_type     = "SystemAssigned"
  aks_cost_analysis_enabled = false

  aks_network = {
    dns_service_ip      = "10.2.0.10"
    service_cidr        = "10.2.0.0/24"
    outbound_type       = "loadBalancer"
    network_plugin_mode = "overlay"
    network_data_plane  = "cilium"
  }

  aks_node_pool = {
    vm_size         = "Standard_DS3_v2"
    node_count      = 3
    max_pods        = 30
    os_disk_size_gb = 128
  }

  aks_user_node_pools = {}
  api_server_authorized_ip_ranges = local.api_server_authorized_ips

  # Container Registry
  enable_container_registry = true
  container_registry_sku    = "Standard"

  # Key Vault
  enable_key_vault                   = true
  key_vault_sku_name                 = "standard"
  key_vault_purge_protection_enabled = false
  key_vault_soft_delete_retention_days = 7
  key_vault_enable_rbac              = true
  kv_secret_name_private             = "jumpbox-ssh-private-key"
  kv_secret_name_public              = "jumpbox-ssh-public-key"

  # Jumpbox
  enable_jumpbox_vm           = true
  jumpbox_subnet_name         = "workload"
  jumpbox_admin_username      = "azureuser"
  jumpbox_admin_ssh_key       = ""
  jumpbox_vm_size             = "Standard_B2ms"
  jumpbox_os_disk_type        = "StandardSSD_LRS"
  jumpbox_public_ip_sku       = "Standard"
  ssh_key_algorithm           = "RSA"
  ssh_key_rsa_bits            = 4096

  # Bastion
  enable_bastion         = false
  bastion_public_ip_sku  = "Standard"

  # VPN
  enable_vpn_gateway         = false
  vpngw_client_configuration = null

  # AKS features
  enable_aks_kv_csi_driver = true
  aks_bootstrap_profile    = null
}

# Uncomment to deploy additional clusters
# module "aks_staging" {
#   source = "../modules/aks"
#   
#   location          = local.location
#   subscription_name = local.subscription_name
#   subscription_id   = data.azurerm_subscription.current.subscription_id
#   region_codes      = local.region_codes
#   tags              = merge(local.common_tags, { cluster_name = "staging" })
#   
#   address_space = ["10.20.0.0/16"]
#   network_subnets = {
#     standard = {
#       mgmt     = "10.20.0.0/24"
#       workload = "10.20.1.0/24"
#     }
#     aks = {
#       nodes      = "10.20.8.0/22"
#       user_pools = {}
#     }
#     bastion   = "10.20.100.0/27"
#     gateway   = "10.20.200.0/27"
#     endpoints = "10.20.250.0/27"
#   }
#   
#   aks_sku_tier                       = "Free"
#   aks_identity_type                  = "SystemAssigned"
#   aks_cost_analysis_enabled          = false
#   enable_aks                         = true
#   
#   aks_network = {
#     dns_service_ip      = "10.3.0.10"
#     service_cidr        = "10.3.0.0/24"
#     outbound_type       = "loadBalancer"
#     network_plugin_mode = "overlay"
#     network_data_plane  = "cilium"
#   }
#   
#   aks_node_pool = {
#     vm_size         = "Standard_DS3_v2"
#     node_count      = 2
#     max_pods        = 30
#     os_disk_size_gb = 128
#   }
#   
#   aks_user_node_pools             = {}
#   api_server_authorized_ip_ranges = []
#   enable_container_registry       = true
#   container_registry_sku          = "Standard"
#   enable_key_vault                = true
#   key_vault_sku_name              = "standard"
#   enable_jumpbox_vm               = true
#   jumpbox_subnet_name             = "workload"
#   enable_bastion                  = false
#   enable_vpn_gateway              = false
#   vpngw_client_configuration      = null
#   enable_aks_kv_csi_driver        = true
#   aks_bootstrap_profile           = null
# }

#################################################################################
# FLUX + WEAVE GITOPS
#################################################################################

# Read GitHub token from Key Vault
# data "azurerm_key_vault_secret" "github_token" {
#   name         = local.github_token_secret_name
#   key_vault_id = module.aks_production.key_vault_id
# }

# Note: Flux deployment requires:
# 1. GitHub token stored in Key Vault with name: flux-github-token
# 2. GitHub repository: https://github.com/rtrentinavx/k8sfluxops
# 3. Deploy Flux separately after AKS cluster is ready
#
# Deploy Flux with this separate Terraform module:
# cd ../flux && terraform init && terraform apply
#
# For now, this module is commented out to avoid Kubernetes auth issues during planning
# Uncomment after the cluster is deployed and kubeconfig is configured

# module "flux_weave" {
#   source = "../modules/flux-weave"
#   
#   kubeconfig_path = "~/.kube/config"
#   kubeconfig_context = module.aks_production.aks_cluster_name
#   
#   github_token = data.azurerm_key_vault_secret.github_token.value
#   github_owner = local.github_owner
#   github_repo  = local.github_repo
#   
#   flux_namespace   = "flux-system"
#   weave_namespace  = "weave-gitops"
# }

#################################################################################
# OUTPUTS
#################################################################################

output "production" {
  value = {
    aks_cluster_name              = try(module.aks_production.aks_cluster_name, null)
    container_registry_name       = try(module.aks_production.container_registry_name, null)
    container_registry_login_server = try(module.aks_production.container_registry_login_server, null)
    key_vault_name                = try(module.aks_production.key_vault_name, null)
    key_vault_uri                 = try(module.aks_production.key_vault_uri, null)
    key_vault_id                  = try(module.aks_production.key_vault_id, null)
    bastion_public_ip             = try(module.aks_production.bastion_public_ip, null)
  }
  description = "Production cluster outputs"
}

# Uncomment after deploying flux_weave module
# output "flux_weave_info" {
#   value = {
#     flux_namespace         = try(module.flux_weave.flux_namespace, null)
#     weave_gitops_namespace = try(module.flux_weave.weave_gitops_namespace, null)
#     weave_admin_password   = try(module.flux_weave.weave_gitops_admin_password, null)
#   }
#   description = "Flux and Weave GitOps information"
#   sensitive   = true
# }

#################################################################################
# UPDATE KUBECONFIG AFTER AKS DEPLOYMENT
#################################################################################

# Automatically get credentials and update kubeconfig after successful deployment
resource "null_resource" "update_kubeconfig" {
  depends_on = [module.aks_production]

  provisioner "local-exec" {
    command = "az aks get-credentials --resource-group ${module.aks_production.resource_group_aks} --name ${module.aks_production.aks_cluster_name} --overwrite-existing && echo '✅ Kubeconfig updated successfully'"
  }

  triggers = {
    cluster_id = module.aks_production.aks_acr_attachment_token_id
  }
}

output "next_steps" {
  value = <<-EOT
    ✅ AKS Cluster deployed successfully!
    
    Your kubeconfig has been automatically updated.
    
    🌐 Terraform runner IP authorized: ${local.terraform_runner_ip}
    
    📝 Verify cluster connection:
       kubectl cluster-info
       kubectl get nodes
    
    🔑 Access cluster credentials:
       kubectl config current-context
    
    🚀 Next: Deploy Flux + Weave GitOps
       cd flux
       terraform init
       terraform apply
       
    Or run the automated script:
       chmod +x flux/deploy.sh
       flux/deploy.sh
  EOT
  description = "Next steps after AKS deployment"
}