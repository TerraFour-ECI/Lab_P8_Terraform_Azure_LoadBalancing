# =============================================================================
#  Root composition for Lab #8 — Azure Load Balancing with Terraform
# -----------------------------------------------------------------------------
#  This file wires together the three local modules that make up the lab:
#
#      vnet     -> Virtual Network + web/management subnets
#      compute  -> NICs and Linux VMs running nginx via cloud-init
#      lb       -> Public Load Balancer, health probe, rules and NSG
#
#  All resources live inside a single Resource Group so cleanup is a single
#  `terraform destroy`. Tags propagate from variables so cost ownership and
#  expiration can be tracked centrally.
# =============================================================================

# Container Resource Group for every lab resource.
resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-rg"
  location = var.location
  tags     = var.tags
}

# Network layer: VNet 10.10.0.0/16 + web/management subnets.
module "vnet" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  prefix              = var.prefix
  tags                = var.tags
}

# Compute layer: 2+ Ubuntu VMs, one NIC each, bootstrapped with cloud-init.
module "compute" {
  source              = "../modules/compute"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  prefix              = var.prefix
  admin_username      = var.admin_username
  ssh_public_key      = file(var.ssh_public_key)
  subnet_id           = module.vnet.subnet_web_id
  vm_count            = var.vm_count
  cloud_init          = file("${path.module}/cloud-init.yaml")
  tags                = var.tags
}

# Edge layer: Public Load Balancer + NSG. Backend pool is wired to the NICs
# emitted by the compute module so we never hard-code IDs at the root.
module "lb" {
  source              = "../modules/lb"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  prefix              = var.prefix
  backend_nic_ids     = module.compute.nic_ids
  allow_ssh_from_cidr = var.allow_ssh_from_cidr
  tags                = var.tags
}
