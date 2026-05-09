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

# ---------------------------------------------------------------------------
#  Optional challenge: Azure Bastion (in subnet-mgmt area)
# ---------------------------------------------------------------------------

variable "enable_bastion" {
  type        = bool
  default     = false
  description = <<-EOT
    Provision Azure Bastion in a dedicated AzureBastionSubnet. When true,
    the SSH NSG rule can be removed in production because operators reach
    the VMs via the Bastion broker over TLS. Disabled by default because
    Bastion is the most expensive single resource in this lab (~USD
    0.19/hour for the Basic SKU).
  EOT
}

variable "bastion_sku" {
  type        = string
  default     = "Basic"
  description = "Azure Bastion SKU: Basic (cheaper) or Standard (shareable links, scale)."

  validation {
    condition     = contains(["Basic", "Standard"], var.bastion_sku)
    error_message = "bastion_sku must be one of Basic, Standard."
  }
}

# ---------------------------------------------------------------------------
#  Optional challenge: Budget alert (Cost Management)
# ---------------------------------------------------------------------------

variable "enable_budget" {
  type        = bool
  default     = false
  description = <<-EOT
    Provision a monthly Cost Management budget on the lab Resource Group
    with email notifications at 50/90/100% of `budget_amount_usd`.
    Budgets themselves are free; the only cost is the email pipeline.
  EOT
}

variable "budget_amount_usd" {
  type        = number
  default     = 30
  description = "Monthly budget cap in USD (used only when enable_budget=true)."
}

variable "budget_contact_emails" {
  type        = list(string)
  default     = []
  description = "Email recipients for budget threshold alerts (used only when enable_budget=true)."
}

variable "budget_start_date" {
  type        = string
  default     = "2026-05-01T00:00:00Z"
  description = "Start of the budget window. Azure requires the first day of a month."
}
