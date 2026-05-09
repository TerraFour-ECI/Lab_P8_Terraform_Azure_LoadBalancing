# =============================================================================
#  bastion module — outputs
# =============================================================================

output "bastion_dns_name" {
  description = "FQDN of the Bastion host (used by the Azure portal SSH/RDP broker)."
  value       = azurerm_bastion_host.bastion.dns_name
}

output "bastion_public_ip" {
  description = "Public IPv4 of the Bastion frontend (informational)."
  value       = azurerm_public_ip.bastion_pip.ip_address
}
