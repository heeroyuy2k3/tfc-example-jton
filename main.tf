# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
  
  tenant_id = TF_VAR_tenant_id
  subscription_id = TF_VAR_subscription_id
}

# Create a resource group using the generated random name
resource "azurerm_resource_group" "example" {
  location = "eastus"
  name     = "MITS-TF-RG"
}
