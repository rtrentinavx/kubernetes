
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.55.0" # adjust as needed
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-tfstate-eus-a1b2"
    storage_account_name = "tfstateeusa1b2"
    container_name       = "tfstate"
    key                  = "platform/azure/main.tfstate"
  }

}

provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
}
