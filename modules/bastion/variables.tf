# =============================================================================
#  bastion module — input variables
# =============================================================================

variable "resource_group_name" {
  type        = string
  description = "Resource Group hosting the Bastion host and its Public IP."
}

variable "location" {
  type        = string
  description = "Azure region for the Bastion deployment."
}

variable "prefix" {
  type        = string
  description = "Naming prefix shared with the rest of the lab resources."
}

variable "subnet_id" {
  type        = string
  description = <<-EOT
    Resource ID of the AzureBastionSubnet (must be named exactly
    `AzureBastionSubnet`, /26 minimum). Provided by the vnet module when
    `enable_bastion_subnet = true`.
  EOT
}

variable "sku" {
  type        = string
  default     = "Basic"
  description = "Bastion SKU. `Basic` is enough for the lab; `Standard` adds shareable links and host scaling."

  validation {
    condition     = contains(["Basic", "Standard"], var.sku)
    error_message = "sku must be one of Basic, Standard."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags propagated to the Bastion host and its Public IP."
}
