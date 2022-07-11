terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.0.0"
    }
  }
}


provider "azurerm" {
  features {}
}


resource "azurerm_resource_group" "abhijitrg1" {
  name     = "abhijitrg1"
  location = "east us"
  tags = {
    environment = "dev"
  }

}

resource "azurerm_virtual_network" "abhijitvn1" {
  name                = "abhijitvn1"
  resource_group_name = azurerm_resource_group.abhijitrg1.name
  location            = azurerm_resource_group.abhijitrg1.location
  address_space       = ["10.123.0.0/16"]

  tags = {
    "environment" = "dev"
  }

}


resource "azurerm_subnet" "abhijitsubnet1" {
  name                 = "abhijitsubnet1"
  resource_group_name  = azurerm_resource_group.abhijitrg1.name
  virtual_network_name = azurerm_virtual_network.abhijitvn1.name
  address_prefixes     = ["10.123.1.0/24"]
}

resource "azurerm_network_security_group" "abhijitsg1" {
  name                = "abhijitsg1"
  resource_group_name = azurerm_resource_group.abhijitrg1.name
  location            = azurerm_resource_group.abhijitrg1.location

  tags = {
    "environment" = "dev"
  }

}

resource "azurerm_network_security_rule" "abhijitsgrule1" {
  name                        = "abhijitsgrule1"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.abhijitrg1.name
  network_security_group_name = azurerm_network_security_group.abhijitsg1.name
}

resource "azurerm_subnet_network_security_group_association" "abhijitsga" {
  subnet_id                 = azurerm_subnet.abhijitsubnet1.id
  network_security_group_id = azurerm_network_security_group.abhijitsg1.id
}


resource "azurerm_public_ip" "abhijitpip" {
  name                = "abhijitPublicIp1"
  resource_group_name = azurerm_resource_group.abhijitrg1.name
  location            = azurerm_resource_group.abhijitrg1.location
  allocation_method   = "Dynamic"

  tags = {
    environment = "dev"
  }
}


resource "azurerm_network_interface" "abhijitnic1" {
  name                = "abhijitnic1"
  resource_group_name = azurerm_resource_group.abhijitrg1.name
  location            = azurerm_resource_group.abhijitrg1.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.abhijitsubnet1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.abhijitpip.id
  }

  tags = {
    "environment" = "dev"
  }

}

resource "azurerm_linux_virtual_machine" "abhijitvm1" {
  name                  = "abhijitvm1"
  resource_group_name   = azurerm_resource_group.abhijitrg1.name
  location              = azurerm_resource_group.abhijitrg1.location
  size                  = "Standard_F2"
  admin_username        = "adminuser"
  network_interface_ids = [azurerm_network_interface.abhijitnic1.id]

  custom_data = filebase64("customdata.tpl")

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/abhijittfsshkey.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  provisioner "local-exec" {
    command = templatefile("${var.host_os}-ssh-script.tpl", {
      hostnamme    = self.public_ip_address,
      user         = "adminuser",
      identityfile = "~/.ssh/abhijittfsshkey"
    })
    interpreter = var.host_os == "windows" ? ["Powershell", "-Command"] : ["bash", "-c"]

  }
  tags = {
    "environment" = "dev"
  }

}

data "azurerm_public_ip" "abhijitipdata" {
  name                = azurerm_public_ip.abhijitpip.name
  resource_group_name = azurerm_resource_group.abhijitrg1.name
}

output "public_ip_address" {
  value = "${azurerm_linux_virtual_machine.abhijitvm1.name}: ${data.azurerm_public_ip.abhijitipdata.ip_address}"
}
