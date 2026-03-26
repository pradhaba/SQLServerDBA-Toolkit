# SQLServerDBA-Toolkit

Production-grade SQL Server DBA portfolio built on:
- Hyper-V (Windows 11 host)
- Terraform (VM provisioning via WinRM)
- Ansible (OS + SQL Server configuration)
- GitHub Actions CI (self-hosted runner on RHEL 9)

## VM topology
| VM | Role | IP |
|---|---|---|
| dc-01 | Domain Controller | 192.168.100.10 |
| sql-01 | SQL Server 2022 Primary | 192.168.100.11 |
| sql-02 | SQL Server 2022 Secondary | 192.168.100.12 |
| witness-01 | File Share Witness | 192.168.100.13 |
| linux-runner | RHEL 9 CI Runner | 192.168.100.30 |
