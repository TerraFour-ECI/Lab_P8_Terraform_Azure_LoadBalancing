# =============================================================================
#  Module: vnet
# -----------------------------------------------------------------------------
#  Provisions a single VNet with two purpose-driven subnets:
#
#    subnet-web   (10.10.1.0/24) -> hosts the load-balanced VMs.
#    subnet-mgmt  (10.10.2.0/24) -> reserved for future jump hosts.
#
#  When `var.enable_bastion_subnet` is true, an additional subnet named
#  `AzureBastionSubnet` (10.10.3.0/26) is created. Azure requires this
#  exact name and a minimum size of /26 for any Bastion deployment.
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

# AzureBastionSubnet — name and minimum size /26 are enforced by Azure.
# Created on demand so the base lab stays cheap; consumed by modules/bastion.
resource "azurerm_subnet" "bastion" {
  count                = var.enable_bastion_subnet ? 1 : 0
  name                 = "AzureBastionSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.10.3.0/26"]
}
