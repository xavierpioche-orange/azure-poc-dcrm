module "bastion" {
 source="./modules/bastion/"
 dc_env = "dv"
 dc_vm_count = 1
 dc_vm_prefix = "dcrm"
 dc_vm_suffix = "bastion"
 dc_vm_data_disk_size = 50
 dc_subnet_id = azurerm_subnet.sn-base.id
 dc_region = azurerm_resource_group.rg-base.location 
 dc_vm_source_connection = "AAA.BBB.CCC.DDD"
}


output "bastion_priv_ip" {
  value = module.bastion.bastion_priv_ip
}


output "bastion_pub_ip" {
    value = module.bastion.bastion_pub_ip
}

output "bastion_pass" {
    value = module.bastion.bastion_pass
    sensitive = true
}