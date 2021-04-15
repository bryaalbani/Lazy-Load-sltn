provider "azurerm" {
    version = "=2.37.0"
    features {}
}



#Definimos el grupo de recursos

resource "azurerm_resource_group" "rg" {
    name = var.resource_group_name
    location = var.resource_group_location

    tags = {
        environment = "production"
    }
}

# Creamos la red virtual

resource "azurerm_virtual_network" "vnet" {

    name = var.virtual_network_name
    address_space = ["10.0.0.0/16"]
    location = azurerm_resource_group.location
    resource_group_name = azurerm_resource_group.rg.name

     tags = {
        environment = "production"
     }
}


#Creamos la sub red

resource "azurerm_subnet" "subnet"
    name = var.subnet_name
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes = ["10.0.1.0/24"]

   
#Creamos la IP publica

resource "azurerm_public_ip" "public_ip" {  
    name = var.public_ip_name
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    allocation_method = "Dynamic"

     tags = {
        environment = "production"
     }
}

#Crear el grupo de seguridad de red and la regla

resource "azurerm_network_security_group" "nsg" {
    name = var.network_security_group_name
    location = azurerm_resource_group.location
    resource_group_name = azurerm_resource_group.rg.name    

    security_rule = [ {
      name = "SHH"
      priority = 1001
      direction = "Inboud"
      access = "Allow"
      protocol = "Tcp"
      source_port_range = "*"
      destination_port_range = "22"
      source_address_prefix = "*"
      destination_address_prefix = "*"

    } ]
  
        tags = {
        environment = "production"
     }
}

#Crear la interfaz de red

resource "azurerm_network_interface" "nic" {
    name = var.network_interface_name
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name

    ip_configuration {
        name = "myNicConfiguration"
        subnet_id = azurerm_subnet.subnet.id
        private_id_address_allocation = "Dynamic"
        public_ip_address_id = azurerm_public_id.public_ip.id
    }

        tags = {
        environment = "production"
     }
}

# conectar el grupo de seguridad a la iterfaz de red

resource "azurerm_network_interface_security_group_association" "association" {

    network_interface_id = azurerm_network_interface.nic.id
    network_security_group_id = azurerm_network_security_group.nsg.id
  
}

#generara random text para una unico nombre de cuenta de almacenamiento

resource "random_id" "randomId" {

    keeper = {
        resource_group_name = azurerm_resource_group.resource_group.rg.name
    }
    byte_length = 8
}

#crear cuenta de almacenamiento para boot diagnostic

resource "azurerm_storage_account" "storage" {
    name = diag${random_id.randomId.hex}
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    account_tier = "Standard"
    account_account_replication_type = "LRS"

    tags = {
        environment = "production"
     }
}

#Crear una SSH key

resource "tls_private_key" "example_ssh" {

    algoalgorithm = "RSA"
    rsarsa_bits = 4096
}
output "tls_private_key" { value = tls_private_key.example_ssh.private_key_pem }

#Crear maquina virtual

resource "azurerm_linux_virtual_machine" "linuxvm" {

    name = var.linux_virtual_machine_name
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    network_interface_ids = [ azurerm_network_interface.nic.id ]
    size = "Standard_DS1_v2"

    os_disk {

        name = "myOsDisk"
        caching = "ReadWrite"
        storage_account_type = "Premium_LRS"

    }

    source_image_reference {

        publisher = "Canonical"
        offer = "UbuntuServer"
        sku = "18.04-LTS"
        version = "latest"
    }

    computer_name = "myvm"
    admin_username = "azureuser"
    disable_password_authentication = true

    admin_ssh_key {

        username = "azureuser"
        public_key = tls_private_key.example_ssh.public_key_openssh
    }
    boot_diagnostics {

        storage_account_uri = azurerm_storage_account.storage.primary_blob_endpoint
    }

    tags = {

        environment = "production"
    }
}


     
