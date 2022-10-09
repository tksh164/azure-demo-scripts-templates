$targetFiles = @(
    'funcapp\host.json',
    'funcapp\requirements.psd1',
    'funcapp\profile.ps1',
    'funcapp\ResourceAutoTaggingEventGridTrigger'
)

$destinationFile = 'funcapp.zip'

$targetFiles |
    ForEach-Object -Process { Join-Path -Path $PSScriptRoot -ChildPath $_ } |
    Compress-Archive -DestinationPath (Join-Path -Path $PSScriptRoot -ChildPath $destinationFile) -CompressionLevel Optimal -Force
