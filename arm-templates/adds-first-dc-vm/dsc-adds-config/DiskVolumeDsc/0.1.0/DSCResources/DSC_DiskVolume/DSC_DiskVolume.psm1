function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $DriveLetter,

        [Parameter(Mandatory = $true)]
        [System.String]
        $VolumeLabel = ''
    )

    Write-Verbose -Message ('Find a target disk volume that has a drive letter "{0}:" and a volume label "{1}".' -f $DriveLetter, $VolumeLabel)

    $getTargetResourceResult = @{
        DriveLetter = ''
        VolumeLabel = ''
    }

    $volume = Get-TargetDiskVolume -DriveLetter $DriveLetter -VolumeLabel $VolumeLabel
    if ($volume -ne $null)
    {
        Write-Verbose -Message ('Found the existing specified volume that has a drive letter "{0}:", a volume label "{1}" and a unique ID "{2}".' -f $volume.DriveLetter, $volume.FileSystemLabel, $volume.UniqueId)

        $getTargetResourceResult = @{
            DriveLetter  = $volume.DriveLetter
            VolumeLabel  = $volume.FileSystemLabel
        }
    }
    else
    {
        Write-Verbose -Message ('Couldn''t find the existing specified volume that has a drive letter "{0}:" and a volume label "{1}".' -f $DriveLetter, $VolumeLabel)
    }

    return $getTargetResourceResult
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $DriveLetter,

        [Parameter(Mandatory = $true)]
        [System.String]
        $VolumeLabel
    )

    Write-Verbose -Message ('Find a target disk volume that has a drive letter "{0}:" and a volume label "{1}".' -f $DriveLetter, $VolumeLabel)

    $volume = Get-TargetDiskVolume -DriveLetter $DriveLetter -VolumeLabel $VolumeLabel
    $testTargetResourceResult = if ($volume -eq $null) { $false } else { $true }

    if ($testTargetResourceResult)
    {
        Write-Verbose -Message ('Found the existing specified volume that has a drive letter "{0}:", a volume label "{1}" and a unique ID "{2}".' -f $volume.DriveLetter, $volume.FileSystemLabel, $volume.UniqueId)
    }
    else
    {
        Write-Verbose -Message ('Couldn''t find the existing specified volume that has a drive letter "{0}:" and a volume label "{1}".' -f $DriveLetter, $VolumeLabel)
    }

    return $testTargetResourceResult
}

function Set-TargetResource
{
    [CmdletBinding()]
    [OutputType([void])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $DriveLetter,

        [Parameter(Mandatory = $true)]
        [System.String]
        $VolumeLabel
    )

    # First, search the existing volume that has the specified drive letter and volume label.
    $existingVolume = Get-TargetDiskVolume -DriveLetter $DriveLetter -VolumeLabel $VolumeLabel
    if ($existingVolume -ne $null)
    {
        Write-Verbose -Message ('Already exist the specified volume that has a drive letter "{0}:", a volume label "{1}" and a unique ID "{2}".' -f $existingVolume.DriveLetter, $existingVolume.FileSystemLabel, $existingVolume.UniqueId)
        return
    }

    # If the specified volume couldn't find in the first step, search a uninitialized disk and create a new volume on the disk.
    Write-Verbose -Message ('Try initialize the raw disk because couldn''t find the existing specified volume that has a drive letter "{0}:" and a volume label "{1}".' -f $DriveLetter, $VolumeLabel)

    $rawDisk = Get-Disk |
        Where-Object -FilterScript {
            ($_.PartitionStyle -eq 'RAW') -and
            ($_.AllocatedSize -eq 0) -and
            ($_.NumberOfPartitions -eq 0)
        } |
        Sort-Object -Property 'DiskNumber' |
        Select-Object -First 1

    if ($rawDisk -eq $null)
    {
        Write-Error -Message (" `n `n" + 'Couldn''t find a raw disk to initialize.' + "`n `n ")
    }

    $newVolume = $rawDisk |
        Initialize-Disk -PartitionStyle GPT -PassThru |
        New-Volume -FileSystem NTFS -DriveLetter $DriveLetter -FriendlyName $VolumeLabel

    Write-Verbose -Message ('A new volume created that has a drive letter "{0}:", a volume label "{1}" and a unique ID "{2}".' -f $newVolume.DriveLetter, $newVolume.FileSystemLabel, $newVolume.UniqueId)
}

function Get-TargetDiskVolume
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $DriveLetter,

        [Parameter(Mandatory = $true)]
        [System.String]
        $VolumeLabel
    )

    $volume = Get-Volume -DriveLetter $DriveLetter -ErrorAction SilentlyContinue |
        Where-Object -FilterScript {
            ($_.DriveType -eq 'Fixed') -and
            ($_.HealthStatus -eq 'Healthy') -and
            ($_.FileSystemLabel -eq $VolumeLabel)
        } |
        Sort-Object -Property 'DriveLetter' |
        Select-Object -First 1

    return $volume
}

Export-ModuleMember -Function *-TargetResource
