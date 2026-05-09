# =============================================================================
#  Root composition for Lab #8 — Azure Load Balancing with Terraform
# -----------------------------------------------------------------------------
#  Wires together every module that makes up the lab:
#
#      vnet     -> Virtual Network + web/management subnets
#      compute  -> NICs and Linux VMs running nginx via cloud-init
#      lb       -> Public Load Balancer, health probe, rules and NSG
#
#  Optional challenges (gated by feature flags, default off):
#
#      bastion  -> Azure Bastion in a dedicated AzureBastionSubnet
#      budget   -> Cost Management budget with email alerts
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

# Network layer: VNet 10.10.0.0/16 + web/management subnets (+ optional
# AzureBastionSubnet when the bastion challenge is enabled).
module "vnet" {
  source                = "../modules/vnet"
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  prefix                = var.prefix
  tags                  = var.tags
  enable_bastion_subnet = var.enable_bastion
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

# -------- Optional challenge #1: Azure Bastion --------------------------
# Removes the need for public 22/TCP on the VMs by brokering SSH through
# the Azure portal over TLS. Subnet is created on demand inside the vnet
# module above; here we only deploy the Bastion host itself.
module "bastion" {
  count               = var.enable_bastion ? 1 : 0
  source              = "../modules/bastion"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  prefix              = var.prefix
  subnet_id           = module.vnet.subnet_bastion_id
  sku                 = var.bastion_sku
  tags                = var.tags
}

# -------- Optional challenge #2: Budget alert ---------------------------
# Cost Management budget scoped to the lab Resource Group, with email
# notifications at 50/90/100% so the team is paged before the credit
# runs out.
module "budget" {
  count             = var.enable_budget ? 1 : 0
  source            = "../modules/budget"
  prefix            = var.prefix
  resource_group_id = azurerm_resource_group.rg.id
  amount_usd        = var.budget_amount_usd
  contact_emails    = var.budget_contact_emails
  start_date        = var.budget_start_date
}
