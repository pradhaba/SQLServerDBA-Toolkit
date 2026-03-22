# SQLServerDBA-Toolkit

Production-grade SQL Server DBA portfolio demonstrating enterprise-level
database administration skills using Infrastructure as Code.

## Stack

| Layer | Tool | Purpose |
|---|---|---|
| Infra provisioning | Terraform + HyperV provider | Create 4 VMs on Windows 11 Hyper-V |
| Configuration | Ansible + WinRM | OS setup, domain join, SQL install, AG config |
| CI/CD | GitHub Actions (self-hosted) | Plan/lint on PR, apply on manual trigger |
| Runner | RHEL 9 VM (192.168.10.5) | Executes all automation |

## VM Topology

```
192.168.10.0/24  —  SQLLabSwitch (Hyper-V internal switch)

  192.168.10.1    Windows 11 host (Hyper-V)
  192.168.10.5    linux-runner  — RHEL 9 CI runner (this machine)
  192.168.10.10   dc-01         — Windows Server 2022, AD DS + DNS
  192.168.10.21   sql-01        — Windows Server 2022, SQL Server 2022 (primary)
  192.168.10.22   sql-02        — Windows Server 2022, SQL Server 2022 (secondary)
  192.168.10.30   witness-01    — Windows Server 2022, file share witness
  192.168.10.50   AG listener   — sql-ag-listener (virtual IP, AG only)
```

## Repository Structure

```
SQLServerDBA-Toolkit/
├── infra/
│   ├── terraform/
│   │   ├── main.tf                    VM definitions (all 4 VMs)
│   │   ├── variables.tf               Input variables
│   │   ├── outputs.tf                 VM names + IPs
│   │   ├── terraform.tfvars.example   Safe-to-commit config template
│   │   └── modules/vm/main.tf         Reusable VM module
│   └── ansible/
│       ├── ansible.cfg
│       ├── inventory/hosts.yml        Static inventory (all VMs)
│       ├── group_vars/
│       │   ├── all.yml                Shared vars (domain, SQL, AG)
│       │   └── vault.yml              Encrypted secrets (ansible-vault)
│       └── playbooks/
│           ├── 01_domain_controller.yml
│           ├── 02_domain_join.yml
│           ├── 03_sql_install.yml
│           ├── 04_ag_setup.yml
│           └── 05_witness.yml
└── .github/workflows/
    ├── terraform-plan.yml             Runs on every PR touching terraform/
    ├── terraform-apply.yml            Manual trigger only
    └── ansible-lint.yml              Runs on every PR touching ansible/
```

## Prerequisites

### On the RHEL 9 runner (one-time setup)
```bash
# Tools
sudo dnf install -y terraform ansible-core gh git
pip3 install pywinrm requests-ntlm ansible-lint
ansible-galaxy collection install ansible.windows community.windows microsoft.ad

# Self-hosted runner — register via GitHub UI
# Repo > Settings > Actions > Runners > New self-hosted runner
```

### On the Windows 11 Hyper-V host (one-time setup)
```powershell
# Enable WinRM for Terraform provider
winrm quickconfig -q
Enable-PSRemoting -Force
winrm set winrm/config/service/Auth '@{Basic="true"}'

# Firewall — allow WinRM from runner only
New-NetFirewallRule -DisplayName "WinRM RHEL runner" `
  -Direction Inbound -Protocol TCP `
  -LocalPort 5985,5986 -RemoteAddress 192.168.10.5 -Action Allow

# Create VHD and ISO directories
New-Item -ItemType Directory -Path C:\HyperV\VHDs, C:\ISOs -Force
```

### GitHub secrets required
| Secret | Value |
|---|---|
| `HYPERV_HOST` | `192.168.10.1` |
| `HYPERV_USER` | `Administrator` |
| `HYPERV_PASSWORD` | Windows 11 admin password |
| `SQL_SA_PASSWORD` | SQL SA password |
| `ANSIBLE_VAULT_PASS` | Ansible vault password |

## Deployment — step by step

### Step 1 — Provision VMs with Terraform
```bash
# On the RHEL 9 runner
cd infra/terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your passwords

terraform init
terraform plan
terraform apply
```

Or trigger via GitHub Actions:
- Go to **Actions > Terraform apply > Run workflow**
- Type `APPLY` in the confirmation box

### Step 2 — Install Windows Server 2022
Boot each VM from the ISO and complete the Windows setup wizard.
Set the local Administrator password to match `vault_windows_admin_password` in your vault.

### Step 3 — Run Ansible playbooks in order
```bash
cd infra/ansible

# 3a. Promote dc-01
ansible-playbook playbooks/01_domain_controller.yml

# 3b. Join sql-01, sql-02, witness-01 to domain
ansible-playbook playbooks/02_domain_join.yml

# 3c. Install SQL Server 2022 on both SQL VMs
ansible-playbook playbooks/03_sql_install.yml

# 3d. Create Always On Availability Group
ansible-playbook playbooks/04_ag_setup.yml

# 3e. Configure file share witness
ansible-playbook playbooks/05_witness.yml
```

### Step 4 — Verify
```bash
# Check AG health from primary
ansible sql_primary -i inventory/hosts.yml -m win_powershell -a \
  "script='Invoke-Sqlcmd -Query \"SELECT replica_server_name, role_desc, synchronization_health_desc FROM sys.dm_hadr_availability_replica_states ars JOIN sys.availability_replicas ar ON ars.replica_id = ar.replica_id\" -TrustServerCertificate | Format-Table'"
```

## DBA Modules (SQL scripts + automation)

See `/01_HA_DR`, `/02_Perf_Tuning`, `/03_Backup_DR`, `/04_Automation`,
`/05_Security` for the full DBA toolkit built on top of this infrastructure.

## License
MIT
