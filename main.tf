/* -------------------------------------------------------------------------- */
/*                                   LOCALS                                   */
/* -------------------------------------------------------------------------- */

locals {
  # Default configurations
  default_network_device = {
    bridge      = "vmbr0"
    enabled     = true
    firewall    = false
    mac_address = null
    model       = "virtio"
    vlan_id     = null
  }

  default_disk_config = {
    interface = "virtio"
  }

  default_ip_config = {
    address = "dhcp"
  }

  # Template file extensions
  template_extension = {
    "iso"       = "img"
    "vztmpl"    = "tar.gz"
    "vm"        = "qcow2"
    "cloudinit" = "img"
  }[var.template_type]

  # Merged configurations
  network_devices      = [for device in var.network_devices : merge(local.default_network_device, device)]
  ip_configs           = [for ip in var.ip_addresses : merge(local.default_ip_config, ip)]
  selected_node        = one(random_shuffle.node.result)
  cloud_config_content = file(var.cloud_init)
  normalized_data_disks = [
    for disk in var.data_disks :
    merge(local.default_disk_config, disk)
  ]

  # Tags normalization
  normalized_tags = distinct(concat(var.tags, ["terraform"]))
}

/* -------------------------------------------------------------------------- */
/*                            PROXMOX NODE SELECTION                          */
/* -------------------------------------------------------------------------- */

# Return all nodes in the proxmox cluster
data "proxmox_virtual_environment_nodes" "available_nodes" {}

# Choose a random node from the cluster
resource "random_shuffle" "node" {
  input        = data.proxmox_virtual_environment_nodes.available_nodes.names
  result_count = 1
}

/* -------------------------------------------------------------------------- */
/*                            CLOUD-INIT CONFIGURATION                        */
/* -------------------------------------------------------------------------- */

# Generate a random ID for cloud-init
resource "random_id" "cloud_config" {
  keepers = {
    cloud_config = var.cloud_init
  }

  byte_length = 16
}

# Upload cloud-init file with random ID
resource "proxmox_virtual_environment_file" "cloud_config" {
  content_type = "snippets"
  datastore_id = var.cloud_config_datastore
  node_name    = local.selected_node

  source_raw {
    data = local.cloud_config_content

    file_name = "${random_id.cloud_config.id}.yaml"
  }
  depends_on = [random_shuffle.node]
}

/* -------------------------------------------------------------------------- */
/*                           VIRTUAL MACHINE RESOURCE                         */
/* -------------------------------------------------------------------------- */

# Create Virtual Machine
resource "proxmox_virtual_environment_vm" "vm" {
  name        = var.hostname
  description = var.description
  tags        = local.normalized_tags

  node_name = local.selected_node
  #vm_id     = ""

  # Agent configuration
  agent {
    enabled = var.agent
  }

  stop_on_destroy = var.stop_on_destroy

  # Startup configuration
  startup {
    order      = var.startup_config.order
    up_delay   = var.startup_config.up_delay
    down_delay = var.startup_config.down_delay
  }

  # CPU configuration
  cpu {
    cores   = var.cpu_cores
    sockets = var.cpu_sockets
  }

  # Memory configuration
  memory {
    dedicated = var.memory_mb
  }

  # OS Disk
  disk {
    datastore_id = var.datastore
    file_id      = "${var.template_datastore}:${var.template_type}/${var.template_name}.${local.template_extension}"
    interface    = "virtio0"
    size         = var.disk_size
  }

  # DATA disks
  dynamic "disk" {
    for_each = { for idx, disk in local.normalized_data_disks : idx => disk }
    content {
      datastore_id = disk.value.datastore_id
      size         = disk.value.size
      interface    = "virtio${disk.key + 1}"
      file_format  = "raw"
    }
  }

  # Network devices
  dynamic "network_device" {
    for_each = local.network_devices
    iterator = network
    content {
      bridge = network.value.bridge
      # enabled     = network.value.enabled
      # firewall    = network.value.firewall
      # mac_address = network.value.mac_address
      # model       = network.value.model
      # vlan_id     = network.value.vlan_id
    }
  }

  # Initialization
  initialization {
    # DNS configuration
    dns {
      domain  = var.dns_domain
      servers = var.dns_servers
    }

    # IP configuration
    ip_config {
      dynamic "ipv4" {
        for_each = var.ip_addresses != null ? var.ip_addresses : []
        content {
          address = ipv4.value.address
          gateway = ipv4.value.gateway
        }
      }

      dynamic "ipv4" {
        for_each = var.ip_addresses == null ? [1] : []
        content {
          address = "dhcp"
        }
      }

    }

    user_data_file_id = proxmox_virtual_environment_file.cloud_config.id
  }

  depends_on = [random_shuffle.node]

  # Lifecycle management
  lifecycle {
    ignore_changes = [
      hostpci,
    ]
  }
}
