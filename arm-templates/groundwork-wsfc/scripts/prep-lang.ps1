# Windows Server 2019
if ($PSVersionTable.BuildVersion.Build -eq 17763)
{
    New-Item -Path 'C:\work' -ItemType Directory -Force

    @(
        [PSCustomObject] @{
            Source      = 'https://raw.githubusercontent.com/tksh164/azure-demo-scripts-templates/master/arm-templates/groundwork-wsfc/scripts/lang-jajp/lang-jajp-step1.ps1'
            Destination = 'C:\work\lang-jajp-step1.ps1'
        },
        [PSCustomObject] @{
            Source      = 'https://raw.githubusercontent.com/tksh164/azure-demo-scripts-templates/master/arm-templates/groundwork-wsfc/scripts/lang-jajp/lang-jajp-step2.ps1'
            Destination = 'C:\work\lang-jajp-step2.ps1'
        },
        [PSCustomObject] @{
            Source      = 'https://raw.githubusercontent.com/tksh164/azure-demo-scripts-templates/master/arm-templates/groundwork-wsfc/scripts/lang-jajp/lang-jajp-ws2019.psd1'
            Destination = 'C:\work\lang-jajp-ws2019.psd1'
        }
    ) | ForEach-Object -Process {
        Invoke-RestMethod -Method Get -Uri $_.Source -UseBasicParsing | Set-Content -LiteralPath $_.Destination -Force
    }
}
