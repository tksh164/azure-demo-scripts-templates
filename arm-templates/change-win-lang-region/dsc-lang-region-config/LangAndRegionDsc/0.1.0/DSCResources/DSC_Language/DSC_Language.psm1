Import-Module -Name (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Modules') -ChildPath 'Common.psm1') -Verbose:$false

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [string] $IsSingleInstance,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $PreferredLanguage,

        [Parameter(Mandatory = $true)]
        [bool] $CopyToDefaultAccount
    )

    Write-Verbose -Message 'Getting the language.'

    $uiLanguageOverride = Get-WinUILanguageOverride
    $uiLanguage = if ($uiLanguageOverride -eq $null) { 'n/a' } else { $uiLanguageOverride.IetfLanguageTag }

    return @{
        IsSingleInstance     = $IsSingleInstance
        PreferredLanguage    = $uiLanguage
        CopyToDefaultAccount = $CopyToDefaultAccount
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
        [ValidateNotNullOrEmpty()]
        [string] $PreferredLanguage,

        [Parameter(Mandatory = $true)]
        [bool] $CopyToDefaultAccount
    )

    Write-Verbose -Message 'Testing the language.'

    $result = $true

    if ((($PreferredLanguage -eq 'ja-JP') -or ($PreferredLanguage -eq 'ja')) -and (Test-WindowsVersion -Version '10.0.17763' -Verbose))
    {
        Import-Module -Name (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Modules') -ChildPath 'ja-JP.ws2019.psm1') -Verbose:$false
        $result = (Test-Language -Verbose) -and $result 
    }
    else
    {
        Write-Verbose -Message ('This DSC resource does not support "{0}" language on this Windows version.' -f $PreferredLanguage)
    }

    $result
}

function Set-TargetResource
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [string] $IsSingleInstance,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $PreferredLanguage,

        [Parameter(Mandatory = $true)]
        [bool] $CopyToDefaultAccount
    )

    Write-Verbose -Message 'Setting the language.'

    if ((($PreferredLanguage -eq 'ja-JP') -or ($PreferredLanguage -eq 'ja')) -and (Test-WindowsVersion -Version '10.0.17763' -Verbose))
    {
        Import-Module -Name (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Modules') -ChildPath 'ja-JP.ws2019.psm1') -Verbose:$false
        Set-Language -CopyToDefaultAccount $CopyToDefaultAccount -Verbose
    }
    else
    {
        Write-Verbose -Message ('This DSC resource does not support "{0}" language on this Windows version.' -f $PreferredLanguage)
    }
}

Export-ModuleMember -Function *-TargetResource
