# =============================================================================
#  Module: lb (Public Azure Load Balancer + NSG)
# -----------------------------------------------------------------------------
#  Composes the edge layer of the lab:
#
#    1. Public IP (Standard, static) -> stable frontend address.
#    2. Standard SKU Load Balancer with a single Public frontend.
#    3. Backend pool wired to every NIC supplied by the compute module.
#    4. TCP/80 health probe + HTTP load balancing rule (80 -> 80).
#    5. NSG with two rules:
#         - Allow 80/TCP from Internet (the public web traffic).
#         - Allow 22/TCP only from `var.allow_ssh_from_cidr` (your /32).
#       The NSG is associated to each NIC, so NSG flows mirror the LB
#       backend pool exactly.
# =============================================================================

# Static Public IP attached to the LB frontend.
resource "azurerm_public_ip" "pip" {
  name                = "${var.prefix}-lb-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Standard SKU Load Balancer (required for Public IPs of Standard SKU).
resource "azurerm_lb" "lb" {
  name                = "${var.prefix}-lb"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "Public"
    public_ip_address_id = azurerm_public_ip.pip.id
  }

  tags = var.tags
}

resource "azurerm_lb_backend_address_pool" "bepool" {
  name            = "${var.prefix}-bepool"
  loadbalancer_id = azurerm_lb.lb.id
}

# Bind every NIC ipconfig (one per VM) into the backend pool.
resource "azurerm_network_interface_backend_address_pool_association" "assoc" {
  count                   = length(var.backend_nic_ids)
  network_interface_id    = var.backend_nic_ids[count.index]
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.bepool.id
}

# TCP/80 probe: cheaper than HTTP and good enough for nginx healthcheck.
resource "azurerm_lb_probe" "probe" {
  name            = "http-80"
  loadbalancer_id = azurerm_lb.lb.id
  protocol        = "Tcp"
  port            = 80
}

# HTTP load balancing rule: 80 (frontend) -> 80 (backend pool).
resource "azurerm_lb_rule" "rule" {
  name                           = "http-80"
  loadbalancer_id                = azurerm_lb.lb.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "Public"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.bepool.id]
  probe_id                       = azurerm_lb_probe.probe.id
}

# Network Security Group: minimal allow-list applied at NIC level.
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.prefix}-web-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Public web traffic — required for the LB to route 80/TCP to backends.
  security_rule {
    name                       = "Allow-HTTP-Internet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # SSH is restricted to a single IP/32 to avoid drive-by brute force.
  security_rule {
    name                       = "Allow-SSH-From-Operator"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.allow_ssh_from_cidr
    destination_address_prefix = "*"
  }

  tags = var.tags
}

# We attach the NSG at NIC level (not subnet level) so additional subnets
# in the future can declare their own posture without inheritance surprises.
resource "azurerm_network_interface_security_group_association" "nsg_assoc" {
  count                     = length(var.backend_nic_ids)
  network_interface_id      = var.backend_nic_ids[count.index]
  network_security_group_id = azurerm_network_security_group.nsg.id
}
