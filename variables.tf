# # variables.tf

# variable "resource_group_name" {
#   description = "Name of the resource group"
#   type        = string
# }

# variable "resource_group_location" {
#   description = "Location for the resource group"
#   type        = string
# }

# variable "username" {
#   description = "Admin username for the VM"
#   type        = string
# }

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "resource_group_location" {
  description = "Location of the resource group"
  type        = string
}

variable "username" {
  description = "SSH username for the VM"
  type        = string
}

