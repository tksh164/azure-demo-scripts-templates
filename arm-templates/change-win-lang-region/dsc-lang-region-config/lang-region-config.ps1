configuration lang-region-config
{
    param ()

    Import-DscResource -ModuleName 'PSDesiredStateConfiguration', 'ComputerManagementDsc', 'LangAndRegionDsc'

    node localhost
    {
        LocalConfigurationManager 
        {
            RebootNodeIfNeeded = $true
        }

        TimeZone time-zone
        {
            IsSingleInstance = 'Yes'
            TimeZone         = 'Tokyo Standard Time'
        }

        Region region
        {
            IsSingleInstance = 'Yes'
            GeoLocationId    = 122  # Japan
        }

        LangAndRegion current-user
        {
            IsSingleInstance     = 'Yes'
            PreferredLanguage    = 'ja'
            CopyToDefaultAccount = $true
            CopyToSystemAccount  = $true
        }

        SystemLocale system-locale
        {
            IsSingleInstance = 'Yes'
            SystemLocale     = 'ja-JP'
        }
    }
}
