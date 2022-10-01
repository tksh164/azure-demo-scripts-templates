Configuration NestedVMConfig {
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

$transcriptLogPath = [IO.Path]::Combine('C:\Temp', ('transcipt-{0}.log' -f (Get-Date -Format 'yyyy-MM-dd')))
Start-Transcript -LiteralPath $transcriptLogPath

$dscConfigLocation = 'C:\Temp\NestedVMConfig'

Remove-DscConfigurationDocument -Stage Current, Previous, Pending -Force

# Create a DSC configuration for the nested VM.
NestedVMConfig -OutputPath $dscConfigLocation

# Apply the DSC configuration to the nested VM.
Set-DscLocalConfigurationManager -Path $dscConfigLocation -Verbose
Start-DscConfiguration -Path $dscConfigLocation -Wait -Verbose

Stop-Transcript

# Shutdown the nested VM.
Stop-Computer
