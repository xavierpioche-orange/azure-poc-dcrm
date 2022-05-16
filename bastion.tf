variable dc_vm_source_connection {}

resource "random_password" "password-bastion" {
  length = 16
  special = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "azurerm_network_interface" "nic-xx-proj-bastion" {
  name                = "nic-${var.dc_env}-${var.dc_vm_prefix}-bastion"
  location            = azurerm_resource_group.rg-base.location
  resource_group_name = azurerm_resource_group.rg-base.name

  ip_configuration {
    name                          = "nic-${var.dc_env}-${var.dc_vm_prefix}-bastion"
    subnet_id                     = azurerm_subnet.sn-base.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.ip-public-xx-proj-bastion.id 

  }
}

resource "azurerm_public_ip" "ip-public-xx-proj-bastion" {
  name                = "ip-public-${var.dc_env}-${var.dc_vm_prefix}-bastion"
  resource_group_name = azurerm_resource_group.rg-base.name
  location            = azurerm_resource_group.rg-base.location
  allocation_method   = "Static"
}

resource "azurerm_network_security_group" "nsg-xx-proj-bastion" {
  name                = "nsg_rdp_${var.dc_env}-${var.dc_vm_prefix}-bastion"
  location            = azurerm_resource_group.rg-base.location
  resource_group_name = azurerm_resource_group.rg-base.name

  security_rule {
    name                       = "allow_rdp_nsg_${var.dc_env}-${var.dc_vm_prefix}_bastion"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefixes    = ["${var.dc_vm_source_connection}"]
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "nsg-public-ip-association-bastion" {
  network_interface_id      = azurerm_network_interface.nic-xx-proj-bastion.id
  network_security_group_id = azurerm_network_security_group.nsg-xx-proj-bastion.id
}

resource "azurerm_windows_virtual_machine" "vm_xx_proj_bastion" {
  name                = "${var.dc_env}-${var.dc_vm_prefix}-bastion"
  resource_group_name = azurerm_resource_group.rg-base.name
  location            = azurerm_resource_group.rg-base.location
  size                = "Standard_D2s_v3"
  admin_username      = "mydmin"
  admin_password      = random_password.password-bastion.result
  network_interface_ids = [
    azurerm_network_interface.nic-xx-proj-bastion.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-10"
    sku       = "win10-21h2-pro-g2"
    version   = "latest"
  }
}

resource "azurerm_virtual_machine_extension" "vm_xx_proj_bastion_powershell" {
  name = "powershell-${var.dc_env}-${var.dc_vm_prefix}-bastion" 
  virtual_machine_id = azurerm_windows_virtual_machine.vm_xx_proj_bastion.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"
  settings = <<EOF
       { 
          "commandToExecute": "powershell -command \"[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('${base64encode(data.template_file.tf.rendered)}')) | Out-File -filepath install.ps1\" && powershell -ExecutionPolicy Unrestricted -File install.ps1"
       }
EOF

depends_on = [
    azurerm_windows_virtual_machine.vm_xx_proj_bastion
  ]
}

data "template_file" "tf" {
  template = "${file("install.ps1")}"
}

output "bastion_ip" {
   value = azurerm_network_interface.nic-xx-proj-bastion.private_ip_addresses
}

output "vms_pass" {
  value = azurerm_windows_virtual_machine.vm_xx_proj_bastion.admin_password
  sensitive = true 
}