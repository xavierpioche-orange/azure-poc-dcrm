module "front" {
 source="./modules/vm/"
 dc_env = "dv"
 dc_vm_count = 2
 dc_vm_prefix = "dcrm"
 dc_vm_suffix = "front"
 dc_vm_data_disk_size = 100
 dc_subnet_id = azurerm_subnet.sn-base.id
 dc_region = azurerm_resource_group.rg-base.location 
}

output "v_ip" {
  value = module.front.vms_ip
}

output "v_vms" {
    value = module.front.vms_name
}

output "v_pass" {
    value = module.front.vms_pass
}