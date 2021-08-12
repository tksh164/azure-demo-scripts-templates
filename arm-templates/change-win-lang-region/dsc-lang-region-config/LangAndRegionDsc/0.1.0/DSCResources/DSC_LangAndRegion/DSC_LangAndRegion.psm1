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

    $langList = Get-WinUserLanguageList
    $preferredLanguage = $langList[0].LanguageTag

    $locationGeoId = (Get-WinHomeLocation).GeoId

    $returnValue = @{
        IsSingleInstance     = 'Yes'
        PreferredLanguage    = $preferredLanguage
        LocationGeoId        = $locationGeoId
        CopyToDefaultAccount = $false
        CopyToSystemAccount  = $false
    }

    return $returnValue
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
        [int] $LocationGeoId,

        [Parameter(Mandatory = $false)]
        [bool] $CopyToDefaultAccount = $false,

        [Parameter(Mandatory = $false)]
        [bool] $CopyToSystemAccount = $false
    )

    $isPrerequisiteMet = $false

    # TODO: Require OS version detection.
    if ($PreferredLanguage -eq 'ja')
    {
        Import-Module -Name (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Modules') -ChildPath 'ws2019-ja-jp.psm1') -Verbose:$false

        if (-not (Test-LanguagePack))
        {
            # Install the Japanese language pack.
            Install-LanguagePack -Verbose

            # The prerequisite is met for the UI language update and the copy settings to the default/system account.
            $isPrerequisiteMet = $true

            # Need to reboot for effect to the language pack installation.
            $global:DSCMachineStatus = 1
        }

        if (-not (Test-LanguageCapability))
        {
            # Install the Japanese language related capabilities.
            Install-LanguageCapability -Verbose
            $global:DSCMachineStatus = 1
        }

        if (-not (Test-PreferredLanguage))
        {
            # Set the preferred language for the current user account.
            Set-PreferredLanguage -Verbose
        }

        $prerequisiteMetFlagFilePath = Get-PrerequisiteMetFlagFilePath
        if ([System.IO.File]::Exists($prerequisiteMetFlagFilePath))
        {
            # Override the Windows UI language for the current user account.
            Set-UILanguage -Verbose

            # Delete the flag file.
            Write-Verbose -Message 'Deleting the prerequisite met flag file.'
            Remove-Item -LiteralPath $prerequisiteMetFlagFilePath -Force

            #
            # Copy the current user language settings to default user account and system user account.
            #

            if ($CopyToDefaultAccount -or $CopyToSystemAccount)
            {
                if ($CopyToDefaultAccount) { Write-Verbose -Message 'Copying the current user language settings to the default account.' }
                if ($CopyToSystemAccount) { Write-Verbose -Message 'Copying the current user language settings to the system account.' }
                Copy-LanguageSttingsToDefaultAndSystemAccount -CopyToDefaultAccount $CopyToDefaultAccount -CopyToSystemAccount $CopyToSystemAccount
            }

            # Need to reboot for effect to the UI language change and the copy settings to the default/system account.
            $global:DSCMachineStatus = 1
        }
        else
        {
            Write-Verbose -Message ('The prerequisite met flag file is not located at "{0}".' -f $prerequisiteMetFlagFilePath)
        }
    }
    else
    {
        Write-Verbose -Message ('"{0}" is not supported language.' -f $PreferredLanguage)
    }

    #
    # Set the home location for the current user account.
    #

    if ($PSBoundParameters.ContainsKey('LocationGeoId'))
    {
        #Write-Verbose -Message 'Getting the location ID for the current user account.'
        
        if ((Get-WinHomeLocation).GeoId -eq $LocationGeoId)
        {
            Write-Verbose -Message ('The location ID is already set to "{0}".' -f $LocationGeoId)
        }
        else
        {
            Write-Verbose -Message ('Setting the location ID to "{0}"' -f $LocationGeoId)
            Set-WinHomeLocation -GeoId $LocationGeoId
        }
    }

    # Create the flag file.
    if ($isPrerequisiteMet)
    {
        $prerequisiteMetFlagFilePath = Get-PrerequisiteMetFlagFilePath
        Write-Verbose -Message ('Creating the prerequisite met flag file to "{0}".' -f $prerequisiteMetFlagFilePath)
        Set-Content -LiteralPath $prerequisiteMetFlagFilePath -Value '' -Force
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

        [Parameter(Mandatory = $false)]
        [int] $LocationGeoId,

        [Parameter(Mandatory = $false)]
        [bool] $CopyToDefaultAccount = $false,

        [Parameter(Mandatory = $false)]
        [bool] $CopyToSystemAccount = $false
    )

    $result = $true

    # TODO: Require OS version detection.
    if ($PreferredLanguage -eq 'ja')
    {
        Import-Module -Name (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Modules') -ChildPath 'ws2019-ja-jp.psm1') -Verbose:$false

        # Test the Japanese language pack installation.
        if (-not (Test-LanguagePack -Verbose)) { $result = $false }

        # Test the Japanese language related capabilities installation.
        if (-not (Test-LanguageCapability -Verbose)) { $result = $false }

        # Set the preferred language for the current user account.
        if (-not (Test-PreferredLanguage -Verbose)) { $result = $false }

        $prerequisiteMetFlagFilePath = Get-PrerequisiteMetFlagFilePath
        if ([System.IO.File]::Exists($prerequisiteMetFlagFilePath))
        {
            Write-Verbose -Message ('The prerequisite met flag file is located at "{0}".' -f $prerequisiteMetFlagFilePath)
            $result = $false
        }
        else
        {
            Write-Verbose -Message ('The prerequisite met flag file is not located at "{0}".' -f $prerequisiteMetFlagFilePath)
        }
    }
    else
    {
        Write-Verbose -Message ('"{0}" is not supported language.' -f $PreferredLanguage)
    }

    #
    # Set the home location for the current user account.
    #

    if ($PSBoundParameters.ContainsKey('LocationGeoId'))
    {
        if ((Get-WinHomeLocation).GeoId -eq $LocationGeoId)
        {
            Write-Verbose -Message ('The location ID is already set to "{0}".' -f $LocationGeoId)
        }
        else
        {
            Write-Verbose -Message ('The location ID is not set to "{0}".' -f $LocationGeoId)
            $result = $false
        }
    }

    $result
}

function Get-PrerequisiteMetFlagFilePath
{
    [CmdletBinding()]
    param ()

    return Join-Path -Path $env:TEMP -ChildPath 'dsc-international-settings-prerequisites-are-met'
}

function Copy-LanguageSttingsToDefaultAndSystemAccount
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [bool] $CopyToDefaultAccount = $false,

        [Parameter(Mandatory = $true)]
        [bool] $CopyToSystemAccount = $false
    )

    # Ref: How to Automate Regional and Language settings in Windows Vista, Windows Server 2008, Windows 7 and in Windows Server 2008 R2
    #      https://docs.microsoft.com/en-us/troubleshoot/windows-client/deployment/automate-regional-language-settings
    $XML_FILE_CONTENT_TEMPLATE = @'
<gs:GlobalizationServices xmlns:gs="urn:longhornGlobalizationUnattend">
    <gs:UserList>
        <gs:User UserID="Current" CopySettingsToDefaultUserAcct="{0}" CopySettingsToSystemAcct="{1}"/> 
    </gs:UserList>
</gs:GlobalizationServices>
'@

    # Create a XML file.
    $xmlFileFilePath = Join-Path -Path $env:TEMP -ChildPath ((New-Guid).Guid + '.xml')
    $xmlFileContent = ($XML_FILE_CONTENT_TEMPLATE -f $CopyToDefaultAccount.ToString().ToLowerInvariant(), $CopyToSystemAccount.ToString().ToLowerInvariant())
    Set-Content -LiteralPath $xmlFileFilePath -Encoding UTF8 -Value $xmlFileContent

    # Copy the current user language settings to default user account and system user account.
    $procStartInfo = New-Object -TypeName 'System.Diagnostics.ProcessStartInfo' -ArgumentList 'C:\Windows\System32\control.exe', ('intl.cpl,,/f:"{0}"' -f $xmlFileFilePath)
    $procStartInfo.UseShellExecute = $false
    $procStartInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Minimized
    $proc = [System.Diagnostics.Process]::Start($procStartInfo)
    $proc.WaitForExit()

    # Delete the XML file.
    Remove-Item -LiteralPath $xmlFileFilePath -Force
}

Export-ModuleMember -Function *-TargetResource
