
output "naming_prefix" {
  value       = local.prefix
  description = "Region code + 4-char hash prefix used in names"
}

output "resource_group_core" {
  value = azurerm_resource_group.core.name
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
