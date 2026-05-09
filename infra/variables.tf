# =============================================================================
#  Root input variables
# -----------------------------------------------------------------------------
#  Concrete values live in `env/dev.tfvars` (and never in this file).
#  Each variable is typed and, where appropriate, validated to fail fast at
#  `terraform plan` rather than mid-apply.
# =============================================================================

variable "prefix" {
  type        = string
  description = "Short identifier prepended to every resource name (e.g. lab8)."

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,10}$", var.prefix))
    error_message = "prefix must be 2-11 lowercase alphanumerics or hyphens, starting with a letter."
  }
}

variable "location" {
  type        = string
  description = "Azure region where every resource is deployed (e.g. eastus)."
}

variable "vm_count" {
  type        = number
  description = "Number of Linux VMs registered behind the Load Balancer."

  validation {
    condition     = var.vm_count >= 2 && var.vm_count <= 5
    error_message = "vm_count must be between 2 and 5 to keep the lab affordable."
  }
}

variable "admin_username" {
  type        = string
  description = "Local admin user created on every VM (used for SSH)."
}

variable "ssh_public_key" {
  type        = string
  description = "Absolute path to the SSH public key injected into authorized_keys."
}

variable "allow_ssh_from_cidr" {
  type        = string
  description = "CIDR allowed to reach 22/TCP through the NSG (use your /32)."
}

variable "tags" {
  type        = map(string)
  description = "Resource tags propagated to every resource for cost/ownership tracking."
}
