/* -------------------------------------------------------------------------- */
/*                            ENVIRONMENT VARIABLES                           */
/* -------------------------------------------------------------------------- */

/* -------------------------------------------------------------------------- */
/*                             REQUIRED VARIABLES                             */
/* -------------------------------------------------------------------------- */

# Basic VM Configuration
variable "hostname" {
  type        = string
  description = "Virtual machine hostname."

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{1,63}$", var.hostname))
    error_message = "The hostname must be a valid DNS hostname, containing only alphanumeric characters and hyphens, and be no longer than 63 characters."
  }
}

variable "description" {
  type        = string
  description = "Description of the virtual machine being created."

  validation {
    condition     = length(var.description) > 0 && length(var.description) <= 255
    error_message = "The description must not be empty and should be no longer than 255 characters."
  }
}

variable "tags" {
  type        = list(string)
  description = "A list of tags to apply to the LXC container. The 'terraform' tag will be automatically added."

  validation {
    condition     = length(var.tags) > 0
    error_message = "At least one tag must be provided."
  }

  validation {
    condition     = alltrue([for tag in var.tags : can(regex("^[a-zA-Z0-9-_]+$", tag))])
    error_message = "Tags must only contain alphanumeric characters, hyphens, and underscores."
  }
}

/* -------------------------------------------------------------------------- */
/*                             OPTIONAL VARIABLES                             */
/* -------------------------------------------------------------------------- */

# VM Behavior
variable "agent" {
  type        = bool
  default     = true
  description = "Enable guest agent on the virtual machine."
}

variable "stop_on_destroy" {
  type        = bool
  default     = true
  description = "Whether to stop rather than shutdown on VM destroy."
}

# Startup Configuration
variable "startup_config" {
  type = object({
    order      = string
    up_delay   = string
    down_delay = string
  })
  default = {
    order      = "3"
    up_delay   = "60"
    down_delay = "60"
  }
  description = "Startup configuration for the VM."
}

# CPU Configuration
variable "cpu_cores" {
  type        = number
  default     = 1
  description = "Number of CPU cores to assign to the VM"

  validation {
    condition     = var.cpu_cores > 0 && var.cpu_cores <= 8
    error_message = "The number of CPU cores must be between 1 and 8."
  }
}

variable "cpu_sockets" {
  type        = number
  default     = 1
  description = "Number of CPU sockets to assign to the VM"

  validation {
    condition     = var.cpu_sockets > 0 && var.cpu_sockets <= 2
    error_message = "The number of CPU sockets must be 1 or 2."
  }
}

# Template Information

variable "template_datastore" {
  type        = string
  default     = "pve-sys"
  description = "Datastore where template image is stored."
}

variable "template_type" {
  type        = string
  default     = "iso"
  description = "The type of template."

  validation {
    condition     = contains(["iso", "vztmpl", "vm", "cloudinit"], var.template_type)
    error_message = "Invalid template type. Allowed values are 'iso', 'vztmpl', 'vm', or 'cloudinit'."
  }
}

variable "template_name" {
  type        = string
  description = "Name of template to deploy"

  validation {
    condition     = length(trimspace(var.template_name)) > 0
    error_message = "The template_name cannot be empty or contain only whitespace."
  }
}

# Memory Configuration
variable "memory_mb" {
  type        = number
  default     = 512
  description = "Amount of memory to assign the VM (in megabytes)"

  validation {
    condition     = var.memory_mb >= 512 && var.memory_mb <= 8192
    error_message = "The amount of memory assigned must be between 512 and 8192 megabytes."
  }
}

# Storage Configuration
variable "datastore" {
  type        = string
  default     = "local-lvm"
  description = "Name of Data store to create the VM on."
}

variable "disk_size" {
  type        = number
  default     = 20
  description = "The OS disk size in gigabytes"

  validation {
    condition     = var.disk_size >= 16 && var.disk_size <= 256
    error_message = "The disk size must be between 16 and 256 gigabytes."
  }
}

variable "data_disks" {
  type = list(object({
    datastore_id = string
    size         = number
    interface    = optional(string)
  }))
  default     = []
  description = "The disk configuration for the VM."
}

# Network Configuration
variable "ip_addresses" {
  type = list(object({
    address = string
    gateway = optional(string)
  }))
  default     = []
  description = "The IPv4 configuration for each network interface"
}

variable "network_devices" {
  type = set(object({
    bridge      = string
    enabled     = bool
    firewall    = bool
    mac_address = string
    model       = string
    vlan_id     = string
    name        = string
  }))
  default = [{
    bridge      = "vmbr0"
    enabled     = true
    firewall    = false
    mac_address = null
    model       = "virtio"
    vlan_id     = null
    name        = null
  }]
  description = "The list of network interfaces"
}

variable "dns_domain" {
  type        = string
  default     = "example.com"
  description = "The DNS search domain."
}

variable "dns_servers" {
  type        = list(string)
  default     = ["1.1.1.1", "8.8.8.8"]
  description = "The list of DNS servers."
}

variable "user_data_file" {
  type    = string
  default = "pve-sys:snippets/cloud-config-ubuntu.yaml"
}

# Cloud-Init Configuration
variable "cloud_init" {
  type        = string
  default     = null
  description = "Path to the cloud-init config"
}

variable "cloud_config_datastore" {
  default     = "pve-sys"
  description = "Datastore where cloud-config is stored."
}
