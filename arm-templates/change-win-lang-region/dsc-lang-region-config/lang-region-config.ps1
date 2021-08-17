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

        TimeZone timezone
        {
            IsSingleInstance = 'Yes'
            TimeZone         = $TimeZone
        }

        SystemLocale system-locale
        {
            IsSingleInstance = 'Yes'
            SystemLocale     = $SystemLocale
        }

        Region region
        {
            IsSingleInstance = 'Yes'
            GeoLocationId    = $GeoLocationId
        }

        Language language
        {
            IsSingleInstance     = 'Yes'
            PreferredLanguage    = $PreferredLanguage
            CopyToDefaultAccount = $CopyToDefaultAccount
            DependsOn            = '[SystemLocale]system-locale','[Region]region'
        }
    }
}
