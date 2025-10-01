# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
  
  tenant_id = var.tenant_id
  subscription_id = var.subscription_id
}

# 1. Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "rg-MITS-RG-demo"
  location = var.resource_group_location
}

# 2. Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-demo"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# 3. Subnets
resource "azurerm_subnet" "vm_subnet" {
  name                 = "subnet-vm"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "bastion_subnet" {
  name                 = "AzureBastionSubnet" # MUST be this name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/27"]
}

# 4. Public IP for Bastion
resource "azurerm_public_ip" "bastion_pip" {
  name                = "pip-bastion"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# 5. Bastion Host
resource "azurerm_bastion_host" "bastion" {
  name                = "bastion-host"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                 = "bastion-ipcfg"
    subnet_id            = azurerm_subnet.bastion_subnet.id
    public_ip_address_id = azurerm_public_ip.bastion_pip.id
  }
}

# 6. Network Interface for VM
resource "azurerm_network_interface" "vm_nic" {
  name                = "nic-vm"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# 7. CIS Windows Server 2022 Level 1 Generation 2
resource "azurerm_virtual_machine" "cisvm" {
  name                  = "cis-l1-vm"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.vm_nic.id]
  vm_size               = "Standard_D4s_v3"
  delete_os_disk_on_termination = true

  # Use the CIS hardened image from Marketplace
  storage_image_reference {
    publisher = "center-for-internet-security-inc"
    offer     = "cis-windows-server"      # example: CIS Windows Server 2022 Level 1 Generation 2 offer
    sku       = "cis-windows-server2022-l1-gen2"                # SKU for the level 1 gen 2 image
    version   = "latest"
  }

  # Required plan block for marketplace images with licensing/terms
  plan {
    name      = "cis-ws2022-l1g2-vm01"
    product   = "cis-windows-server2022-l1-gen2"
    publisher = "center-for-internet-security-inc"
  }

  os_profile {
    computer_name  = "cisvm"
    admin_username = "azureuser"
    admin_password = "P@ssword1234!" # <-- Use secret in production
  }

  os_profile_windows_config {
    enable_automatic_upgrades = true
	timezone                  = "Singapore Standard Time"
  }

  storage_os_disk {
    name              = "cisvm-osdisk"
    caching           = "ReadWrite"
    managed_disk_type = "Premium_LRS"
    create_option     = "FromImage"
  }

  # attach NSG, etc.
}