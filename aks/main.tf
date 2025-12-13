locals {
  subscription_display_name = var.subscription_name != null ? var.subscription_name : data.azurerm_subscription.current.display_name
  region_code               = lookup(var.region_codes, var.location, var.location)
  hash4                     = substr(md5("${lower(local.subscription_display_name)}-${lower(var.location)}"), 0, 4)
  prefix                    = lower("${local.region_code}-${local.hash4}")

  common_tags = merge(
    {
      subscription = local.subscription_display_name
      region       = var.location
      name_prefix  = local.prefix
    },
    var.tags
  )

  kv_base_name   = "kv${replace(local.prefix, "-", "")}"
  key_vault_name = var.key_vault_name_override != null && var.key_vault_name_override != "" ? var.key_vault_name_override : local.kv_base_name

}

# -----------------------------
# Resource Groups
# -----------------------------
resource "azurerm_resource_group" "core" {
  name     = "rg-${local.prefix}-core"
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_resource_group" "aks" {
  count    = var.enable_aks ? 1 : 0
  name     = "rg-${local.prefix}-aks"
  location = var.location
  tags     = local.common_tags
}

# -----------------------------
# VNet and subnets
# -----------------------------
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${local.prefix}"
  resource_group_name = azurerm_resource_group.core.name
  location            = var.location
  address_space       = var.address_space
  tags                = local.common_tags
}

# Regular subnets
resource "azurerm_subnet" "standard" {
  for_each             = var.subnets
  name                 = "${each.key}-subnet-${local.prefix}"
  resource_group_name  = azurerm_resource_group.core.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [each.value]
}

# Bastion subnet
resource "azurerm_subnet" "bastion" {
  count                = var.enable_bastion ? 1 : 0
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.core.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.bastion_subnet_cidr]
}

# Gateway subnet (VPN)
resource "azurerm_subnet" "gateway" {
  count                = var.enable_vpn_gateway ? 1 : 0
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.core.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.gateway_subnet_cidr]
}

# AKS nodes subnet
resource "azurerm_subnet" "aks_nodes" {
  count                = var.enable_aks ? 1 : 0
  name                 = "aks-nodes-${local.prefix}"
  resource_group_name  = azurerm_resource_group.core.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.aks_node_subnet_cidr]
}

# -----------------------------
# Azure Bastion
# -----------------------------
resource "azurerm_public_ip" "bastion" {
  count               = var.enable_bastion ? 1 : 0
  name                = "pip-bastion-${local.prefix}"
  resource_group_name = azurerm_resource_group.core.name
  location            = var.location
  allocation_method   = "Static"
  sku                 = var.bastion_public_ip_sku
  tags                = local.common_tags
}

resource "azurerm_bastion_host" "bastion" {
  count               = var.enable_bastion ? 1 : 0
  name                = "bastion-${local.prefix}"
  resource_group_name = azurerm_resource_group.core.name
  location            = var.location

  ip_configuration {
    name                 = "bastion-ipcfg"
    subnet_id            = azurerm_subnet.bastion[0].id
    public_ip_address_id = azurerm_public_ip.bastion[0].id
  }

  tags = local.common_tags
}


# ---------------------------------
# Client config (for tenant_id/principal_id)
# ---------------------------------
data "azurerm_client_config" "current" {}

# ---------------------------------
# TLS SSH key for jumpbox (generated when jumpbox enabled)
# ---------------------------------
resource "tls_private_key" "jumpbox" {
  count     = var.enable_jumpbox_vm ? 1 : 0
  algorithm = var.ssh_key_algorithm
  # Only set rsa_bits when algorithm == "RSA"
  rsa_bits = var.ssh_key_algorithm == "RSA" ? var.ssh_key_rsa_bits : null
}

# ---------------------------------
# Key Vault 
# ---------------------------------

resource "azurerm_key_vault" "kv" {
  count                      = var.enable_key_vault ? 1 : 0
  name                       = local.key_vault_name
  resource_group_name        = azurerm_resource_group.core.name
  location                   = var.location
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = var.key_vault_sku_name
  purge_protection_enabled   = var.key_vault_purge_protection_enabled
  soft_delete_retention_days = var.key_vault_soft_delete_retention_days
  enable_rbac_authorization  = var.key_vault_enable_rbac

  tags = local.common_tags
}

resource "azurerm_role_assignment" "kv_secrets_officer" {
  count                = var.enable_key_vault && var.key_vault_enable_rbac ? 1 : 0
  scope                = azurerm_key_vault.kv[0].id
  role_definition_name = var.key_vault_rbac_role_name # e.g., "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}


# ---------------------------------
# Store SSH keys as Vault secrets
# ---------------------------------
resource "azurerm_key_vault_secret" "jumpbox_private" {
  count        = var.enable_key_vault && var.enable_jumpbox_vm ? 1 : 0
  name         = var.kv_secret_name_private
  value        = tls_private_key.jumpbox[0].private_key_pem
  key_vault_id = azurerm_key_vault.kv[0].id
}

resource "azurerm_key_vault_secret" "jumpbox_public" {
  count        = var.enable_key_vault && var.enable_jumpbox_vm ? 1 : 0
  name         = var.kv_secret_name_public
  value        = tls_private_key.jumpbox[0].public_key_openssh
  key_vault_id = azurerm_key_vault.kv[0].id
}


# -----------------------------
# Optional Jumpbox VM
# -----------------------------
resource "azurerm_public_ip" "jumpbox" {
  count               = var.enable_jumpbox_vm ? 1 : 0
  name                = "pip-jumpbox-${local.prefix}"
  resource_group_name = azurerm_resource_group.core.name
  location            = var.location
  allocation_method   = "Static"
  sku                 = var.jumpbox_public_ip_sku
  tags                = local.common_tags
}

resource "azurerm_network_interface" "jumpbox" {
  count               = var.enable_jumpbox_vm ? 1 : 0
  name                = "nic-jumpbox-${local.prefix}"
  resource_group_name = azurerm_resource_group.core.name
  location            = var.location

  ip_configuration {
    name                          = "ipcfg"
    subnet_id                     = azurerm_subnet.standard[var.jumpbox_subnet_name].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.jumpbox[0].id
  }

  tags = local.common_tags
}

resource "azurerm_linux_virtual_machine" "jumpbox" {
  count                 = var.enable_jumpbox_vm ? 1 : 0
  name                  = "vm-jumpbox-${local.prefix}"
  resource_group_name   = azurerm_resource_group.core.name
  location              = var.location
  size                  = var.jumpbox_vm_size
  admin_username        = var.jumpbox_admin_username
  network_interface_ids = [azurerm_network_interface.jumpbox[0].id]

  os_disk {
    name                 = "osdisk-jumpbox-${local.prefix}"
    caching              = "ReadWrite"
    storage_account_type = var.jumpbox_os_disk_type
  }

  source_image_reference {
    publisher = var.jumpbox_image.publisher
    offer     = var.jumpbox_image.offer
    sku       = var.jumpbox_image.sku
    version   = var.jumpbox_image.version
  }

  admin_ssh_key {
    username   = var.jumpbox_admin_username
    public_key = var.jumpbox_admin_ssh_key
  }

  tags = local.common_tags
}

# -----------------------------
# VPN Gateway
# -----------------------------
resource "azurerm_public_ip" "vpn" {
  count               = var.enable_vpn_gateway ? 1 : 0
  name                = "pip-vpngw-${local.prefix}"
  resource_group_name = azurerm_resource_group.core.name
  location            = var.location
  allocation_method   = "Static"
  sku                 = var.vpngw_public_ip_sku
  tags                = local.common_tags
}

resource "azurerm_virtual_network_gateway" "vpn" {
  count               = var.enable_vpn_gateway ? 1 : 0
  name                = "vpngw-${local.prefix}"
  resource_group_name = azurerm_resource_group.core.name
  location            = var.location
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = var.vpngw_sku
  active_active       = var.vpngw_active_active
  enable_bgp          = var.vpngw_enable_bgp

  ip_configuration {
    name                          = "vpngw-ipcfg"
    public_ip_address_id          = azurerm_public_ip.vpn[0].id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway[0].id
  }

  tags = local.common_tags
}

# -----------------------------
# AKS (Azure CNI)
# -----------------------------
resource "azurerm_kubernetes_cluster" "aks" {
  count               = var.enable_aks ? 1 : 0
  name                = "aks-${local.prefix}"
  resource_group_name = azurerm_resource_group.aks[0].name
  location            = var.location
  dns_prefix          = "aks-${local.hash4}"
  sku_tier            = var.aks_sku_tier

  default_node_pool {
    name            = var.aks_node_pool.name
    vm_size         = var.aks_node_pool.vm_size
    node_count      = var.aks_node_pool.node_count
    vnet_subnet_id  = azurerm_subnet.aks_nodes[0].id
    max_pods        = var.aks_node_pool.max_pods
    os_disk_size_gb = var.aks_node_pool.os_disk_size_gb
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_data_plane  = "cilium"
    dns_service_ip      = var.aks_network.dns_service_ip
    service_cidr        = var.aks_network.service_cidr
    outbound_type       = var.aks_network.outbound_type
  }

  api_server_access_profile {
    authorized_ip_ranges = var.api_server_authorized_ip_ranges
  }

  identity {
    type = var.aks_identity_type
  }

  tags = local.common_tags

  lifecycle {
    ignore_changes = []
  }
}
