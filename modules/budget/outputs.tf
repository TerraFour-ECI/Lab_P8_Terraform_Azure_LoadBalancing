# =============================================================================
#  budget module — outputs
# =============================================================================

output "budget_id" {
  description = "Resource ID of the Cost Management budget."
  value       = azurerm_consumption_budget_resource_group.budget.id
}

output "budget_name" {
  description = "Name of the Cost Management budget."
  value       = azurerm_consumption_budget_resource_group.budget.name
}
