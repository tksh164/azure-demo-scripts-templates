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

    Set-WinHomeLocation -GeoId $GeoLocationId
    Write-Verbose -Message ('The geo location ID for the current user updated to "{0}"' -f $GeoLocationId)
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

    $currentGeoLocationId = (Get-WinHomeLocation).GeoId
    $result = $currentGeoLocationId -eq $GeoLocationId
    if ($result)
    {
        Write-Verbose -Message ('The geo location ID is already set to "{0}".' -f $GeoLocationId)
    }
    else
    {
        Write-Verbose -Message ('The geo location ID is "{0}" but should be "{1}". Change required.' -f $currentGeoLocationId, $GeoLocationId)
    }
    $result
}

Export-ModuleMember -Function *-TargetResource
