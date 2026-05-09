# =============================================================================
#  compute module — input variables
# =============================================================================

variable "resource_group_name" {
  type        = string
  description = "Name of the Resource Group where VMs/NICs will be created."
}

variable "location" {
  type        = string
  description = "Azure region for the compute resources."
}

variable "prefix" {
  type        = string
  description = "Naming prefix shared with the rest of the lab resources."
}

variable "admin_username" {
  type        = string
  description = "Local admin user created on every VM."
}

variable "ssh_public_key" {
  type        = string
  description = "Raw SSH public key contents (already read with file())."
  sensitive   = true
}

variable "subnet_id" {
  type        = string
  description = "ID of the subnet where the NICs will live."
}

variable "vm_count" {
  type        = number
  description = "Number of identical VMs to provision."
}

variable "cloud_init" {
  type        = string
  description = "Raw cloud-init YAML used to bootstrap nginx on first boot."
}

variable "tags" {
  type        = map(string)
  description = "Tags propagated to NICs and VMs."
}
