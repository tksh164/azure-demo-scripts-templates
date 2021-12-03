# Windows Server 2019
if ($PSVersionTable.BuildVersion.Build -eq 17763)
{
    New-Item -Path 'C:\work' -ItemType Directory -Force

    @(
        [PSCustomObject] @{
            Source      = 'https://raw.githubusercontent.com/tksh164/azure-demo-scripts-templates/master/arm-templates/groundwork-wsfc/scripts/lang/lang-step1.ps1'
            Destination = 'C:\work\lang-step1.ps1'
        },
        [PSCustomObject] @{
            Source      = 'https://raw.githubusercontent.com/tksh164/azure-demo-scripts-templates/master/arm-templates/groundwork-wsfc/scripts/lang/lang-step2.ps1'
            Destination = 'C:\work\lang-step2.ps1'
        },
        [PSCustomObject] @{
            Source      = 'https://raw.githubusercontent.com/tksh164/azure-demo-scripts-templates/master/arm-templates/groundwork-wsfc/scripts/lang/lang-ws2019-jajp.psd1'
            Destination = 'C:\work\lang-ws2019-jajp.psd1'
        }
    ) | ForEach-Object -Process {
        Invoke-RestMethod -Method Get -Uri $_.Source -UseBasicParsing | Set-Content -LiteralPath $_.Destination -Force
    }
}
