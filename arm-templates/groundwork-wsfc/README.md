# Groundwork for Windows Server Failover Clustering lab environment

This template provides groundworks for the Windows Server Failover Clustering lab environment.

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2Ftksh164%2Fazure-demo-scripts-templates%2Fmaster%2Farm-templates%2Fgroundwork-wsfc%2Ftemplate.json)

## Deployment

- Domain controller VM
    - The AD DS feature and related management tools are installed.
    - The data disk for AD DS is formatted with drive letter `N:`.
- WSF node 1 VM
    - The Failover Clustering feature and related management tools are installed.
    - The shared data disk for witness is formatted with drive letter `W:` if this VM's fault domain is equals `0`.
- WSF node 2 VM
    - The Failover Clustering feature is installed.
    - The shared data disk for witness is formatted with drive letter `W:` if this VM's fault domain is equals `0`.
- Client VM

## Notes

- The deploy.ps1 script needs [Az module](https://www.powershellgallery.com/packages/Az/).
