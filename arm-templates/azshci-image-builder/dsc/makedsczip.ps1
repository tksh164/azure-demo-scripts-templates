$targetFolder = 'azshciimgbuilder'
$destinationFile = 'azshciimgbuilder.zip'

Get-ChildItem -LiteralPath $targetFolder |
    ForEach-Object -Process { $_.FullName } |
    Compress-Archive -DestinationPath (Join-Path -Path $PSScriptRoot -ChildPath $destinationFile) -CompressionLevel Optimal -Force
