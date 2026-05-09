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
