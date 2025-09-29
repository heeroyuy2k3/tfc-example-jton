# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

terraform {
  required_version = ">=1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {}
  
  tenant_id = var.tenant_id
  subscription_id = var.subscription_id
}

# Create a resource group using the generated random name
resource "azurerm_resource_group" "example" {
  location = "eastus"
  name     = "MITS-TF-RG"
}
