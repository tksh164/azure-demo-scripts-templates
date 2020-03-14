Configuration Config
{
    param ()

    Import-DscResource -ModuleName PSDesiredStateConfiguration

    Node 'localhost'
    {
        LocalConfigurationManager
        {
            ConfigurationMode    = 'ApplyAndAutoCorrect'
            RebootNodeIfNeeded   = $true
            ActionAfterReboot    = 'ContinueConfiguration'
            AllowModuleOverwrite = $true
        }

        WindowsFeature Install_AD_Domain_Services
        {
            Ensure = 'Present'
            Name   = 'AD-Domain-Services'
        }
    }
}
