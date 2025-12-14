
output "naming_prefix" {
  value       = local.prefix
  description = "Region code + 4-char hash prefix used in names"
}

output "resource_group_core" {
  value = azurerm_resource_group.core.name
}

output "resource_group_aks" {
  value       = try(azurerm_resource_group.aks[0].name, null)
  description = "AKS resource group name (if AKS enabled)"
}

output "vnet_name" {
  value = azurerm_virtual_network.vnet.name
}

output "subnet_ids" {
  value = {
    for k, s in azurerm_subnet.standard : k => s.id
  }
}

output "bastion_public_ip" {
  value       = try(azurerm_public_ip.bastion[0].ip_address, null)
  description = "Public IP of Azure Bastion (if enabled)"
}

output "vpn_gateway_public_ip" {
  value       = try(azurerm_public_ip.vpn[0].ip_address, null)
  description = "Public IP of VPN Gateway (if enabled)"
}

output "aks_cluster_name" {
  value       = try(azurerm_kubernetes_cluster.aks[0].name, null)
  description = "AKS cluster name (if enabled)"
}

output "aks_user_node_pools" {
  value = {
    for k, v in azurerm_kubernetes_cluster_node_pool.user : k => {
      id   = v.id
      name = v.name
    }
  }
  description = "User node pool IDs and names"
}

output "container_registry_name" {
  value       = try(azurerm_container_registry.acr[0].name, null)
  description = "Container registry name (if enabled)"
}

output "container_registry_login_server" {
  value       = try(azurerm_container_registry.acr[0].login_server, null)
  description = "Container registry login server URL (if enabled)"
}

output "container_registry_id" {
  value       = try(azurerm_container_registry.acr[0].id, null)
  description = "Container registry ID (if enabled)"
}

output "aks_acr_attachment_token_id" {
  value       = try(azurerm_kubernetes_cluster.aks[0].id, null)
  description = "AKS cluster ID with ACR attached during creation"
}

output "key_vault_name" {
  value       = try(azurerm_key_vault.kv[0].name, null)
  description = "Key Vault name (if enabled)"
}

output "key_vault_id" {
  value       = try(azurerm_key_vault.kv[0].id, null)
  description = "Key Vault ID (if enabled)"
}

output "key_vault_uri" {
  value       = try(azurerm_key_vault.kv[0].vault_uri, null)
  description = "Key Vault URI for accessing secrets (if enabled)"
}

output "key_vault_private_endpoint_id" {
  value       = try(azurerm_private_endpoint.kv[0].id, null)
  description = "Key Vault private endpoint ID (if endpoints subnet enabled)"
}

output "key_vault_private_endpoint_ip" {
  value       = try(azurerm_private_endpoint.kv[0].private_service_connection[0].private_ip_address, null)
  description = "Key Vault private endpoint IP address (if endpoints subnet enabled)"
}
