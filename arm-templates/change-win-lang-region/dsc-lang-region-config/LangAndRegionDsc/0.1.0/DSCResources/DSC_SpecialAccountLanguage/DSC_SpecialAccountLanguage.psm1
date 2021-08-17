function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [string] $IsSingleInstance,

        [Parameter(Mandatory = $true)]
        [bool] $CopyToDefaultAccount,

        [Parameter(Mandatory = $true)]
        [bool] $CopyToSystemAccount,

        [Parameter(Mandatory = $true)]
        [bool] $RebootAfterCopy
    )

    Write-Verbose -Message 'Getting the special accounts language.'

    return @{
        IsSingleInstance         = $IsSingleInstance
        CopyToDefaultAccount     = $CopyToDefaultAccount
        CopyToSystemAccount      = $CopyToSystemAccount
        RebootAfterCopy          = $RebootAfterCopy
        CurrentAccountCulture    = (Get-Culture).Name
        CurrentAccountGeoId      = (Get-WinHomeLocation).GeoId.ToString()
        DefaultAccountLocaleName = Get-SpecialAccountRegistryValue -Account Default -Name LocaleName
        DefaultAccountNation     = Get-SpecialAccountRegistryValue -Account Default -Name Nation
        SystemAccountLocaleName  = Get-SpecialAccountRegistryValue -Account System -Name LocaleName
        SystemAccountNation      = Get-SpecialAccountRegistryValue -Account System -Name Nation
    }
}

function Get-SpecialAccountRegistryValue
{
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Default', 'System')]
        [string] $Account,

        [Parameter(Mandatory = $true)]
        [ValidateSet('LocaleName', 'Nation')]
        [string] $Name
    )

    $accountKey = if ($Account -eq 'Default') { '.DEFAULT' } else { 'S-1-5-18' }
    $subKey = if ($Name -eq 'LocaleName') { 'Control Panel\International' } else { 'Control Panel\International\Geo' }
    $path = 'Registry::HKEY_USERS\{0}\{1}' -f $accountKey, $subKey
    (Get-Item -LiteralPath $path).GetValue($Name)
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
        [bool] $CopyToDefaultAccount,

        [Parameter(Mandatory = $true)]
        [bool] $CopyToSystemAccount,

        [Parameter(Mandatory = $true)]
        [bool] $RebootAfterCopy
    )

    if (-not ($CopyToDefaultAccount -or $CopyToSystemAccount))
    {
        Write-Verbose -Message 'Skip copy of the special account''s language settings because any target accounts not specified.'
        return $true
    }

    # Current user account's culture and geo ID.
    $currentAccountCulture = (Get-Culture).Name
    $currentAccountGeoId = (Get-WinHomeLocation).GeoId.ToString()

    $result = $true

    if ($CopyToDefaultAccount)
    {
        $accountNameText = 'default'

        # Default account's culture.
        $currentDefaultAccountCulture = Get-SpecialAccountRegistryValue -Account Default -Name LocaleName
        $subResult = $currentAccountCulture -eq $currentDefaultAccountCulture
        if ($subResult)
        {
            Write-Verbose -Message ('The {0} account''s culture is already set to "{1}".' -f $accountNameText, $currentDefaultAccountCulture)
        }
        else
        {
            Write-Verbose -Message ('The {0} account''s culture is "{1}" but should be "{2}". Change required.' -f $accountNameText, $currentDefaultAccountCulture, $currentAccountCulture)
        }
        $result = $result -and $subResult

        # Default account's geo ID.
        $currentDefaultAccountGeoId = Get-SpecialAccountRegistryValue -Account Default -Name Nation
        $subResult = $currentAccountGeoId -eq $currentDefaultAccountGeoId
        if ($subResult)
        {
            Write-Verbose -Message ('The {0} account''s geo location ID is already set to "{1}".' -f $accountNameText, $currentDefaultAccountGeoId)
        }
        else
        {
            Write-Verbose -Message ('The {0} account''s geo location ID is "{1}" but should be "{2}". Change required.' -f $accountNameText, $currentDefaultAccountGeoId, $currentAccountGeoId)
        }
        $result = $result -and $subResult
    }

    if ($CopyToSystemAccount)
    {
        $accountNameText = 'system'

        # System account's culture.
        $currentSystemAccountCulture = Get-SpecialAccountRegistryValue -Account System -Name LocaleName
        $subResult = $currentAccountCulture -eq $currentSystemAccountCulture
        if ($subResult)
        {
            Write-Verbose -Message ('The {0} account''s culture is already set to "{1}".' -f $accountNameText, $currentSystemAccountCulture)
        }
        else
        {
            Write-Verbose -Message ('The {0} account''s culture is "{1}" but should be "{2}". Change required.' -f $accountNameText, $currentSystemAccountCulture, $currentAccountCulture)
        }
        $result = $result -and $subResult

        # System account's geo ID.
        $currentSystemAccountGeoId = Get-SpecialAccountRegistryValue -Account System -Name Nation
        $subResult = $currentAccountGeoId -eq $currentSystemAccountGeoId
        if ($subResult)
        {
            Write-Verbose -Message ('The {0} account''s geo location ID is already set to "{1}".' -f $accountNameText, $currentSystemAccountGeoId)
        }
        else
        {
            Write-Verbose -Message ('The {0} account''s geo location ID is "{1}" but should be "{2}". Change required.' -f $accountNameText, $currentSystemAccountGeoId, $currentAccountGeoId)
        }
        $result = $result -and $subResult
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
        [bool] $CopyToDefaultAccount,

        [Parameter(Mandatory = $true)]
        [bool] $CopyToSystemAccount,

        [Parameter(Mandatory = $true)]
        [bool] $RebootAfterCopy
    )

    if (-not ($CopyToDefaultAccount -or $CopyToSystemAccount))
    {
        Write-Verbose -Message 'Skip copy of the special account''s language settings because any target accounts not specified.'
        return
    }

    $targetAccountText = if ($CopyToDefaultAccount -and $CopyToSystemAccount)
    {
        'the default account and system account'
    }
    elseif ($CopyToDefaultAccount)
    {
        'the default account'
    }
    elseif ($CopyToSystemAccount)
    {
        'the system account'
    }
    Write-Verbose -Message ('Copying the current user language settings to {0}.' -f $targetAccountText)

    Copy-CurrentUserLanguageSettingsToSpecialAccount -CopyToDefaultAccount $CopyToDefaultAccount -CopyToSystemAccount $CopyToSystemAccount

    if ($RebootAfterCopy)
    {
        $global:DSCMachineStatus = 1
    }
}

function Copy-CurrentUserLanguageSettingsToSpecialAccount
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [bool] $CopyToDefaultAccount,

        [Parameter(Mandatory = $true)]
        [bool] $CopyToSystemAccount
    )

    # Reference:
    # How to Automate Regional and Language settings in Windows Vista, Windows Server 2008, Windows 7 and in Windows Server 2008 R2
    # https://docs.microsoft.com/en-us/troubleshoot/windows-client/deployment/automate-regional-language-settings
    $xmlFileContentTemplate = @'
<gs:GlobalizationServices xmlns:gs="urn:longhornGlobalizationUnattend">
    <gs:UserList>
        <gs:User UserID="Current" CopySettingsToDefaultUserAcct="{0}" CopySettingsToSystemAcct="{1}"/> 
    </gs:UserList>
</gs:GlobalizationServices>
'@

    # Create a new XML file and set the content.
    $xmlFileFilePath = Join-Path -Path $env:TEMP -ChildPath ((New-Guid).Guid + '.xml')
    $xmlFileContent = ($xmlFileContentTemplate -f $CopyToDefaultAccount.ToString().ToLowerInvariant(), $CopyToSystemAccount.ToString().ToLowerInvariant())
    Set-Content -LiteralPath $xmlFileFilePath -Encoding UTF8 -Value $xmlFileContent

    # Copy the current user language settings to the default user account and system user account.
    $procStartInfo = New-Object -TypeName 'System.Diagnostics.ProcessStartInfo' -ArgumentList 'C:\Windows\System32\control.exe', ('intl.cpl,,/f:"{0}"' -f $xmlFileFilePath)
    $procStartInfo.UseShellExecute = $false
    $procStartInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Minimized
    $proc = [System.Diagnostics.Process]::Start($procStartInfo)
    $proc.WaitForExit()

    # Delete the XML file.
    Remove-Item -LiteralPath $xmlFileFilePath -Force
}

Export-ModuleMember -Function *-TargetResource
