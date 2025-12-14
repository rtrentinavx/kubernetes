
variable "address_space" {
  description = "The address space that will be used by the Virtual Network."
  type        = list(string)
}

variable "network_subnets" {
  description = "Network subnet configuration. Includes standard subnets, AKS subnets, and special subnets."
  type = object({
    standard = optional(map(string), {})
    aks = object({
      nodes      = string
      user_pools = optional(map(string), {})
    })
    bastion   = optional(string)
    gateway   = optional(string)
    endpoints = optional(string)
  })
}


variable "aks_network" {
  description = "Network configuration for the AKS cluster."
  type = object({
    dns_service_ip      = string
    service_cidr        = string
    outbound_type       = string
    network_plugin_mode = optional(string, "overlay")
    network_data_plane  = optional(string, "cilium")
  })
}

variable "aks_node_pool" {
  description = "Configuration for the default AKS node pool."
  type = object({
    name            = optional(string)
    vm_size         = string
    node_count      = number
    max_pods        = number
    os_disk_size_gb = number
  })
}

variable "aks_user_node_pools" {
  description = "Configuration for user AKS node pools. Subnets are defined in network_subnets.aks.user_pools."
  type = map(object({
    name                  = optional(string)
    vm_size               = string
    node_count            = number
    max_pods              = number
    os_disk_size_gb       = number
    auto_scaling_enabled  = optional(bool, false)
    min_count             = optional(number)
    max_count             = optional(number)
  }))
  default = {}
}

variable "aks_sku_tier" {
  description = "The SKU tier for the AKS cluster."
  type        = string
}

variable "enable_container_registry" {
  description = "Flag to enable or disable the creation of a container registry."
  type        = bool
  default     = true
}

variable "container_registry_sku" {
  description = "The SKU for the container registry."
  type        = string
  default     = "Standard"
}

variable "aks_identity_type" {
  description = "The type of identity used for the AKS cluster."
  type        = string
}

variable "aks_cost_analysis_enabled" {
  description = "Flag to enable cost analysis for the AKS cluster. When enabled, automatically uses Standard SKU tier."
  type        = bool
  default     = false
}

variable "aks_bootstrap_profile" {
  description = "Bootstrap profile configuration for AKS. Requires private endpoint for container registry if using Cache artifact source."
  type = object({
    artifact_source       = optional(string, "Direct")  # Cache or Direct
    container_registry_id = optional(string)
  })
  default = null
}

variable "enable_bastion" {
  description = "Flag to enable or disable the creation of the Bastion host."
  type        = bool
  default = false
}

variable "bastion_public_ip_sku" {
  description = "The SKU for the Bastion public IP address."
  type        = string
  default     = "Standard"
}

variable "enable_jumpbox_vm" {
  description = "Flag to enable or disable the creation of the jumpbox virtual machine."
  type        = bool
  default     = false
}

variable "jumpbox_admin_ssh_key" {
  description = "The SSH public key for the jumpbox admin user. If not provided, a key will be generated and stored in Key Vault."
  type        = string
  default     = ""
}

variable "enable_vpn_gateway" {
  description = "Flag to enable or disable the creation of the VPN gateway."
  type        = bool
  default     = false
}

variable "enable_aks" {
  description = "Flag to enable or disable the creation of the AKS cluster."
  type        = bool
  default     = true
}

variable "jumpbox_admin_username" {
  description = "The admin username for the jumpbox."
  type        = string
  default     = "azureuser"
}

variable "jumpbox_image" {
  description = "The image to use for the jumpbox virtual machine."
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

variable "jumpbox_os_disk_type" {
  description = "The OS disk type for the jumpbox."
  type        = string
  default     = "StandardSSD_LRS"
}

variable "jumpbox_public_ip_sku" {
  description = "The SKU for the jumpbox public IP address."
  type        = string
  default     = "Standard"
}

variable "jumpbox_subnet_name" {
  description = "The name of the subnet for the jumpbox. This must exist in the 'subnets' variable."
  type        = string
  default     = "mgmt"
}

variable "jumpbox_vm_size" {
  description = "The size of the jumpbox virtual machine."
  type        = string
  default     = "Standard_B2ms"
}

variable "key_vault_name_override" {
  description = "The name of the Key Vault. If not specified, a name will be generated."
  type        = string
  default     = ""
}

variable "location" {
  description = "The Azure region where all resources in this example should be created."
  type        = string
  default     = "eastus"
}

variable "region_codes" {
  description = "A map of region names to short codes."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "A map of tags to add to all resources."
  type        = map(string)
  default     = {}
}

variable "vpngw_active_active" {
  description = "Flag to enable or disable active-active mode for the VPN gateway."
  type        = bool
  default     = false
}

variable "vpngw_enable_bgp" {
  description = "Flag to enable or disable BGP for the VPN gateway."
  type        = bool
  default     = false
}

variable "vpngw_client_configuration" {
  description = "VPN client configuration settings for point-to-site VPN. Azure AD authentication can be configured in Azure Portal after deployment."
  type = object({
    address_space         = list(string)
    vpn_client_protocols  = optional(list(string), ["OpenVPN"])
  })
  default = null
}

variable "vpngw_public_ip_sku" {
  description = "The SKU for the VPN gateway public IP address."
  type        = string
  default     = "Standard"
}

variable "vpngw_sku" {
  description = "The SKU for the VPN gateway."
  type        = string
  default     = "VpnGw2"
}

variable "ssh_key_algorithm" {
  description = "The algorithm to use for generating the SSH key pair."
  type        = string
  default     = "RSA"
}

variable "ssh_key_rsa_bits" {
  description = "The number of bits in the RSA key (only used when algorithm is RSA)."
  type        = number
  default     = 4096
}

variable "subscription_id" {
  description = "The ID of the Azure subscription to use."
  type        = string
}

variable "subscription_name" {
  description = "The name of the Azure subscription to use."
  type        = string
  default     = null
}

variable "enable_key_vault" {
  description = "Flag to enable or disable the creation of the Key Vault."
  type        = bool
  default     = true 
}

variable "key_vault_sku_name" {
  description = "The SKU name for the Key Vault."
  type        = string
  default     = "standard"
}

variable "key_vault_purge_protection_enabled" {
  description = "Flag to enable or disable purge protection for the Key Vault."
  type        = bool
  default     = false
}

variable "key_vault_soft_delete_retention_days" {
  description = "The number of days to retain deleted items in the Key Vault."
  type        = number
  default     = 7
}

variable "key_vault_enable_rbac" {
  description = "Flag to enable or disable RBAC authorization for the Key Vault."
  type        = bool
  default     = true
}

variable "key_vault_rbac_role_name" {
  description = "The RBAC role name to assign to the Key Vault."
  type        = string
  default     = "Key Vault Secrets Officer"
}

variable "kv_secret_name_private" {
  description = "The name of the Key Vault secret for the private SSH key."
  type        = string
  default     = "jumpbox-ssh-private-key"
}

variable "kv_secret_name_public" {
  description = "The name of the Key Vault secret for the public SSH key."
  type        = string
  default     = "jumpbox-ssh-public-key"
}

variable "enable_aks_kv_csi_driver" {
  description = "Flag to enable the Azure Keyvault CSI driver addon in AKS, allowing pods to mount Key Vault secrets as volumes."
  type        = bool
  default     = true
}

variable "api_server_authorized_ip_ranges" {
  description = "List of authorized IP ranges that can access the API server"
  type        = list(string)
  default     = []
}
