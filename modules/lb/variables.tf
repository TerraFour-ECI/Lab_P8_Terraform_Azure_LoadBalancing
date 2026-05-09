# =============================================================================
#  lb module — input variables
# =============================================================================

variable "resource_group_name" {
  type        = string
  description = "Resource Group hosting the LB and NSG."
}

variable "location" {
  type        = string
  description = "Azure region for the edge resources."
}

variable "prefix" {
  type        = string
  description = "Naming prefix shared with the rest of the lab resources."
}

variable "backend_nic_ids" {
  type        = list(string)
  description = "Resource IDs of the NICs to register in the LB backend pool."
}

variable "allow_ssh_from_cidr" {
  type        = string
  description = "CIDR block (typically a single /32) allowed to reach 22/TCP."
}

variable "tags" {
  type        = map(string)
  description = "Tags propagated to LB, Public IP and NSG."
}
