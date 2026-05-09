# =============================================================================
#  Module: vnet
# -----------------------------------------------------------------------------
#  Provisions a single VNet with two purpose-driven subnets:
#
#    subnet-web   (10.10.1.0/24) -> hosts the load-balanced VMs.
#    subnet-mgmt  (10.10.2.0/24) -> reserved for Azure Bastion or jump hosts
#                                   in a production hardening exercise.
#
#  Address ranges are intentionally non-overlapping with the typical Azure
#  default ranges so peering with another VNet stays painless.
# =============================================================================

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-vnet"
  address_space       = ["10.10.0.0/16"]
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_subnet" "web" {
  name                 = "subnet-web"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.10.1.0/24"]
}

resource "azurerm_subnet" "mgmt" {
  name                 = "subnet-mgmt"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.10.2.0/24"]
}
