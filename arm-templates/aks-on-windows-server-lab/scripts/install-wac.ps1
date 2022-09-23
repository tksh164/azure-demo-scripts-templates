$ProgressPreference = [System.Management.Automation.ActionPreference]::SilentlyContinue

New-Item -Path 'C:\WAC' -ItemType Directory -Force

# Download the MSI file
& 'C:\Windows\System32\curl.exe' --location --silent --show-error --output 'C:\WAC\WindowsAdminCenter.msi' 'https://aka.ms/WACDownload'

# Install Windows Admin Center
$msiArgs = '/i', 'C:\WAC\WindowsAdminCenter.msi', '/qn', '/L*v', 'log.txt', 'SME_PORT=443', 'SSL_CERTIFICATE_OPTION=generate'
Start-Process -FilePath 'msiexec.exe' -ArgumentList $msiArgs -Wait
