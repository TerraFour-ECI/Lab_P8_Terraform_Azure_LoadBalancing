# =============================================================================
#  Root outputs — surfaced to the CLI and to GitHub Actions
# -----------------------------------------------------------------------------
#  - `lb_public_ip` is the entry point printed on stdout to curl the demo.
#  - `resource_group_name` makes destroy/inspection scripts stable.
#  - `vm_names` is consumed by smoke tests that hit the LB N times to assert
#    that every backend VM responded at least once.
#  - `bastion_dns_name` and `budget_name` are conditional outputs from the
#    optional challenge modules (null when the feature flag is off).
# =============================================================================

output "lb_public_ip" {
  description = "Public IPv4 address of the Azure Load Balancer frontend."
  value       = module.lb.public_ip
}

output "resource_group_name" {
  description = "Name of the Resource Group that contains every lab resource."
  value       = azurerm_resource_group.rg.name
}

output "vm_names" {
  description = "Names of the Linux VMs registered in the LB backend pool."
  value       = module.compute.vm_names
}

output "bastion_dns_name" {
  description = "FQDN of the Azure Bastion host (null when enable_bastion=false)."
  value       = try(module.bastion[0].bastion_dns_name, null)
}

output "budget_name" {
  description = "Name of the Cost Management budget (null when enable_budget=false)."
  value       = try(module.budget[0].budget_name, null)
}
