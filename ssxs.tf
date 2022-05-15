module "ssxs" {
 source="modules/vm/"
 dc_env = "dv"
 dc_vm_count = 2
 dc_vm_prefix = "dcrm"
 dc_vm_suffix = "ssxs"
 dc_vm_data_disk_size = 300
}