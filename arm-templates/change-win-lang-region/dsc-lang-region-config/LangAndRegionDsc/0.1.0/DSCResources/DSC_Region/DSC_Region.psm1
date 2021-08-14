function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [string] $IsSingleInstance,

        [Parameter(Mandatory = $true)]
        [int] $GeoLocationId
    )

    Write-Verbose -Message 'Getting the region.'

    $geoLocationId = (Get-WinHomeLocation).GeoId

    return @{
        IsSingleInstance = 'Yes'
        GeoLocationId    = $geoLocationId
    }
}

function Set-TargetResource
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [string] $IsSingleInstance,

        [Parameter(Mandatory = $true)]
        [int] $GeoLocationId
    )

    Write-Verbose -Message 'Setting the region.'

    if ((Get-WinHomeLocation).GeoId -ne $GeoLocationId)
    {
        Set-WinHomeLocation -GeoId $GeoLocationId
        Write-Verbose -Message ('The geo location ID for the current user updated to "{0}"' -f $GeoLocationId)
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [string] $IsSingleInstance,

        [Parameter(Mandatory = $true)]
        [int] $GeoLocationId
    )

    Write-Verbose -Message 'Testing the region.'

    $result = $true

    $currentGeoLocationId = (Get-WinHomeLocation).GeoId

    if ($currentGeoLocationId -eq $GeoLocationId)
    {
        Write-Verbose -Message ('The geo location ID is already set to "{0}".' -f $GeoLocationId)
    }
    else
    {
        Write-Verbose -Message ('The geo location ID is "{0}" but should be "{1}". Change required.' -f $currentGeoLocationId, $GeoLocationId)
        $result = $false
    }

    $result
}

Export-ModuleMember -Function *-TargetResource
