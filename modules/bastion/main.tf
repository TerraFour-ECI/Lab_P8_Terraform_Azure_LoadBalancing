# =============================================================================
#  Module: bastion (Optional challenge — Azure Bastion in subnet-mgmt area)
# -----------------------------------------------------------------------------
#  Provisions an Azure Bastion host that brokers SSH/RDP through the Azure
#  portal over TLS, removing the need to expose 22/TCP on the workload VMs.
#
#  Composition:
#    1. Standard SKU Public IP for the Bastion frontend.
#    2. azurerm_bastion_host attached to the AzureBastionSubnet provided by
#       the vnet module.
#
#  Cost note: Azure Bastion is the most expensive single resource in this
#  lab (~USD 0.19/hour for the Basic SKU). Keep it disabled unless a real
#  hardening exercise is being demoed.
# =============================================================================

resource "azurerm_public_ip" "bastion_pip" {
  name                = "${var.prefix}-bastion-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_bastion_host" "bastion" {
  name                = "${var.prefix}-bastion"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku

  ip_configuration {
    name                 = "bastion-ipconfig"
    subnet_id            = var.subnet_id
    public_ip_address_id = azurerm_public_ip.bastion_pip.id
  }

  tags = var.tags
}
