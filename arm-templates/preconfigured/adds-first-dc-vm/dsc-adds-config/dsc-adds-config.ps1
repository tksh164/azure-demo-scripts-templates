configuration setup-adds-first-dc
{
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $DomainName,

        [Parameter(Mandatory = $true)]
        [PSCredential]
        $CredentialForAddsInstall,

        [Parameter(Mandatory = $true)]
        [PSCredential]
        $SafeModeAdministratorPassword,

        [Parameter(Mandatory = $true)]
        [string]
        $DataVolumeDriveLetter,

        [Parameter(Mandatory = $true)]
        [string]
        $DataVolumeLabel
    )

    Import-DscResource -ModuleName 'PSDesiredStateConfiguration', 'DiskVolumeDsc', 'ActiveDirectoryDsc'

    $ConfigurationData.AllNodes = @(
        @{
            NodeName                    = 'localhost'
            PSDscAllowPlainTextPassword = $true
        }
    )

    node localhost
    {
        LocalConfigurationManager 
        {
            RebootNodeIfNeeded = $true
        }

        DiskVolume adds-data-store-volume
        {
            DriveLetter = $DataVolumeDriveLetter
            VolumeLabel = $DataVolumeLabel
        }

        WindowsFeatureSet adds-role-and-tools
        {
            Ensure               = 'Present'
            Name                 = 'AD-Domain-Services',
                                   'RSAT-ADDS',
                                   'RSAT-AD-PowerShell',
                                   'GPMC'
                                   # Note: DNS and DNS management tools are automatically installed by the domain controller promotion.
            IncludeAllSubFeature = $true
            LogPath              = ('{0}:\adds-setup\install-adds-role-and-tools.log' -f $DataVolumeDriveLetter)
            DependsOn            = '[DiskVolume]adds-data-store-volume'
        }
    
        ADDomain create-adds-forest
        {
            DomainName                    = $DomainName
            Credential                    = $CredentialForAddsInstall
            SafemodeAdministratorPassword = $SafeModeAdministratorPassword
            DatabasePath                  = ('{0}:\Windows\NTDS' -f $DataVolumeDriveLetter)
            LogPath                       = ('{0}:\Windows\NTDS' -f $DataVolumeDriveLetter)
            SysvolPath                    = ('{0}:\Windows\SYSVOL' -f $DataVolumeDriveLetter)
            DependsOn                     = '[WindowsFeatureSet]adds-role-and-tools'
        }
    }
}
