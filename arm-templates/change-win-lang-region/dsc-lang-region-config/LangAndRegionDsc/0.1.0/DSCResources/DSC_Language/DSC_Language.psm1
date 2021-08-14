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
        [string] $PreferredLanguage
    )

    Write-Verbose -Message 'Getting the language.'

    $langList = Get-WinUserLanguageList
    $preferredLanguage = $langList[0].LanguageTag

    return @{
        IsSingleInstance     = 'Yes'
        PreferredLanguage    = $preferredLanguage
        CopyToDefaultAccount = $false
        CopyToSystemAccount  = $false
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
        [ValidateNotNullOrEmpty()]
        [string] $PreferredLanguage,

        [Parameter(Mandatory = $false)]
        [bool] $CopyToDefaultAccount = $false,

        [Parameter(Mandatory = $false)]
        [bool] $CopyToSystemAccount = $false
    )

    Write-Verbose -Message 'Setting the language.'

    $isPhaseOneComplete = $false

    if (($PreferredLanguage -eq 'ja') -and (Test-WindowsVersion -Version '10.0.17763' -Verbose))
    {
        Import-Module -Name (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Modules') -ChildPath 'ja-JP.ws2019.psm1') -Verbose:$false

        if (-not (Test-LanguagePack))
        {
            Install-LanguagePack -Verbose
            $isPhaseOneComplete = $true
            $global:DSCMachineStatus = 1
        }

        if (-not (Test-LanguageCapability))
        {
            Install-LanguageCapability -Verbose
            $global:DSCMachineStatus = 1
        }

        if (-not (Test-PreferredLanguage))
        {
            Set-PreferredLanguage -Verbose
        }

        if (Test-PhaseOneCompletionFlag -Verbose)
        {
            Set-UILanguage -Verbose
            Clear-PhaseOneCompletionFlag -Verbose
            Copy-LanguageSttingsToSpecialAccount -CopyToDefaultAccount:$CopyToDefaultAccount -CopyToSystemAccount:$CopyToSystemAccount -Verbose
            $global:DSCMachineStatus = 1
        }
    }
    else
    {
        Write-Verbose -Message ('This DSC resource does not support "{0}" language on this Windows version.' -f $PreferredLanguage)
    }

    if ($isPhaseOneComplete) { Set-PhaseOneCompletionFlag -Verbose }
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

        [Parameter(Mandatory = $false)]
        [bool] $CopyToDefaultAccount = $false,

        [Parameter(Mandatory = $false)]
        [bool] $CopyToSystemAccount = $false
    )

    Write-Verbose -Message 'Testing the language.'

    $result = $true

    if (($PreferredLanguage -eq 'ja') -and (Test-WindowsVersion -Version '10.0.17763' -Verbose))
    {
        Import-Module -Name (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Modules') -ChildPath 'ja-JP.ws2019.psm1') -Verbose:$false
        if (-not (Test-LanguagePack -Verbose)) { $result = $false }
        if (-not (Test-LanguageCapability -Verbose)) { $result = $false }
        if (-not (Test-PreferredLanguage -Verbose)) { $result = $false }
        if (Test-PhaseOneCompletionFlag -Verbose) { $result = $false }
    }
    else
    {
        Write-Verbose -Message ('This DSC resource does not support "{0}" language on this Windows version.' -f $PreferredLanguage)
    }

    $result
}

Export-ModuleMember -Function *-TargetResource
