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

# 7. Windows VM
#resource "azurerm_windows_virtual_machine" "vm" {
#  name                  = "vm-rdp"
#  location              = azurerm_resource_group.rg.location
#  resource_group_name   = azurerm_resource_group.rg.name
#  size                  = "Standard_B2ms"
#  admin_username        = "azureuser"
#  admin_password        = "P@ssword1234!" # <-- Use secret in production
#  network_interface_ids = [azurerm_network_interface.vm_nic.id]
#
#  os_disk {
#    caching              = "ReadWrite"
#    storage_account_type = "Standard_LRS"
#  }
#
#  source_image_reference {
#    publisher = "MicrosoftWindowsServer"
#    offer     = "WindowsServer"
#    sku       = "2019-Datacenter"
#    version   = "latest"
#  }
#}

# 8. Custom Script Extension to Install IIS
#resource "azurerm_virtual_machine_extension" "iis" {
#  name                 = "install-iis"
#  virtual_machine_id   = azurerm_windows_virtual_machine.vm.id
#  publisher            = "Microsoft.Compute"
#  type                 = "CustomScriptExtension"
#  type_handler_version = "1.10"
#
#  settings = jsonencode({
#    commandToExecute = "powershell -Command \"Add-WindowsFeature Web-Server; Set-Content -Path #'C:\\inetpub\\wwwroot\\index.html' -Value 'Hello World from IIS'; New-Item -Path 'C:\\inetpub\\wwwroot\\test.txt' #-ItemType File -Force\""
#  })
#}

# 7. Windows VM with MS SQL Deployment
resource "azurerm_windows_virtual_machine" "sqlvm" {
  name                = "sql2022vm-byol"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_D4s_v3"
  admin_username      = "azureuser"
  admin_password      = "P@ssw0rd1234!"
  network_interface_ids = [azurerm_network_interface.vm_nic.id]

  source_image_reference {
    publisher = "MicrosoftSQLServer"
    offer     = "sql2022-ws2022"
    sku       = "Enterprise-gen2" # can be Developer-gen2, Standard-gen2, Enterprise-gen2
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  # BYOL (Azure Hybrid Benefit for SQL)
  license_type = "Windows_Server"

}

# 8. MS SQL Server BYOL
resource "azurerm_mssql_virtual_machine" "sqlvm" {
  virtual_machine_id = azurerm_windows_virtual_machine.sqlvm.id

  sql_license_type = "AHUB"  # Azure Hybrid Benefit (BYOL)
}

# 9. Custom Script for SQL Collation
resource "azurerm_virtual_machine_extension" "sql_rebuild" {
  name                 = "sql-rebuild"
  virtual_machine_id   = azurerm_windows_virtual_machine.sqlvm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = jsonencode({
    commandToExecute = "powershell -ExecutionPolicy Unrestricted -Command \"& 'C:\\Program Files\\Microsoft SQL Server\\160\\Setup Bootstrap\\SQL2022\\Setup.exe' /QUIET /ACTION=REBUILDDATABASE /INSTANCENAME=MSSQLSERVER /SQLSYSADMINACCOUNTS=azureuser /SAPWD='P@ssw0rd1234!' /SQLCOLLATION=Latin1_General_CI_AS\""
  })
}