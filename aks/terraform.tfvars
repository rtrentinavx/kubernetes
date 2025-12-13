subscription_id = "47ab116c-8c15-4453-b06a-3fecd09ebda9"

location = "eastus"

address_space = ["10.10.0.0/16"]

subnets = {
  mgmt     = "10.10.0.0/24"
  workload = "10.10.1.0/24"
}

bastion_subnet_cidr  = "10.10.100.0/27"
gateway_subnet_cidr  = "10.10.200.0/27"
aks_node_subnet_cidr = "10.10.8.0/22"

enable_bastion     = true
enable_jumpbox_vm  = false
enable_vpn_gateway = false
enable_aks         = true

bastion_public_ip_sku = "Standard"


jumpbox_subnet_name    = "mgmt"
jumpbox_public_ip_sku  = "Standard"
jumpbox_vm_size        = "Standard_B2ms"
jumpbox_admin_username = "azureuser"
jumpbox_admin_ssh_key  = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIexamplekeygoeshere user@host"
jumpbox_os_disk_type   = "StandardSSD_LRS"

jumpbox_image = {
  publisher = "Canonical"
  offer     = "0001-com-ubuntu-server-jammy"
  sku       = "22_04-lts-gen2"
  version   = "latest"
}

vpngw_public_ip_sku = "Standard"
vpngw_sku           = "VpnGw2"
vpngw_active_active = false
vpngw_enable_bgp    = false

aks_sku_tier      = "Free"
aks_identity_type = "SystemAssigned"

aks_node_pool = {
  name            = "np1"
  vm_size         = "Standard_DS3_v2"
  node_count      = 3
  max_pods        = 30
  os_disk_size_gb = 128
}

aks_network = {
  dns_service_ip      = "10.2.0.10"
  service_cidr        = "10.2.0.0/24"
  outbound_type       = "loadBalancer"
  network_plugin_mode = "overlay"
  network_data_plane  = "cilium"
}

# API Server authorized IP ranges
api_server_authorized_ip_ranges = [
  "23.124.126.28/32",   # Your current IP
  "10.10.100.0/27"      # Bastion subnet
]