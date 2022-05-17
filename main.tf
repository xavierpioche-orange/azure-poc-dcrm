variable dc_vm_prefix {}
variable dc_env {}
variable dc_region {}
variable dc_nw_address_space {}
variable dc_nw_subnet {}
variable dc_vm_source_connection { default = "aaa.bbb.ccc.ddd" }

terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
  backend "azurerm" {
        resource_group_name  = "tfstate"
        storage_account_name = "tfstate92068321"
        container_name       = "tfstate"
        key                  = "terraform.tfstate"
    }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg-base" {
  name = "rg-${var.dc_env}-${var.dc_vm_prefix}"
  location = "${var.dc_region}"
}

resource "azurerm_virtual_network" "vn-base" {
  name                = "nw-${var.dc_env}-${var.dc_vm_prefix}"
  address_space       = ["${var.dc_nw_address_space}"]
  location            = azurerm_resource_group.rg-base.location
  resource_group_name = azurerm_resource_group.rg-base.name
}

resource "azurerm_subnet" "sn-base" {
  name                 = "sn-${var.dc_env}-${var.dc_vm_prefix}"
  resource_group_name  = azurerm_resource_group.rg-base.name
  virtual_network_name = azurerm_virtual_network.vn-base.name
  address_prefixes     = ["${var.dc_nw_subnet}"]
}

