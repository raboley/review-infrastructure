provider "azurerm" {
  # whilst the `version` attribute is optional, we recommend pinning to a given version of the Provider
  version = "=2.20.0"
  features {}
}

# Create a resource group
variable "prefix" {
  default = "main"
}

resource "azurerm_resource_group" "i" {
  name     = "${var.prefix}-review-infrastructure-rg"
  location = "West US"
}

output "resource_group_name" {
  value = azurerm_resource_group.i.name
}