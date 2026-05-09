# =============================================================================
#  compute module — outputs
# =============================================================================

output "vm_names" {
  description = "Friendly names of the provisioned VMs (lab8-vm-0, lab8-vm-1, ...)."
  value       = [for v in azurerm_linux_virtual_machine.vm : v.name]
}

output "nic_ids" {
  description = "Resource IDs of the NICs, consumed by the lb module to wire the backend pool."
  value       = [for n in azurerm_network_interface.nic : n.id]
}
