module "back" {
 source="./modules/vm/"
 dc_env = "dv"
 dc_vm_count = 1
 dc_vm_prefix = "dcrm"
 dc_vm_suffix = "back"
 dc_vm_data_disk_size = 300
 dc_subnet_id = azurerm_subnet.sn-base.id
 dc_region = azurerm_resource_group.rg-base.location 
}


output "back_ip" {
  value = module.back.vms_ip
}

output "back_vms" {
    value = module.back.vms_name
}

output "back_pass" {
    value = module.back.vms_pass
    sensitive = true
}