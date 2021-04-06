$targetFiles = @(
    'dsc-adds-config.ps1',
    'ActiveDirectoryDsc'
)
$destinationFile = 'dsc-adds-config.zip'

$targetFiles |
    ForEach-Object -Process { Join-Path -Path $PSScriptRoot -ChildPath $_ } |
    Compress-Archive -DestinationPath (Join-Path -Path $PSScriptRoot -ChildPath $destinationFile) -CompressionLevel Optimal -Force
