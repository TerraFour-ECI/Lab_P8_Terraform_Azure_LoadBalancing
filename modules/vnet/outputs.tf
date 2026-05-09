# =============================================================================
#  vnet module — outputs
# -----------------------------------------------------------------------------
#  Only the resource IDs/names that other modules genuinely need are exposed.
# =============================================================================

output "vnet_name" {
  description = "Name of the Virtual Network."
  value       = azurerm_virtual_network.vnet.name
}

output "subnet_web_id" {
  description = "Resource ID of the web subnet (consumed by the compute module)."
  value       = azurerm_subnet.web.id
}

output "subnet_mgmt_id" {
  description = "Resource ID of the management subnet."
  value       = azurerm_subnet.mgmt.id
}

output "subnet_bastion_id" {
  description = "Resource ID of the AzureBastionSubnet (null when enable_bastion_subnet=false)."
  value       = try(azurerm_subnet.bastion[0].id, null)
}
