$targetFiles = @(
    'aksonwshost.ps1',
    'dscmetadata.json',
    'ComputerManagementDsc',
    'NetworkingDsc',
    'xCredSSP',
    'xWindowsUpdate',
    'ActiveDirectoryDsc',
    'DnsServerDsc',
    'xHyper-V',
    'cHyper-V',
    'Hyper-ConvertImage',
    'WindowsDeploymentHelper',
    'xDhcpServer',
    'DSCR_Shortcut',
    'MSCatalog',
    'dsc-config-for-nested-vm.ps1'
)

$destinationFile = 'aksonwshost.zip'

$targetFiles |
    ForEach-Object -Process { Join-Path -Path $PSScriptRoot -ChildPath $_ } |
    Compress-Archive -DestinationPath (Join-Path -Path $PSScriptRoot -ChildPath $destinationFile) -CompressionLevel Optimal -Force
