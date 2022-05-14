variable dc_env {}
variable dc_vm_count {}
variable dc_vm_prefix {}
variable dc_vm_suffix {}
variable dc_vm_data_disk_size {}
variable dc_vm_cpu_ram { default = "Standard_D2s_v3"}

resource "azurerm_network_interface" "nic-xx-template" {
  count = "${var.dc_vm_count}"
  name                = "nic-${var.dc_env}-${var.dc_vm_prefix}-${var.dc_vm_suffix}${var.count.index + 1}"
  location            = azurerm_resource_group.rg-base.location
  resource_group_name = azurerm_resource_group.rg-base.name

  ip_configuration {
    name                          = "nic-${var.dc_env}-${var.dc_vm_prefix}-${var.dc_vm_suffix}${var.count.index + 1}"
    subnet_id                     = azurerm_subnet.sn-base.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_managed_disk" "datadsk-xx-template" {
  count = "${var.dc_vm_count}"
  name                 = "datadsk-${var.dc_env}-${var.dc_vm_prefix}-${var.dc_vm_suffix}${var.count.index + 1}-disk1"
  location             = azurerm_resource_group.rg-base.location
  resource_group_name  = azurerm_resource_group.rg-base.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "${var.dc_vm_data_disk_size}"
}

resource "azurerm_virtual_machine_data_disk_attachment" "datadsk-attach-xx-template" {
  managed_disk_id    = azurerm_managed_disk.datadsk-xx-template.id
  virtual_machine_id = azurerm_windows_virtual_machine.vm_xx_template_as1.id
  lun                = "10"
  caching            = "ReadWrite"
}

resource "azurerm_windows_virtual_machine" "vm_xx_template_as1" {
  count = "${var.dc_vm_count}"
  name                = "${var.dc_env}-${var.dc_vm_prefix}-${var.dc_vm_suffix}${var.count.index + 1}"
  resource_group_name = azurerm_resource_group.rg-base.name
  location            = azurerm_resource_group.rg-base.location
  size                = "${var.dc_vm_cpu_ram}" #2cpu 8Goram
  admin_username      = "osadmin"
  admin_password      = "AdmPlat1369=NoW@y"
  network_interface_ids = [
    azurerm_network_interface.nic-xx-template.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}

resource "azurerm_virtual_machine_extension" "vm_xx_template_as1_powershell" {
  count = "${var.dc_vm_count}"
  name = "powershell-${var.dc_env}-${var.dc_vm_prefix}--${var.dc_vm_suffix}${var.count.index + 1}" 
  virtual_machine_id = azurerm_windows_virtual_machine.vm_xx_template_as1.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"
  settings = <<EOF
       { 
          "commandToExecute": "powershell -command \"[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('${base64encode(data.template_file.tf.rendered)}')) | Out-File -filepath install.ps1\" && powershell -ExecutionPolicy Unrestricted -File install.ps1"
       }
EOF

depends_on = [
    azurerm_windows_virtual_machine.vm_xx_template_as1
  ]
}

data "template_file" "tf" {
  template = "${file("install.ps1")}"
}