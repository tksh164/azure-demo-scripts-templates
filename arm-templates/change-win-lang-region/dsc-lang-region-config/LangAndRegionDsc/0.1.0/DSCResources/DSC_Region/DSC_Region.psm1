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

    # Set the home location for the current user account.
    if ((Get-WinHomeLocation).GeoId -ne $GeoLocationId)
    {
        Write-Verbose -Message ('Setting the geo location ID to "{0}"' -f $GeoLocationId)
        Set-WinHomeLocation -GeoId $GeoLocationId
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

    $result = $true

    # Test the home location for the current user account.

    $currentGeoLocationId = (Get-WinHomeLocation).GeoId

    if ($currentGeoLocationId -eq $GeoLocationId)
    {
        Write-Verbose -Message ('The geo location ID is already set to "{0}".' -f $GeoLocationId)
    }
    else
    {
        Write-Verbose -Message ('The geo location ID is not set to "{0}". The current geo location ID is "{1}"' -f $GeoLocationId, $currentGeoLocationId)
        $result = $false
    }

    $result
}

Export-ModuleMember -Function *-TargetResource
