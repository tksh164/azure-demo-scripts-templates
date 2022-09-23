$ProgressPreference = [System.Management.Automation.ActionPreference]::SilentlyContinue

New-Item -Path 'C:\WAC' -ItemType Directory -Force

# Download the MSI file
Start-BitsTransfer -Source 'https://aka.ms/WACDownload' -Destination 'C:\WAC\WindowsAdminCenter.msi'

# Install Windows Admin Center
$msiArgs = '/i', 'C:\WAC\WindowsAdminCenter.msi', '/qn', '/L*v', 'log.txt', 'SME_PORT=443', 'SSL_CERTIFICATE_OPTION=generate'
Start-Process -FilePath 'msiexec.exe' -ArgumentList $msiArgs -Wait
