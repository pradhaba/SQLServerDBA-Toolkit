terraform {
  required_version = ">= 1.6.0"
  required_providers {
    hyperv = {
      source  = "taliesins/hyperv"
      version = "~> 1.2"
    }
  }

  # Store state in repo — swap for remote backend (S3/Azure) in production
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "hyperv" {
  user     = var.hyperv_user
  password = var.hyperv_password
  host     = var.hyperv_host
  port     = 5986
  https    = true
  insecure = true   # self-signed cert on host WinRM
  use_ntlm = true
  timeout  = "60s"
}

# ── Internal virtual switch (matches your static network) ──────────────────
resource "hyperv_network_switch" "lab_switch" {
  source  = "taliesins/hyperv"
  name                              = "SQLLabSwitch"
  switch_type                       = "Internal"
  allow_management_os               = true
  default_flow_minimum_bandwidth_mbps = 0
}

# ── Domain Controller ───────────────────────────────────────────────────────
module "dc01" {
  source       = "./modules/vm"
  name         = "dc-01"
  cpus         = var.dc_cpus
  memory_mb    = var.dc_memory_mb
  os_disk_gb   = 60
  vhd_path     = "${var.vhd_base_path}\\dc-01-os.vhdx"
  iso_path     = var.ws2022_iso_path
  switch_name  = hyperv_network_switch.lab_switch.name
  mac_address  = "00:15:5D:01:0A:0A"   # maps to 192.168.10.10
}

# ── SQL Server Primary ──────────────────────────────────────────────────────
module "sql01" {
  source        = "./modules/vm"
  name          = "sql-01"
  cpus          = var.sql_cpus
  memory_mb     = var.sql_memory_mb
  os_disk_gb    = 80
  data_disk_gb  = 50       # dedicated data/log disk
  vhd_path      = "${var.vhd_base_path}\\sql-01-os.vhdx"
  data_vhd_path = "${var.vhd_base_path}\\sql-01-data.vhdx"
  iso_path      = var.ws2022_iso_path
  switch_name   = hyperv_network_switch.lab_switch.name
  mac_address   = "00:15:5D:01:0A:15"  # maps to 192.168.10.21
}

# ── SQL Server Secondary ────────────────────────────────────────────────────
module "sql02" {
  source        = "./modules/vm"
  name          = "sql-02"
  cpus          = var.sql_cpus
  memory_mb     = var.sql_memory_mb
  os_disk_gb    = 80
  data_disk_gb  = 50
  vhd_path      = "${var.vhd_base_path}\\sql-02-os.vhdx"
  data_vhd_path = "${var.vhd_base_path}\\sql-02-data.vhdx"
  iso_path      = var.ws2022_iso_path
  switch_name   = hyperv_network_switch.lab_switch.name
  mac_address   = "00:15:5D:01:0A:16"  # maps to 192.168.10.22
}

# ── File Share Witness ──────────────────────────────────────────────────────
module "witness01" {
  source      = "./modules/vm"
  name        = "witness-01"
  cpus        = var.witness_cpus
  memory_mb   = var.witness_memory_mb
  os_disk_gb  = 40
  vhd_path    = "${var.vhd_base_path}\\witness-01-os.vhdx"
  iso_path    = var.ws2022_iso_path
  switch_name = hyperv_network_switch.lab_switch.name
  mac_address = "00:15:5D:01:0A:1E"   # maps to 192.168.10.30
}
