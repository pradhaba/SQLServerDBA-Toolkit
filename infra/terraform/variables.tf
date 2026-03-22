# ── Hyper-V host connection ─────────────────────────────────────────────────
variable "hyperv_host" {
  description = "IP of the Windows 11 Hyper-V host"
  type        = string
  default     = "192.168.10.1"
}

variable "hyperv_user" {
  description = "Local administrator on the Hyper-V host"
  type        = string
  default     = "Administrator"
}

variable "hyperv_password" {
  description = "Password for Hyper-V host admin — injected via GitHub secret"
  type        = string
  sensitive   = true
}

# ── Paths ───────────────────────────────────────────────────────────────────
variable "vhd_base_path" {
  description = "Windows path on the host where VHDx files are stored"
  type        = string
  default     = "C:\\HyperV\\VHDs"
}

variable "ws2022_iso_path" {
  description = "Windows path to the Windows Server 2022 ISO"
  type        = string
  default     = "C:\\ISOs\\WS2022_EVAL.iso"
}

# ── Domain Controller sizing ─────────────────────────────────────────────────
variable "dc_cpus" {
  type    = number
  default = 2
}

variable "dc_memory_mb" {
  type    = number
  default = 4096
}

# ── SQL Server sizing ────────────────────────────────────────────────────────
variable "sql_cpus" {
  type    = number
  default = 4
}

variable "sql_memory_mb" {
  type    = number
  default = 8192
}

# ── Witness sizing ───────────────────────────────────────────────────────────
variable "witness_cpus" {
  type    = number
  default = 2
}

variable "witness_memory_mb" {
  type    = number
  default = 2048
}
