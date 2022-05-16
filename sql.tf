module "sql" {
 source="./modules/vm/"
 dc_env = "dv"
 dc_vm_count = 2
 dc_vm_prefix = "dcrm"
 dc_vm_suffix = "sql"
 dc_vm_data_disk_size = 500
 dc_subnet_id = azurerm_subnet.sn-base.id
 dc_region = azurerm_resource_group.rg-base.location 
}


output "sql_ip" {
  value = module.sql.vms_ip
}

output "sql_vms" {
    value = module.sql.vms_name
}

output "sql_pass" {
    value = module.sql.vms_pass
}