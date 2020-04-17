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

    Import-DscResource -ModuleName 'PSDesiredStateConfiguration', 'ActiveDirectoryDsc'

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

        Script create-adds-data-volume
        {
            TestScript = {
                $addsDataVolume = Get-Volume -DriveLetter $using:DataVolumeDriveLetter -ErrorAction SilentlyContinue |
                    Where-Object -FilterScript {
                        $_.FileSystem -eq 'NTFS' -and
                        $_.FileSystemLabel -eq $using:DataVolumeLabel
                    }
                if (($addsDataVolume | Measure-Object).Count -ne 0)
                {
                    Write-Verbose -Message ('Already prepared the AD DS data volume as "{0}:".' -f $using:DataVolumeLabel)
                    return $true
                }

                $uninitializedDisk = Get-Disk |
                    Where-Object -FilterScript {
                        ($_.PartitionStyle -eq 'RAW') -and
                        ($_.AllocatedSize -eq 0) -and
                        ($_.NumberOfPartitions -eq 0)
                    } |
                    Sort-Object -Property 'DiskNumber' |
                    Select-Object -First 1

                if (($uninitializedDisk | Measure-Object).Count -eq 0)
                {
                    throw 'Not exist uninitialized data disks on this VM. Least one uninitialized disk requires to ADDS setup.'
                }

                if ((Get-Volume -DriveLetter $using:DataVolumeDriveLetter -ErrorAction SilentlyContinue | Measure-Object).Count -ne 0)
                {
                    throw ('The specified drive letter "{0}:" already exists. Non used drive letter requires to ADDS setup.' -f $using:DataVolumeDriveLetter)
                }
        
                Write-Verbose -Message 'Need preparation for the AD DS data volume.'
                $false
            }

            SetScript = {
                Get-Disk |
                    Where-Object -FilterScript {
                        ($_.PartitionStyle -eq 'RAW') -and
                        ($_.AllocatedSize -eq 0) -and
                        ($_.NumberOfPartitions -eq 0)
                    } |
                    Sort-Object -Property 'DiskNumber' |
                    Select-Object -First 1 |
                    Initialize-Disk -PartitionStyle GPT -PassThru |
                    New-Volume -FileSystem NTFS -DriveLetter $using:DataVolumeDriveLetter -FriendlyName $using:DataVolumeLabel
            }

            GetScript = {
                @{ Result = 'create-adds-data-volume reuslt' }
            }
        }

        WindowsFeatureSet install-ad-domain-services-role-and-tools
        {
            Ensure               = 'Present'
            Name                 = 'AD-Domain-Services',
                                   'RSAT-ADDS',
                                   'RSAT-AD-PowerShell',
                                   'GPMC'
                                   # Note: DNS and DNS management tools are automatically installed by the domain controller promotion.
            IncludeAllSubFeature = $true
            LogPath              = ('{0}:\adds-setup\install-ad-domain-services-role-and-tools.log' -f $DataVolumeDriveLetter)
            DependsOn            = '[Script]create-adds-data-volume'
        }
    
        ADDomain create-adds-forest
        {
            DomainName                    = $DomainName
            Credential                    = $CredentialForAddsInstall
            SafemodeAdministratorPassword = $SafeModeAdministratorPassword
            DatabasePath                  = ('{0}:\Windows\NTDS' -f $DataVolumeDriveLetter)
            LogPath                       = ('{0}:\Windows\NTDS' -f $DataVolumeDriveLetter)
            SysvolPath                    = ('{0}:\Windows\SYSVOL' -f $DataVolumeDriveLetter)
            DependsOn                     = '[WindowsFeatureSet]install-ad-domain-services-role-and-tools'
        }
    }
}
