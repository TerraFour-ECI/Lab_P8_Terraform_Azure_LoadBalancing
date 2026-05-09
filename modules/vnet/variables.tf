# =============================================================================
#  vnet module — input variables
# =============================================================================

variable "resource_group_name" {
  type        = string
  description = "Name of the Resource Group that will host the VNet."
}

variable "location" {
  type        = string
  description = "Azure region where the VNet is deployed."
}

variable "prefix" {
  type        = string
  description = "Naming prefix for VNet and subnets (e.g. lab8)."
}

variable "tags" {
  type        = map(string)
  description = "Tags propagated to the VNet for ownership and cost tracking."
}

variable "enable_bastion_subnet" {
  type        = bool
  default     = false
  description = <<-EOT
    When true, provisions an additional `AzureBastionSubnet` (10.10.3.0/26).
    The subnet name is mandated by Azure and cannot be customised. Required
    by the optional `bastion` module — leave false unless you also enable
    that module.
  EOT
}
