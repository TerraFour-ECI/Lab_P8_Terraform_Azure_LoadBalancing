# =============================================================================
#  Module: budget (Optional challenge — Resource-Group level cost guardrail)
# -----------------------------------------------------------------------------
#  Provisions an Azure Cost Management budget scoped to the lab Resource
#  Group with three notification thresholds:
#
#    50%  -> early heads-up to the team mailing list.
#    90%  -> warning before the credit is exhausted.
#    100% -> hard alert; if you keep applying past this you are on your own.
#
#  Budgets themselves are free — Azure only emails the contacts when the
#  configured cost ratio is crossed. Time period defaults to a calendar
#  month starting on the day Terraform creates the resource.
# =============================================================================

resource "azurerm_consumption_budget_resource_group" "budget" {
  name              = "${var.prefix}-monthly-budget"
  resource_group_id = var.resource_group_id

  amount     = var.amount_usd
  time_grain = "Monthly"

  time_period {
    start_date = var.start_date
  }

  # Forecast vs Actual: we alert on Actual to avoid noisy notifications
  # during the first few days of the month.
  notification {
    enabled        = true
    threshold      = 50
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = var.contact_emails
  }

  notification {
    enabled        = true
    threshold      = 90
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = var.contact_emails
  }

  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThanOrEqualTo"
    threshold_type = "Actual"
    contact_emails = var.contact_emails
  }
}
