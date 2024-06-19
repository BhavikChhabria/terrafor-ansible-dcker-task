# Resource Group
resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = replace(replace(replace(replace(replace(var.resource_group_name, " ", "_"), "(", "_"), ")", "_"), " ", "_"), "-", "_")
}

# Virtual Network
resource "azurerm_virtual_network" "my_terraform_network" {
  name                = "myVnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Subnet
resource "azurerm_subnet" "my_terraform_subnet" {
  name                 = "mySubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.my_terraform_network.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Public IP
resource "azurerm_public_ip" "my_terraform_public_ip" {
  name                = "myPublicIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

# Network Security Group
resource "azurerm_network_security_group" "my_terraform_nsg" {
  name                = "myNetworkSecurityGroup"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 320
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Network Interface
resource "azurerm_network_interface" "my_terraform_nic" {
  name                = "myNIC"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "my_nic_configuration"
    subnet_id                     = azurerm_subnet.my_terraform_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.my_terraform_public_ip.id
  }
}

# Generate Random Text for Unique Storage Account Name
resource "random_id" "random_id" {
  keepers = {
    resource_group = azurerm_resource_group.rg.name
  }
  byte_length = 8
}

# Storage Account for Boot Diagnostics
resource "azurerm_storage_account" "my_storage_account" {
  name                     = "diag${random_id.random_id.hex}"
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Generate SSH Key
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key_pem" {
  content  = tls_private_key.ssh_key.private_key_pem
  filename = "${path.module}/id_rsa"
}

resource "local_file" "public_key_openssh" {
  content  = tls_private_key.ssh_key.public_key_openssh
  filename = "${path.module}/id_rsa.pub"
}

# resource "local_file" "id_rsa" {
#   filename = "id_rsa"
#   content = abspath("./")
# }

# Generate the hosts.ini File

# Virtual Machine
resource "azurerm_linux_virtual_machine" "my_terraform_vm" {
    name                  = "myVM"
    location              = azurerm_resource_group.rg.location
    resource_group_name   = azurerm_resource_group.rg.name
    network_interface_ids = [azurerm_network_interface.my_terraform_nic.id]
    size                  = "Standard_DS1_v2"

    os_disk {
        name                 = "myOsDisk"
        caching              = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "0001-com-ubuntu-server-jammy"
        sku       = "22_04-lts-gen2"
        version   = "latest"
    }

    computer_name  = "hostname"
    admin_username = var.username

    admin_ssh_key {
        username   = var.username
        public_key = tls_private_key.ssh_key.public_key_openssh
    }

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.my_storage_account.primary_blob_endpoint
    }

}

resource "local_file" "hosts_ini" {
    content  =<<-EOT
        [my_virtual_machine]
        ${azurerm_public_ip.my_terraform_public_ip.ip_address} ansible_user=${var.username} ansible_ssh_private_key_file=./id_rsa
    EOT
    filename = "./hosts.ini"
    provisioner "local-exec" {
        command = "ansible-playbook -i hosts.ini deploy_docker.yml"
        environment = {
            ANSIBLE_HOST_KEY_CHECKING = "False"
        }

    }
    
}




