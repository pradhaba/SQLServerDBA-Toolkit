variable "name"          { type = string }
variable "cpus"          { type = number }
variable "memory_mb"     { type = number }
variable "os_disk_gb"    { type = number }
variable "data_disk_gb"  {
   type = number
   default = 0 
}
variable "vhd_path"      { type = string }
variable "data_vhd_path" { 
  type = string
  default = "" 
}
variable "iso_path"      { type = string }
variable "switch_name"   { type = string }
variable "mac_address"   { type = string }

# ── OS disk ─────────────────────────────────────────────────────────────────
resource "hyperv_vhd" "os_disk" {
  path = var.vhd_path
  size = var.os_disk_gb * 1024 * 1024 * 1024   # bytes
}

# ── Optional data disk (SQL VMs only) ───────────────────────────────────────
resource "hyperv_vhd" "data_disk" {
  count = var.data_disk_gb > 0 ? 1 : 0
  path  = var.data_vhd_path
  size  = var.data_disk_gb * 1024 * 1024 * 1024
}

# ── Virtual machine ──────────────────────────────────────────────────────────
resource "hyperv_machine_instance" "vm" {
  name                   = var.name
  generation             = 2
  processor_count        = var.cpus
  static_memory          = true
  memory_startup_bytes   = var.memory_mb * 1024 * 1024
  checkpoint_type        = "Disabled"
  automatic_start_action = "StartIfRunning"
  automatic_stop_action  = "ShutDown"
  smart_paging_file_path = "C:\\HyperV\\SmartPaging"
  snapshot_file_location = "C:\\HyperV\\Snapshots"

  # Boot from ISO first, then VHDX
  vm_firmware {
    enable_secure_boot   = "On"
    secure_boot_template = "MicrosoftWindows"
    boot_order {
      boot_type           = "DvdDrive"
      controller_number   = 0
      controller_location = 1
    }
    boot_order {
      boot_type           = "HardDiskDrive"
      controller_number   = 0
      controller_location = 0
    }
  }

  vm_processor {
    expose_virtualization_extensions = false   # set true if nesting VMs
  }

  # OS disk
  hard_disk_drives {
    controller_type     = "Scsi"
    controller_number   = 0
    controller_location = 0
    path                = hyperv_vhd.os_disk.path
  }

  # Data disk (SQL VMs)
  dynamic "hard_disk_drives" {
    for_each = var.data_disk_gb > 0 ? [1] : []
    content {
      controller_type     = "Scsi"
      controller_number   = 0
      controller_location = 1
      path                = hyperv_vhd.data_disk[0].path
    }
  }

  # DVD drive — ISO for initial OS install
  dvd_drives {
    controller_number   = 0
    controller_location = 1
    path                = var.iso_path
  }

  # NIC with static MAC so DHCP reservation maps to fixed IP
  network_adaptors {
    name                = "LAN"
    switch_name         = var.switch_name
    static_mac_address  = var.mac_address
    wait_for_ips        = false
  }
}

output "vm_name" {
  value = hyperv_machine_instance.vm.name
}

import {
  to = hyperv_network_switch.lab_switch
  id = "SQLLabSwitch"
}