# Groundwork for Windows Server Failover Clustering lab environment

This template provides groundworks for the Windows Server Failover Clustering lab environment.

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2Ftksh164%2Fazure-demo-scripts-templates%2Fmaster%2Farm-templates%2Fgroundwork-wsfc%2Ftemplate.json)

## Deployment

- Domain controller VM
    - The AD DS feature and related management tools are installed.
    - The data disk for AD DS is formatted with drive letter `N:`.
- WSFC node 1 VM
    - The Failover Clustering feature and related management tools are installed.
    - The shared data disk for witness is formatted with drive letter `W:` if this VM's fault domain is equals `0`.
- WSFC node 2 VM
    - The Failover Clustering feature is installed.
    - The shared data disk for witness is formatted with drive letter `W:` if this VM's fault domain is equals `0`.
- Client VM

### Taks on the domain controller VM after the deployment

Use the following command in the domain contoller VM to make the VM to domain controller.

```powershell
Install-ADDSForest -DomainName lab.contoso.com -DatabasePath N:\Windows\NTDS -LogPath N:\Windows\NTDS -SysvolPath N:\Windows\SYSVOL -Force -Verbose
```

### Tasks on the WSFC node VMs after the deployment

Use the following command in the WSFC node VMs to join the VM to the lab.contoso.com domain.

```powershell
Add-Computer -DomainName lab.contoso.com -Restart -PassThru -Verbose
```

Use the following command in one of the WSFC node VM to make a new failover cluster.

```powershell
New-Cluster -Name clus1 -ManagementPointNetworkType Distributed -Node n1,n2
```

### Language settings changing scripts

You can use the language settings changing scripts if you want change the operating system's language settings. The language settings changing scripts for Japanese are located under the `C:\work`.

You should run the language settings changing scripts before server's role setup (e.g. Domain controller, Failover cluster node).

Steps for changing language settings:

1. Install the language pack and language capabilities by `lang-step1.ps1`. The system reboots after finish the script. This script takes few minutes for running.

    ```powershell
    cd C:\work
    .\lang-step1.ps1 lang-ws2019-jajp.psd1
    ```

2. Change language related settings by `lang-step2.ps1`. The system reboots after finish the script. This script takes less a minute for running.

    ```powershell
    cd C:\work
    .\lang-step2.ps1 lang-ws2019-jajp.psd1
    ```

## Notes

- The deploy.ps1 script needs [Az module](https://www.powershellgallery.com/packages/Az/).
