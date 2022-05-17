module "bastion" {
 source="./modules/bastion/"
 dc_env = "dv"
 dc_vm_prefix = "dcrm"
 dc_subnet_id = azurerm_subnet.sn-base.id
 dc_region = azurerm_resource_group.rg-base.location 
 dc_vm_source_connection = var.dc_vm_source_connection
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