# ---------------------------------
# Current subscription (for display name if you don't provide one)
# ---------------------------------
data "azurerm_subscription" "current" {}


# ---------------------------------
# Client config (for tenant_id/principal_id)
# ---------------------------------
data "azurerm_client_config" "current" {}

# ---------------------------------
# Azure AD config (for tenant and AAD information)
# ---------------------------------
data "azuread_client_config" "current" {}