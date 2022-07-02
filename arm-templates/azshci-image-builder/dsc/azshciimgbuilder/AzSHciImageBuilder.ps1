Configuration AzSHciImageBuilder
{
    param 
    (
        [Parameter(Mandatory = $false)]
        [string] $WorkingDriveLetter = 'W',

        [Parameter(Mandatory = $false)]
        [string] $WorkingDriveVolumeLabel = 'Builder',

        [Parameter(Mandatory = $false)]
        [string] $WorkingFolderPath = $WorkingDriveLetter + ':\work',

        [Parameter(Mandatory = $false)]
        [string] $SsuFolderPath = [System.IO.Path]::Combine($WorkingFolderPath, 'ssu'),

        [Parameter(Mandatory = $false)]
        [string] $CuFolderPath = [System.IO.Path]::Combine($WorkingFolderPath, 'cu'),

        [Parameter(Mandatory = $false)]
        [string] $AzSHciVersion = '21H2',

        [Parameter(Mandatory = $false)]
        [string] $AzSHciIsoUri = 'https://aka.ms/2CNBagfhSZ8BM7jyEV8I',

        [Parameter(Mandatory = $false)]
        [string] $AzSHciIsoFileName = 'AzureStackHCI.iso',

        [Parameter(Mandatory = $false)]
        [string] $AzSHciIsoFilePath = [System.IO.Path]::Combine($WorkingFolderPath, $AzSHciIsoFileName),

        [Parameter(Mandatory = $false)]
        [string] $AzSHciVhdFileName = 'azshci.vhd',

        [Parameter(Mandatory = $false)]
        [string] $AzSHciVhdFilePath = [System.IO.Path]::Combine($WorkingFolderPath, $AzSHciVhdFileName),

        [Parameter(Mandatory = $false)]
        [string] $AzcopyUri = 'https://aka.ms/downloadazcopy-v10-windows',

        [Parameter(Mandatory = $false)]
        [string] $AzcopyZipFilePath = [System.IO.Path]::Combine($WorkingFolderPath, 'azcopy.zip'),

        [Parameter(Mandatory = $false)]
        [string] $AzcopyExpandPath = [System.IO.Path]::Combine($WorkingFolderPath, 'azcopy'),

        [Parameter(Mandatory = $false)]
        [string] $VhdTempPath = $WorkingFolderPath,

        [Parameter(Mandatory = $true)]
        [string] $VhdBlobDestinationUri
    )
    
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'

    Node localhost
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
            ActionAfterReboot  = 'ContinueConfiguration'
            ConfigurationMode  = 'ApplyOnly'
        }

        Script 'Format working disk'
        {
            GetScript  = {
                @{ 'Result' = if ((Get-Volume -DriveLetter $using:WorkingDriveLetter).FileSystem -eq 'NTFS') { 'Formatted' } Else { 'Not formatted' } }
            }
            SetScript  = {
                Get-Disk |
                    Where-Object -FilterScript { ($_.PartitionStyle -eq 'RAW') -and ($_.AllocatedSize -eq 0) -and ($_.NumberOfPartitions -eq 0) } |
                    Sort-Object -Property 'DiskNumber' |
                    Select-Object -First 1 |
                    Initialize-Disk -PartitionStyle GPT -PassThru |
                    New-Volume -FileSystem NTFS -DriveLetter $using:WorkingDriveLetter -FriendlyName $using:WorkingDriveVolumeLabel
            }
            TestScript = { 
                (Get-Volume -DriveLetter $using:WorkingDriveLetter -ErrorAction SilentlyContinue).FileSystem -eq 'NTFS'
            }
        }

        File 'Create working folder'
        {
            Type            = 'Directory'
            DestinationPath = $WorkingFolderPath
            DependsOn       = '[Script]Format working disk'
        }

        File 'Create folder for Servicing Stack Update'
        {
            Type            = 'Directory'
            DestinationPath = $SsuFolderPath
            DependsOn       = '[File]Create working folder'
        }

        File 'Create folder for Cumulative Update'
        {
            Type            = 'Directory'
            DestinationPath = $CuFolderPath
            DependsOn       = '[File]Create working folder'
        }

        Script 'Download Servicing Stack Update for Azure Stach HCI'
        {
            GetScript  = {
                $result = Test-Path -Path (Join-Path -Path $using:SsuFolderPath -ChildPath '*') -Include '*.msu'
                @{ 'Result' = $result }
            }
            SetScript  = {
                $ssuSearchString = 'Servicing Stack Update for Azure Stack HCI, version ' + $using:AzSHciVersion + ' for x64-based Systems'
                $product = 'Azure Stack HCI'
                $ssuUpdate = Get-MSCatalogUpdate -Search $ssuSearchString -SortBy LastUpdated -Descending |
                    Where-Object -Property 'Products' -eq $product |
                    Select-Object -First 1
                $ssuUpdate | Save-MSCatalogUpdate -Destination $using:SsuFolderPath
            }
            TestScript = {
                $state = [scriptblock]::Create($GetScript).Invoke()
                $state.Result
            }
            DependsOn  = '[File]Create folder for Servicing Stack Update'
        }

        Script 'Download Cumulative Update for Azure Stach HCI'
        {
            GetScript  = {
                $result = Test-Path -Path (Join-Path -Path $using:CuFolderPath -ChildPath '*') -Include '*.msu'
                @{ 'Result' = $result }
            }
            SetScript  = {
                $cuSearchString = 'Cumulative Update for Azure Stack HCI, version ' + $using:AzSHciVersion
                $product = 'Azure Stack HCI'
                $cuUpdate = Get-MSCatalogUpdate -Search $cuSearchString -SortBy LastUpdated -Descending |
                    Where-Object -Property 'Products' -eq $product |
                    Where-Object -Property 'Title' -NotLike '*Preview*' |
                    Select-Object -First 1
                $cuUpdate | Save-MSCatalogUpdate -Destination $using:CuFolderPath
            }
            TestScript = {
                $state = [scriptblock]::Create($GetScript).Invoke()
                $state.Result
            }
            DependsOn  = '[File]Create folder for Cumulative Update'
        }

        Script 'Download Azure Stack HCI ISO file'
        {
            GetScript  = {
                $result = Test-Path -PathType Leaf -Path $using:AzSHciIsoFilePath
                @{ 'Result' = $result }
            }
            SetScript  = {
                Start-BitsTransfer -Source $using:AzSHciIsoUri -Destination $using:AzSHciIsoFilePath
            }
            TestScript = {
                $state = [scriptblock]::Create($GetScript).Invoke()
                $state.Result
            }
            DependsOn  = '[File]Create working folder'
        }

        Script 'Prepare Azure Stack HCI VHD file'
        {
            GetScript  = {
                $result = Test-Path -PathType Leaf -Path $using:AzSHciVhdFilePath
                @{ 'Result' = $result }
            }
            SetScript  = {
                $params = @{
                    SourcePath        = $using:AzSHciIsoFilePath
                    SizeBytes         = 40GB
                    VHDPath           = $using:AzSHciVhdFilePath
                    VhdFormat         = 'VHD'
                    VhdType           = 'Fixed'
                    VHDPartitionStyle = 'GPT'
                    TempDirectory     = $using:VhdTempPath
                    Verbose           = $true
                }
                Convert-WindowsImage @params

                # TODO: Apply SSU and CU.
            }
            TestScript = {
                $state = [scriptblock]::Create($GetScript).Invoke()
                $state.Result
            }
            DependsOn = @(
                '[Script]Download Servicing Stack Update for Azure Stach HCI',
                '[Script]Download Cumulative Update for Azure Stach HCI',
                '[Script]Download Azure Stack HCI ISO file'
            )
        }

        Script 'Disable Virtualization-based Security'
        {
            GetScript  = {
                $result = [scriptblock]::Create($TestScript).Invoke()
                @{ 'Result' = $result.ToString() }
            }
            SetScript  = {
                $mountResult = Mount-DiskImage -ImagePath $using:AzSHciVhdFilePath -StorageType VHD -Access ReadWrite
                $windowsPartition = Get-Partition -DiskNumber $mountResult.Number | Where-Object -Property 'Type' -EQ -Value 'Basic' | Select-Object -First 1
                $systemHiveFilePath = '{0}:\Windows\System32\config\SYSTEM' -f $windowsPartition.DriveLetter
                & 'C:\Windows\System32\reg.exe' load HKLM\TempHive $systemHiveFilePath

                $properties = Get-ItemProperty -LiteralPath $using:vbsRegKeyPath
                $using:vbsRegValueNames | ForEach-Object -Process {
                    if (($properties | Get-Member -Name $_) -ne $null) {
                        Remove-ItemProperty -LiteralPath $using:vbsRegKeyPath -Name $_
                    }
                }

                & 'C:\Windows\System32\reg.exe' unload HKLM\TempHive
                Dismount-DiskImage -ImagePath $mountResult.ImagePath
            }
            TestScript = {
                $mountResult = Mount-DiskImage -ImagePath $using:AzSHciVhdFilePath -StorageType VHD -Access ReadOnly
                $windowsPartition = Get-Partition -DiskNumber $mountResult.Number | Where-Object -Property 'Type' -EQ -Value 'Basic' | Select-Object -First 1
                $systemHiveFilePath = '{0}:\Windows\System32\config\SYSTEM' -f $windowsPartition.DriveLetter
                & 'C:\Windows\System32\reg.exe' load HKLM\TempHive $systemHiveFilePath

                $properties = Get-ItemProperty -LiteralPath $using:vbsRegKeyPath
                $result = $true
                $using:vbsRegValueNames | ForEach-Object -Process {
                    $result = $result -and (($properties | Get-Member -Name $_) -eq $null)
                }

                & 'C:\Windows\System32\reg.exe' unload HKLM\TempHive
                Dismount-DiskImage -ImagePath $mountResult.ImagePath
                $result
            }
            DependsOn = @(
                '[Script]Prepare Azure Stack HCI VHD file'
            )
        }
        Script 'Download azcopy archive file'
        {
            GetScript  = {
                $result = Test-Path -PathType Leaf -Path $using:AzcopyZipFilePath
                @{ 'Result' = $result }
            }
            SetScript  = {
                Start-BitsTransfer -Source $using:AzcopyUri -Destination $using:AzcopyZipFilePath
            }
            TestScript = {
                $state = [scriptblock]::Create($GetScript).Invoke()
                $state.Result
            }
            DependsOn  = '[File]Create working folder'
        }

        Script 'Expand azcopy archive file'
        {
            GetScript  = {
                $result = Test-Path -PathType Container -Path $using:AzcopyExpandPath
                @{ 'Result' = $result }
            }
            SetScript  = {
                Expand-Archive -Path $using:AzcopyZipFilePath -DestinationPath $using:AzcopyExpandPath
            }
            TestScript = {
                $state = [scriptblock]::Create($GetScript).Invoke()
                $state.Result
            }
            DependsOn  = '[Script]Download azcopy archive file'
        }

        Script 'Upload Azure Stack HCI VHD file'
        {
            GetScript  = {
                $logFile = Get-ChildItem -Path (Join-Path -Path $using:AzcopyExpandPath -ChildPath '*.log') -Exclude '*scanning.log' |
                    Sort-Object -Descending -Property 'CreationTimeUtc' |
                    Select-Object -First 1
                $result = ($logFile | Get-Content -Tail 2 | Select-Object -First 1) -eq 'Final Job Status: Completed'
                @{ 'Result' = $result }
            }
            SetScript  = {
                $env:AZCOPY_LOG_LOCATION = $using:AzcopyExpandPath
                $azcopy = Get-ChildItem -LiteralPath $using:AzcopyExpandPath -Recurse -Filter 'azcopy.exe'
                & $azcopy.FullName copy $using:AzSHciVhdFilePath $using:VhdBlobDestinationUri --blob-type PageBlob
            }
            TestScript = {
                $state = [scriptblock]::Create($GetScript).Invoke()
                $state.Result
            }
            DependsOn = @(
                '[Script]Prepare Azure Stack HCI VHD file',
                '[Script]Expand azcopy archive file'
            )
        }
    }
}
