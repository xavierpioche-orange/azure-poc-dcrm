variable dc_env {}
variable dc_vm_count {}
variable dc_vm_prefix {}
variable dc_vm_suffix {}
variable dc_vm_data_disk_size {}
variable dc_region {}
variable dc_vm_cpu_ram { default = "Standard_D2s_v3"}
variable dc_subnet_id {}

resource "random_password" "password-template" {
  length = 16
  special = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "azurerm_network_interface" "nic-xx-template" {
  count = "${var.dc_vm_count}"
  name                = "nic-${var.dc_env}-${var.dc_vm_prefix}-${var.dc_vm_suffix}${count.index + 1}"
  location            = "${var.dc_region}"
  resource_group_name = "rg-${var.dc_env}-${var.dc_vm_prefix}"

  ip_configuration {
    name                          = "nic-${var.dc_env}-${var.dc_vm_prefix}-${var.dc_vm_suffix}${count.index + 1}"
    subnet_id                     = var.dc_subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_managed_disk" "datadsk-xx-template" {
  count = "${var.dc_vm_count}"
  name                 = "datadsk-${var.dc_env}-${var.dc_vm_prefix}-${var.dc_vm_suffix}${count.index + 1}-disk1"
  location            = "${var.dc_region}"
  resource_group_name = "rg-${var.dc_env}-${var.dc_vm_prefix}"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "${var.dc_vm_data_disk_size}"
}

resource "azurerm_virtual_machine_data_disk_attachment" "datadsk-attach-xx-template" {
  count = "${var.dc_vm_count}"
  managed_disk_id    = azurerm_managed_disk.datadsk-xx-template[count.index].id
  virtual_machine_id = azurerm_windows_virtual_machine.vm_xx_template_as1[count.index].id
  lun                = "10"
  caching            = "ReadWrite"
}

resource "azurerm_windows_virtual_machine" "vm_xx_template_as1" {
  count = "${var.dc_vm_count}"
  name                = "${var.dc_env}-${var.dc_vm_prefix}-${var.dc_vm_suffix}${count.index + 1}"
  resource_group_name = "rg-${var.dc_env}-${var.dc_vm_prefix}"
  location            = "${var.dc_region}"
  size                = "${var.dc_vm_cpu_ram}" #2cpu 8Goram
  admin_username      = "osadmin"
  admin_password      = random_password.password-template.result
  network_interface_ids = [
    azurerm_network_interface.nic-xx-template[count.index].id,
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
  name = "powershell-${var.dc_env}-${var.dc_vm_prefix}--${var.dc_vm_suffix}${count.index + 1}" 
  virtual_machine_id = azurerm_windows_virtual_machine.vm_xx_template_as1[count.index].id
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

output "vms_name" {
  value = azurerm_windows_virtual_machine.vm_xx_template_as1.*.name 
}

output "vms_ip" {
  value = azurerm_network_interface.nic-xx-template.*.private_ip_addresses
}

output "vms_pass" {
  value = azurerm_windows_virtual_machine.vm_xx_template_as1.admin_password
  sensitive = true 
}