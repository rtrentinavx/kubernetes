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
  for_each             = var.network_subnets.standard
  name                 = "${each.key}-subnet-${local.prefix}"
  resource_group_name  = azurerm_resource_group.core.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [each.value]
}

# Bastion subnet
resource "azurerm_subnet" "bastion" {
  count                = (var.enable_bastion && var.network_subnets.bastion != null) ? 1 : 0
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.core.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.network_subnets.bastion]
}

# Gateway subnet (VPN)
resource "azurerm_subnet" "gateway" {
  count                = ((var.enable_vpn_gateway || var.vpngw_client_configuration != null) && var.network_subnets.gateway != null) ? 1 : 0
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.core.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.network_subnets.gateway]
}

# Private Endpoints subnet
resource "azurerm_subnet" "endpoints" {
  count                = var.network_subnets.endpoints != null ? 1 : 0
  name                 = "endpoints-${local.prefix}"
  resource_group_name  = azurerm_resource_group.core.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.network_subnets.endpoints]
}

# AKS nodes subnet
resource "azurerm_subnet" "aks_nodes" {
  count                = var.enable_aks ? 1 : 0
  name                 = "aks-nodes-${local.prefix}"
  resource_group_name  = azurerm_resource_group.core.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.network_subnets.aks.nodes]
}

# AKS user node pool subnets
resource "azurerm_subnet" "aks_user_nodes" {
  for_each             = var.enable_aks ? var.network_subnets.aks.user_pools : {}
  name                 = "aks-user-nodes-${each.key}-${local.prefix}"
  resource_group_name  = azurerm_resource_group.core.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [each.value]
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
# TLS SSH key for jumpbox (generated when jumpbox enabled and no key provided)
# ---------------------------------
resource "tls_private_key" "jumpbox" {
  count     = var.enable_jumpbox_vm && var.jumpbox_admin_ssh_key == "" ? 1 : 0
  algorithm = var.ssh_key_algorithm
  # Only set rsa_bits when algorithm == "RSA"
  rsa_bits = var.ssh_key_algorithm == "RSA" ? var.ssh_key_rsa_bits : null
}

# ---------------------------------
# Key Vault 
# ---------------------------------

resource "azurerm_key_vault" "kv" {
  count                      = (var.enable_key_vault || (var.enable_jumpbox_vm && var.jumpbox_admin_ssh_key == "")) ? 1 : 0
  name                       = local.key_vault_name
  resource_group_name        = azurerm_resource_group.core.name
  location                   = var.location
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = var.key_vault_sku_name
  purge_protection_enabled   = var.key_vault_purge_protection_enabled
  soft_delete_retention_days = var.key_vault_soft_delete_retention_days
  rbac_authorization_enabled = var.key_vault_enable_rbac

  tags = local.common_tags
}

resource "azurerm_role_assignment" "kv_secrets_officer" {
  count                = ((var.enable_key_vault || (var.enable_jumpbox_vm && var.jumpbox_admin_ssh_key == "")) && var.key_vault_enable_rbac) ? 1 : 0
  scope                = azurerm_key_vault.kv[0].id
  role_definition_name = var.key_vault_rbac_role_name # e.g., "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}


# ---------------------------------
# Store SSH keys as Vault secrets
# ---------------------------------
resource "azurerm_key_vault_secret" "jumpbox_private" {
  count        = (var.enable_jumpbox_vm && var.jumpbox_admin_ssh_key == "") ? 1 : 0
  name         = var.kv_secret_name_private
  value        = tls_private_key.jumpbox[0].private_key_pem
  key_vault_id = azurerm_key_vault.kv[0].id

  depends_on = [
    azurerm_role_assignment.kv_secrets_officer
  ]
}

resource "azurerm_key_vault_secret" "jumpbox_public" {
  count        = (var.enable_jumpbox_vm && var.jumpbox_admin_ssh_key == "") ? 1 : 0
  name         = var.kv_secret_name_public
  value        = tls_private_key.jumpbox[0].public_key_openssh
  key_vault_id = azurerm_key_vault.kv[0].id

  depends_on = [
    azurerm_role_assignment.kv_secrets_officer
  ]
}

# Private Endpoint for Key Vault
resource "azurerm_private_endpoint" "kv" {
  count               = (var.enable_key_vault || (var.enable_jumpbox_vm && var.jumpbox_admin_ssh_key == "")) && var.network_subnets.endpoints != null ? 1 : 0
  name                = "pep-kv-${local.prefix}"
  resource_group_name = azurerm_resource_group.core.name
  location            = var.location
  subnet_id           = azurerm_subnet.endpoints[0].id

  private_service_connection {
    name                           = "psc-kv-${local.prefix}"
    private_connection_resource_id = azurerm_key_vault.kv[0].id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  tags = local.common_tags
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
    public_key = var.jumpbox_admin_ssh_key != "" ? var.jumpbox_admin_ssh_key : tls_private_key.jumpbox[0].public_key_openssh
  }

  custom_data = base64encode(file("${path.module}/jumpbox_init.sh"))

  tags = local.common_tags
}

# -----------------------------
# VPN Gateway
# -----------------------------
resource "azurerm_public_ip" "vpn" {
  count               = (var.enable_vpn_gateway || var.vpngw_client_configuration != null) ? 1 : 0
  name                = "pip-vpngw-${local.prefix}"
  resource_group_name = azurerm_resource_group.core.name
  location            = var.location
  allocation_method   = "Static"
  sku                 = var.vpngw_public_ip_sku
  tags                = local.common_tags
}

resource "azurerm_virtual_network_gateway" "vpn" {
  count               = (var.enable_vpn_gateway || var.vpngw_client_configuration != null) ? 1 : 0
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

  dynamic "vpn_client_configuration" {
    for_each = var.vpngw_client_configuration != null ? [var.vpngw_client_configuration] : []
    content {
      address_space        = vpn_client_configuration.value.address_space
      vpn_client_protocols = vpn_client_configuration.value.vpn_client_protocols
    }
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
  # Automatically use Standard SKU when cost analysis is enabled
  sku_tier            = var.aks_cost_analysis_enabled ? "Standard" : var.aks_sku_tier

  default_node_pool {
    name            = coalesce(var.aks_node_pool.name, "sys${local.hash4}")
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

  dynamic "key_vault_secrets_provider" {
    for_each = var.enable_aks_kv_csi_driver ? [1] : []
    content {
      secret_rotation_enabled = true
    }
  }

  cost_analysis_enabled = var.aks_cost_analysis_enabled

  dynamic "bootstrap_profile" {
    for_each = var.aks_bootstrap_profile != null ? [var.aks_bootstrap_profile] : []
    content {
      artifact_source       = bootstrap_profile.value.artifact_source
      container_registry_id = bootstrap_profile.value.container_registry_id
    }
  }

  tags = local.common_tags

  lifecycle {
    ignore_changes = []
  }
}

# User node pools
resource "azurerm_kubernetes_cluster_node_pool" "user" {
  for_each              = var.enable_aks ? var.aks_user_node_pools : {}
  name                  = coalesce(each.value.name, "usr${each.key}-${local.hash4}")
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks[0].id
  vm_size               = each.value.vm_size
  node_count            = each.value.node_count
  vnet_subnet_id        = contains(keys(var.network_subnets.aks.user_pools), each.key) ? azurerm_subnet.aks_user_nodes[each.key].id : azurerm_subnet.aks_nodes[0].id
  max_pods              = each.value.max_pods
  os_disk_size_gb       = each.value.os_disk_size_gb
  
  tags = local.common_tags
}

# ---------------------------------
# Container Registry
# ---------------------------------
resource "azurerm_container_registry" "acr" {
  count               = var.enable_aks && var.enable_container_registry ? 1 : 0
  name                = "acr${replace(local.prefix, "-", "")}"
  resource_group_name = azurerm_resource_group.aks[0].name
  location            = var.location
  sku                 = var.container_registry_sku
  admin_enabled       = false

  tags = local.common_tags
}

# Grant AKS cluster pull access to container registry
resource "azurerm_role_assignment" "aks_acr_pull" {
  count              = var.enable_aks && var.enable_container_registry ? 1 : 0
  scope              = azurerm_container_registry.acr[0].id
  role_definition_name = "AcrPull"
  principal_id       = azurerm_kubernetes_cluster.aks[0].identity[0].principal_id
}

# Grant AKS cluster access to read Key Vault secrets (for CSI driver)
resource "azurerm_role_assignment" "aks_keyvault_secrets_user" {
  count              = var.enable_aks && var.enable_aks_kv_csi_driver && (var.enable_key_vault || (var.enable_jumpbox_vm && var.jumpbox_admin_ssh_key == "")) ? 1 : 0
  scope              = azurerm_key_vault.kv[0].id
  role_definition_name = "Key Vault Secrets User"
  principal_id       = azurerm_kubernetes_cluster.aks[0].identity[0].principal_id
}

