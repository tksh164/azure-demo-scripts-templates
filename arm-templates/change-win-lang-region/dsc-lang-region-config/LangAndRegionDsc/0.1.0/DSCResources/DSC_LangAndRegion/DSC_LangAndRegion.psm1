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
        #
        # Install the Japanese language pack.
        #

        #Write-Verbose -Message ('Getting the language pack installation state for "{0}".' -f $PreferredLanguage)

        if (Test-LanguagePackInstallationState)
        {
            Write-Verbose -Message ('The language pack for "{0}" is already installed.' -f $PreferredLanguage)
        }
        else
        {
            Write-Verbose -Message ('The language pack for "{0}" is not installed.' -f $PreferredLanguage)

            # Download the lang pack CAB file.
            Write-Verbose -Message 'Downloading the language pack.'
            $langPackFilePath = Join-Path -Path $env:TEMP -ChildPath 'Microsoft-Windows-Server-Language-Pack_x64_ja-jp.cab'
            Get-JapaneseLangPackCabFile -DestinationFilePath $langPackFilePath

            # Install the language pack.
            Write-Verbose -Message 'Installing the language pack.'
            Add-WindowsPackage -Online -NoRestart -PackagePath $langPackFilePath -Verbose:$false

            # Delete the lang pack CAB file.
            Write-Verbose -Message 'Deleting the language pack temporary file.'
            Remove-Item -LiteralPath $langPackFilePath -Force

            # The prerequisite is met for the UI language update and the copy settings to the default/system account.
            $isPrerequisiteMet = $true

            # Need to reboot for effect to the language pack installation.
            $global:DSCMachineStatus = 1
        }

        #
        # Install the Japanese language related capabilities.
        #

        #Write-Verbose -Message ('Getting the language related capabilities installation state for "{0}".' -f $PreferredLanguage)

        Get-RequiredWindowsCapabilityNames | ForEach-Object -Process {
            if (Test-WindowsCapabilityInstallationState -WindowsCapabilityName $_)
            {
                Write-Verbose -Message ('The "{0}" capability is already installed.' -f $_)
            }
            else
            {
                Write-Verbose -Message ('Installing the "{0}" capability.' -f $_)
                Add-WindowsCapability -Online -Name $_ -Verbose:$false
                $global:DSCMachineStatus = 1
            }
        }

        #
        # Set the preferred language for the current user account.
        #

        #Write-Verbose -Message 'Getting the preferred language setting for the current user account.'

        $langList = Get-WinUserLanguageList
        if ($langList[0].LanguageTag -eq $PreferredLanguage)
        {
            Write-Verbose -Message ('The preferred language is already set to "{0}".' -f $PreferredLanguage)
        }
        else
        {
            Write-Verbose -Message ('Setting the preferred language to "{0}"' -f $PreferredLanguage)
            $jaItems = $langList | Where-Object -Property 'LanguageTag' -EQ -Value $PreferredLanguage
            $jaItems | ForEach-Object -Process { $langList.Remove($_) }
            $langList.Insert(0, $PreferredLanguage)
            Set-WinUserLanguageList -LanguageList $langList -Force
        }

        $prerequisiteMetFlagFilePath = Get-PrerequisiteMetFlagFilePath
        if ([System.IO.File]::Exists($prerequisiteMetFlagFilePath))
        {
            #
            # Override the Windows UI language for the current user account.
            #

            #Write-Verbose -Message 'Getting the UI language setting for the current user account.'

            Write-Verbose -Message ('Setting the UI language to "{0}"' -f $PreferredLanguage)
            Set-WinUILanguageOverride -Language ja-JP

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
        #
        # Test the Japanese language pack installation.
        #

        #Write-Verbose -Message ('Getting the language pack installation state for "{0}".' -f $PreferredLanguage)
        if (Test-LanguagePackInstallationState)
        {
            Write-Verbose -Message ('The language pack for "{0}" is already installed.' -f $PreferredLanguage)
        }
        else
        {
            Write-Verbose -Message ('The language pack for "{0}" is not installed.' -f $PreferredLanguage)
            $result = $false
        }

        #
        # Test the Japanese language related capabilities installation.
        #

        #Write-Verbose -Message ('Getting the language related capabilities installation state for "{0}".' -f $PreferredLanguage)
        Get-RequiredWindowsCapabilityNames | ForEach-Object -Process {
            if (Test-WindowsCapabilityInstallationState -WindowsCapabilityName $_)
            {
                Write-Verbose -Message ('The "{0}" capability is already installed.' -f $_)
            }
            else
            {
                Write-Verbose -Message ('The "{0}" capability is not installed.' -f $_)
                $result = $false
            }
        }
       
        #
        # Set the preferred language for the current user account.
        #

        #Write-Verbose -Message 'Getting the preferred language setting for the current user account.'

        $langList = Get-WinUserLanguageList
        if ($langList[0].LanguageTag -eq $PreferredLanguage)
        {
            Write-Verbose -Message ('The preferred language is already set to "{0}"' -f $PreferredLanguage)
        }
        else
        {
            Write-Verbose -Message ('The preferred language is not set to "{0}"' -f $PreferredLanguage)
            $result = $false
        }

        #
        # Override the Windows UI language for the current user account.
        #

        #Write-Verbose -Message 'Getting the UI language setting for the current user account.'

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
        #Write-Verbose -Message 'Getting the location ID for the current user account.'

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

function Test-LanguagePackInstallationState
{
    [CmdletBinding()]
    [OutputType([bool])]
    param ()

    $langPackPackageName = 'Microsoft-Windows-Server-LanguagePack-Package~31bf3856ad364e35~amd64~ja-JP~10.0.17763.1'
    $package = Get-WindowsPackage -Online -Verbose:$false | Where-Object -Property 'PackageName' -EQ -Value $langPackPackageName
    $package -ne $null
}

function Get-RequiredWindowsCapabilityNames
{
    [CmdletBinding()]
    param ()

    return @(
        'Language.Basic~~~ja-JP~0.0.1.0',
        'Language.Fonts.Jpan~~~und-JPAN~0.0.1.0',
        'Language.Handwriting~~~ja-JP~0.0.1.0',
        'Language.OCR~~~ja-JP~0.0.1.0',
        'Language.Speech~~~ja-JP~0.0.1.0',
        'Language.TextToSpeech~~~ja-JP~0.0.1.0'
    )
}

function Test-WindowsCapabilityInstallationState
{
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true)]
        [string] $WindowsCapabilityName
    )

    $capability = Get-WindowsCapability -Online -Name $WindowsCapabilityName -Verbose:$false
    $capability.State -eq [Microsoft.Dism.Commands.PackageFeatureState]::Installed
}

function Get-PrerequisiteMetFlagFilePath
{
    [CmdletBinding()]
    param ()

    return Join-Path -Path $env:TEMP -ChildPath 'dsc-international-settings-prerequisites-are-met'
}

function Get-JapaneseLangPackCabFile
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $DestinationFilePath
    )

    # Ref: Cannot configure a language pack for Windows Server 2019 Desktop Experience
    #      https://docs.microsoft.com/en-us/troubleshoot/windows-server/shell-experience/cannot-configure-language-pack-windows-server-desktop-experience
    $LANG_PACK_ISO_URI = 'https://software-download.microsoft.com/download/pr/17763.1.180914-1434.rs5_release_SERVERLANGPACKDVD_OEM_MULTI.iso'  # WS2019
    $request = [System.Net.HttpWebRequest]::Create($LANG_PACK_ISO_URI)
    $request.Method = 'GET'

    # Set the Japanese language pack CAB file data range.
    $OFFSET_TO_JP_LANG_CAB_FILE_IN_ISO_FILE = 1003644928
    $JP_LANG_CAB_FILE_SIZE = 62015873
    $request.AddRange('bytes', $OFFSET_TO_JP_LANG_CAB_FILE_IN_ISO_FILE, $OFFSET_TO_JP_LANG_CAB_FILE_IN_ISO_FILE + $JP_LANG_CAB_FILE_SIZE - 1)

    # Donwload the lang pack CAB file.
    $response = $request.GetResponse()
    $reader = New-Object -TypeName 'System.IO.BinaryReader' -ArgumentList $response.GetResponseStream()
    $contents = $reader.ReadBytes($response.ContentLength)
    $reader.Dispose()

    # Save the lang pack CAB file.
    $fileStream = [System.IO.File]::Create($DestinationFilePath)
    $fileStream.Write($contents, 0, $contents.Length)
    $fileStream.Dispose()

    # Verify integrity to the downloaded lang pack CAB file.
    $JP_LANG_CAB_FILE_HASH = 'B562ECD51AFD32DB6E07CB9089691168C354A646'
    $fileHash = Get-FileHash -Algorithm SHA1 -LiteralPath $DestinationFilePath
    if ($fileHash.Hash -ne $JP_LANG_CAB_FILE_HASH) {
        throw ('"{0}" is corrupted. The download was may failed.') -f $DestinationFilePath
    }
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
