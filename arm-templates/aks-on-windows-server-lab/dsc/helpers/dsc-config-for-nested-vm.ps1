Configuration WsfcNodeConfig {
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'

    Node 'localhost' {
        LocalConfigurationManager {
            ConfigurationMode  = 'ApplyOnly'
            RebootNodeIfNeeded = $true
            ActionAfterReboot  = 'ContinueConfiguration'
        }

        WindowsFeatureSet 'Install Windows roles and features' {
            Ensure = 'Present'
            Name   = @(
                'FS-FileServer',
                'Failover-Clustering',
                'RSAT-Clustering',
                'Hyper-V',
                'RSAT-Hyper-V-Tools'
            )
        }
    }
}

$transcriptLogPath = Join-Path -Path 'C:\Temp' -ChildPath ('transcipt-{0}.log' -f (Get-Date -Format 'yyyy-MM-dd'))
Start-Transcript -LiteralPath $transcriptLogPath

$dscConfigLocation = 'C:\Temp\WsfcNodeConfig'

Remove-DscConfigurationDocument -Stage Current, Previous, Pending -Force

WsfcNodeConfig -OutputPath $dscConfigLocation

Set-DscLocalConfigurationManager -Path $dscConfigLocation -Verbose
Start-DscConfiguration -Path $dscConfigLocation -Wait -Verbose

Stop-Transcript

logoff.exe
