configuration lang-region-config
{
    param (
        [Parameter(Mandatory = $true)]
        [string] $TimeZone,

        [Parameter(Mandatory = $true)]
        [int] $GeoLocationId,

        [Parameter(Mandatory = $true)]
        [string] $PreferredLanguage,

        [Parameter(Mandatory = $true)]
        [bool] $CopyToDefaultAccount,

        [Parameter(Mandatory = $true)]
        [bool] $CopyToSystemAccount,

        [Parameter(Mandatory = $true)]
        [string] $SystemLocale
    )

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
            TimeZone         = $TimeZone
        }

        Region region
        {
            IsSingleInstance = 'Yes'
            GeoLocationId    = $GeoLocationId
        }

        Language current-user
        {
            IsSingleInstance     = 'Yes'
            PreferredLanguage    = $PreferredLanguage
            CopyToDefaultAccount = $CopyToDefaultAccount
            CopyToSystemAccount  = $CopyToSystemAccount
        }

        SystemLocale system-locale
        {
            IsSingleInstance = 'Yes'
            SystemLocale     = $SystemLocale
        }
    }
}
