# =============================================================================
#  lb module — outputs
# =============================================================================

output "public_ip" {
  description = "Public IPv4 of the LB frontend (curl this to reach the backends)."
  value       = azurerm_public_ip.pip.ip_address
}

output "backend_pool_id" {
  description = "Resource ID of the backend address pool."
  value       = azurerm_lb_backend_address_pool.bepool.id
}
