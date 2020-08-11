terraform {
  required_version = "~> 0.13.0"

  backend "remote" {}
}

provider "azurerm" {
  # whilst the `version` attribute is optional, we recommend pinning to a given version of the Provider
  version = "=2.20.0"
  features {}
}

# Create a resource group
variable "suffix" {
  default = "main"
}

resource "azurerm_resource_group" "i" {
  name     = "review-infrastructure-rg-${var.suffix}"
  location = "West US"
}

output "resource_group_name" {
  value = azurerm_resource_group.i.name
}