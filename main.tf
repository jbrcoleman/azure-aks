resource "azurerm_resource_group" "main" {
  name     = "kubernetes-autoscaling-rg"
  location = var.location
}

resource "azurerm_kubernetes_cluster" "main" {
  name                = "autoscaling-aks-cluster"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "autoscalek8s"

  default_node_pool {
    name       = "default"
    node_count = 2
    vm_size    = "Standard_D2_v2"
    type       = "VirtualMachineScaleSets"
    enable_auto_scaling = true
    min_count  = 1
    max_count  = 5
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_network_security_group" "webapp_nsg" {
  name                = "webapp-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "AllowSpecificIP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix       = var.allowed_ip  # Restrict to specific IP
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "DenyAll"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
