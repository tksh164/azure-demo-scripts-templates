$targetFiles = @(
    'lang-options-and-region.ps1',
    'MultilingualUserInterfaceDsc',
    'ComputerManagementDsc'
)
$destinationFile = 'lang-region-config.zip'

$targetFiles |
    ForEach-Object -Process { Join-Path -Path $PSScriptRoot -ChildPath $_ } |
    Compress-Archive -DestinationPath (Join-Path -Path $PSScriptRoot -ChildPath $destinationFile) -CompressionLevel Optimal -Force
