
variable "address_space" {
  description = "The address space that will be used by the Virtual Network."
  type        = list(string)
}

variable "aks_identity_type" {
  description = "The type of identity used for the AKS cluster."
  type        = string
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
    name            = string
    vm_size         = string
    node_count      = number
    max_pods        = number
    os_disk_size_gb = number
  })
}

variable "aks_node_subnet_cidr" {
  description = "The CIDR block for the AKS node subnet."
  type        = string
}

variable "aks_sku_tier" {
  description = "The SKU tier for the AKS cluster."
  type        = string
}

variable "bastion_public_ip_sku" {
  description = "The SKU for the Bastion public IP address."
  type        = string
  default     = "Standard"
}

variable "bastion_subnet_cidr" {
  description = "The CIDR block for the Bastion subnet."
  type        = string
}

variable "enable_aks" {
  description = "Flag to enable or disable the creation of the AKS cluster."
  type        = bool
}

variable "enable_bastion" {
  description = "Flag to enable or disable the creation of the Bastion host."
  type        = bool
}

variable "enable_jumpbox_vm" {
  description = "Flag to enable or disable the creation of the jumpbox virtual machine."
  type        = bool
}

variable "enable_vpn_gateway" {
  description = "Flag to enable or disable the creation of the VPN gateway."
  type        = bool
}

variable "gateway_subnet_cidr" {
  description = "The CIDR block for the VPN Gateway subnet."
  type        = string
}

variable "jumpbox_admin_ssh_key" {
  description = "The SSH public key for the jumpbox admin user."
  type        = string
}

variable "jumpbox_admin_username" {
  description = "The admin username for the jumpbox."
  type        = string
}

variable "jumpbox_image" {
  description = "The image to use for the jumpbox virtual machine."
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
}

variable "jumpbox_os_disk_type" {
  description = "The OS disk type for the jumpbox."
  type        = string
}

variable "jumpbox_public_ip_sku" {
  description = "The SKU for the jumpbox public IP address."
  type        = string
}

variable "jumpbox_subnet_name" {
  description = "The name of the subnet for the jumpbox. This must exist in the 'subnets' variable."
  type        = string
}

variable "jumpbox_vm_size" {
  description = "The size of the jumpbox virtual machine."
  type        = string
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

variable "subnets" {
  description = "A map of subnet names to CIDR blocks."
  type        = map(string)
}

variable "subscription_name" {
  description = "The name of the Azure subscription to use."
  type        = string
  default     = null
}

variable "tags" {
  description = "A map of tags to add to all resources."
  type        = map(string)
  default     = {}
}

variable "vpngw_active_active" {
  description = "Flag to enable or disable active-active mode for the VPN gateway."
  type        = bool
}

variable "vpngw_enable_bgp" {
  description = "Flag to enable or disable BGP for the VPN gateway."
  type        = bool
}

variable "vpngw_public_ip_sku" {
  description = "The SKU for the VPN gateway public IP address."
  type        = string
}

variable "vpngw_sku" {
  description = "The SKU for the VPN gateway."
  type        = string
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

variable "enable_key_vault" {
  description = "Flag to enable or disable the creation of the Key Vault."
  type        = bool
  default     = false
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

variable "api_server_authorized_ip_ranges" {
  description = "List of authorized IP ranges that can access the API server"
  type        = list(string)
  default     = []
}
