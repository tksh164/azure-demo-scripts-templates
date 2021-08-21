configuration language-options-and-region
{
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $PreferredLanguage,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Minimum', 'All')]
        [string] $LanguageCapabilities,

        [Parameter(Mandatory = $true)]
        [int] $GeoLocationId,

        [Parameter(Mandatory = $true)]
        [bool] $CopySettingsToDefaultUserAccount,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $TimeZone,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $SystemLocale
    )

    Import-DscResource -ModuleName 'PSDesiredStateConfiguration', 'ComputerManagementDsc', 'MultilingualUserInterfaceDsc'

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

        LanguageOptionsAndRegion lang-and-region
        {
            IsSingleInstance                 = 'Yes'
            PreferredLanguage                = $PreferredLanguage
            LanguageCapabilities             = $LanguageCapabilities
            CopySettingsToDefaultUserAccount = $CopySettingsToDefaultUserAccount
            LocationGeoId                    = $GeoLocationId
            SystemLocale                     = $SystemLocale
        }
    }
}
