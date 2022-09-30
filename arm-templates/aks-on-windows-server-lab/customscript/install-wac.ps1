$ProgressPreference = [System.Management.Automation.ActionPreference]::SilentlyContinue

$wacFolderPath = 'C:\WAC'
New-Item -Path $wacFolderPath -ItemType Directory -Force

# Download the MSI file
$wacMsiFilePath = [IO.Path]::Combine($wacFolderPath, 'WindowsAdminCenter.msi')
Start-BitsTransfer -Source 'https://aka.ms/WACDownload' -Destination $wacMsiFilePath

# Install Windows Admin Center
$msiArgs = '/i', ('"{0}"' -f $wacMsiFilePath), '/qn', '/L*v', 'log.txt', 'SME_PORT=443', 'SSL_CERTIFICATE_OPTION=generate'
Start-Process -FilePath 'msiexec.exe' -ArgumentList $msiArgs -Wait
