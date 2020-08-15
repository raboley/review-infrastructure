terraform {
  required_version = "~> 0.12.0"

  backend "remote" {}
}

provider "azurerm" {
  # whilst the `version` attribute is optional, we recommend pinning to a given version of the Provider
  version = "=2.20.0"
  features {}
}

# Create a resource group
variable "environment" {
  default = "dev"
}

resource "azurerm_resource_group" "i" {
  name     = "${environment}-infrastructure-rg"
  location = "West US"
}

output "resource_group_name" {
  value = azurerm_resource_group.i.name
}