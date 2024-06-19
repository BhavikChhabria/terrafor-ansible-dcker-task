output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

# output "public_ip_address" {
#   value = azurerm_linux_virtual_machine.my_terraform_vm.public_ip_address
# }

output "public_ip" {
  value = azurerm_public_ip.my_terraform_public_ip.ip_address
}
