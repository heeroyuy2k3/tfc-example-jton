# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

output "hello_world" {
  description = "Custom message"
  value       = "Hello World!"
}

output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.rg.name
}

output "vm_name" {
  description = "The name of the virtual machine"
  value       = azurerm_windows_virtual_machine.vm.name
}


