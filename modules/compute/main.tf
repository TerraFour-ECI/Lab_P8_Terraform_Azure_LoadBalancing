# =============================================================================
#  Module: compute
# -----------------------------------------------------------------------------
#  Provisions `vm_count` Linux VMs (Ubuntu 22.04 LTS, Standard_B1s) along
#  with a dedicated NIC each. The NICs land in the web subnet provided by
#  the vnet module and are later associated to the LB backend pool by the
#  lb module.
#
#  Bootstrap is performed via cloud-init (passed in as `var.cloud_init`),
#  which keeps OS-level concerns out of Terraform.
# =============================================================================

resource "azurerm_network_interface" "nic" {
  count               = var.vm_count
  name                = "${var.prefix}-nic-${count.index}"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

resource "azurerm_linux_virtual_machine" "vm" {
  count               = var.vm_count
  name                = "${var.prefix}-vm-${count.index}"
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = "Standard_B1s"

  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.nic[count.index].id]

  # Password authentication is disabled by default — SSH keys only.
  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # cloud-init is passed as raw YAML by the caller and base64-encoded here
  # because Azure expects the payload encoded in transit.
  custom_data = base64encode(var.cloud_init)

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  tags = var.tags
}
