# =============================================================================
#  budget module — input variables
# =============================================================================

variable "prefix" {
  type        = string
  description = "Naming prefix shared with the rest of the lab resources."
}

variable "resource_group_id" {
  type        = string
  description = "Resource ID of the Resource Group the budget is scoped to."
}

variable "amount_usd" {
  type        = number
  description = "Monthly budget in USD. Notifications fire at 50/90/100% of this value."

  validation {
    condition     = var.amount_usd > 0 && var.amount_usd <= 200
    error_message = "amount_usd must be between 1 and 200 to keep the lab affordable."
  }
}

variable "contact_emails" {
  type        = list(string)
  description = "Email addresses notified when a threshold is crossed."

  validation {
    condition     = length(var.contact_emails) > 0
    error_message = "contact_emails must contain at least one address."
  }
}

variable "start_date" {
  type        = string
  description = <<-EOT
    Start date of the budget window in `YYYY-MM-01T00:00:00Z` format
    (Azure requires the first day of a month). Default: first day of the
    current month at the location of the apply.
  EOT
}
