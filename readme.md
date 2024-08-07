# Proxmox VM Terraform Module

This Terraform module allows you to create and manage virtual machines in Proxmox VE.

## Features

- Dynamic VM creation with customizable settings
- Support for multiple network devices and data disks
- Cloud-init integration
- Automatic node selection within a Proxmox cluster

## Usage

Here's a basic example of how to use this module:

```hcl
module "proxmox_vm" {
  source = "path/to/this/module"

  hostname    = "my-vm"
  description = "My Proxmox VM created with Terraform"
  tags        = ["prod", "web"]

  template_name      = "ubuntu-cloud-init"
  template_type      = "iso"
  template_datastore = "local"

  cpu_cores   = 2
  cpu_sockets = 1
  memory_mb   = 2048
  disk_size   = 32

  # Optional
  network_devices = [
    {
      bridge      = "vmbr0"
      vlan_id     = "10"
      mac_address = "02:01:02:03:04:05"
    }
  ]

  # Optional, defaults to DHCP
  ip_addresses = [
    {
      address = "192.168.1.100"
      gateway = "192.168.1.1"
    }
  ]

  dns_servers = ["8.8.8.8", "8.8.4.4"]
  dns_domain  = "example.com"

  cloud_init = "path/to/your/cloud-init.yml"
}
