# Groundwork for File Server Capacity Tool lab environment

This template provides groundworks for the File Server Capacity Tool lab environment.

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2Ftksh164%2Fazure-demo-scripts-templates%2Fmaster%2Farm-templates%2Fgroundwork-fsct%2Ftemplate.json)

## Deployment

- Domain controller VM
    - The AD DS feature and related management tools are installed.
    - The data disk for AD DS is formatted with drive letter `N:`.
- File server VM
    - The File Server feature is installed.
- FSCT controller VM
    - The FSCT zip file is downloaded at `C:\`.
- FSCT client 1 VM
    - The FSCT zip file is downloaded at `C:\`.
- FSCT client 2 VM
    - The FSCT zip file is downloaded at `C:\`.


## File Server Capacity Tool

- [Download File Server Capacity Tool v1.3 (64bit)](https://www.microsoft.com/en-us/download/details.aspx?id=55947)

## Notes

- The deploy.ps1 script needs [Az module](https://www.powershellgallery.com/packages/Az/).
