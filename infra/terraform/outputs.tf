output "dc01_name" {
  value = module.dc01.vm_name
}

output "sql01_name" {
  value = module.sql01.vm_name
}

output "sql02_name" {
  value = module.sql02.vm_name
}

output "witness01_name" {
  value = module.witness01.vm_name
}

output "lab_switch_name" {
  value = hyperv_network_switch.lab_switch.name
}

# Summary block — useful for README / Ansible inventory generation
output "vm_summary" {
  value = {
    dc01      = { name = module.dc01.vm_name,      ip = "192.168.10.10" }
    sql01     = { name = module.sql01.vm_name,     ip = "192.168.10.21" }
    sql02     = { name = module.sql02.vm_name,     ip = "192.168.10.22" }
    witness01 = { name = module.witness01.vm_name, ip = "192.168.10.30" }
  }
}
