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

        LangAndRegion current-user
        {
            IsSingleInstance     = 'Yes'
            PreferredLanguage    = 'ja'
            LocationGeoId        = 122
            CopyToDefaultAccount = $true
            CopyToSystemAccount  = $true
        }

        TimeZone time-zone
        {
            IsSingleInstance = 'Yes'
            TimeZone         = 'Tokyo Standard Time'
        }

        SystemLocale system-locale
        {
            IsSingleInstance = 'Yes'
            SystemLocale     = 'ja-JP'
        }
    }
}
