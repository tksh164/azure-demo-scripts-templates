# Reference:
# Default Input Profiles (Input Locales) in Windows
# https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/default-input-locales-for-windows-language-packs
$languageConstants = @{
    'en-US' = @{
        LanguagePack = @{
            PackageName = 'Microsoft-Windows-Server-LanguagePack-Package~31bf3856ad364e35~amd64~en-US~10.0.17763.1'
            CabFileName = 'Microsoft-Windows-Server-Language-Pack_x64_en-us.cab'
            OffsetToCabFileInIsoFile = 0x1780D000
            CabFileSize              = 41441411
            CabFileHash              = 'B10C36225B9AFB503383FEA94A0D16FE4191CA37'
        }
        CapabilityNames = @{
            Minimum = @(
                'Language.Basic~~~en-US~0.0.1.0',
                'Language.OCR~~~en-US~0.0.1.0'
            )
            Additional = @(
                'Language.Handwriting~~~en-US~0.0.1.0',
                'Language.Speech~~~en-US~0.0.1.0',
                'Language.TextToSpeech~~~en-US~0.0.1.0'
            )
        }
        InputLanguageID = '0409:00000409'
    }
    'ja-JP' = @{
        LanguagePack = @{
            PackageName              = 'Microsoft-Windows-Server-LanguagePack-Package~31bf3856ad364e35~amd64~ja-JP~10.0.17763.1'
            CabFileName              = 'Microsoft-Windows-Server-Language-Pack_x64_ja-jp.cab'
            OffsetToCabFileInIsoFile = 0x3BD26800
            CabFileSize              = 62015873
            CabFileHash              = 'B562ECD51AFD32DB6E07CB9089691168C354A646'
        
        }
        CapabilityNames = @{
            Minimum = @(
                'Language.Basic~~~ja-JP~0.0.1.0',
                'Language.Fonts.Jpan~~~und-JPAN~0.0.1.0',
                'Language.OCR~~~ja-JP~0.0.1.0'
            )
            Additional = @(
                'Language.Handwriting~~~ja-JP~0.0.1.0',
                'Language.Speech~~~ja-JP~0.0.1.0',
                'Language.TextToSpeech~~~ja-JP~0.0.1.0'
            )
        }
        InputLanguageID = '0411:{03B5835F-F03C-411B-9CE2-AA23E1171E36}{A76C93D9-5523-4E90-AAFA-4DB112F9AC76}'
    }
    'fr-FR' = @{
        LanguagePack = @{
            PackageName = 'Microsoft-Windows-Server-LanguagePack-Package~31bf3856ad364e35~amd64~fr-FR~10.0.17763.1'
            CabFileName = 'Microsoft-Windows-Server-Language-Pack_x64_fr-fr.cab'
            OffsetToCabFileInIsoFile = 0x2ADB2000
            CabFileSize              = 60331188
            CabFileHash              = '02CBE6DC0302F15AFBBC9159E5A1AE81AAC86804'
        }
        CapabilityNames = @{
            Minimum = @(
                'Language.Basic~~~fr-FR~0.0.1.0'
                'Language.OCR~~~fr-FR~0.0.1.0'
            )
            Additional = @(
                'Language.Handwriting~~~fr-FR~0.0.1.0',
                'Language.Speech~~~fr-FR~0.0.1.0',
                'Language.TextToSpeech~~~fr-FR~0.0.1.0'
            )
        }
        InputLanguageID = '040c:0000040c'
    }
    'ko-KR' = @{
        LanguagePack = @{
            PackageName = 'Microsoft-Windows-Server-LanguagePack-Package~31bf3856ad364e35~amd64~ko-KR~10.0.17763.1'
            CabFileName = 'Microsoft-Windows-Server-Language-Pack_x64_ko-kr.cab'
            OffsetToCabFileInIsoFile = 0x3F84B800
            CabFileSize              = 62974463 
            CabFileHash              = '1370BBE78210CDF6D8156D9125C0D17C05607D82'
        }
        CapabilityNames = @{
            Minimum = @(
                'Language.Basic~~~ko-KR~0.0.1.0',
                'Language.Fonts.Kore~~~und-KORE~0.0.1.0',
                'Language.OCR~~~ko-KR~0.0.1.0'
            )
            Additional = @(
                'Language.Handwriting~~~ko-KR~0.0.1.0',
                'Language.TextToSpeech~~~ko-KR~0.0.1.0'
            )
        }
        InputLanguageID = '0412:{A028AE76-01B1-46C2-99C4-ACD9858AE02F}{B5FE1F02-D5F2-4445-9C03-C568F23C99A1}'
    }
}

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
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Minimum', 'All')]
        [string] $LanguageCapabilities,

        [Parameter(Mandatory = $true)]
        [bool] $CopySettingsToDefaultUserAccount,

        [Parameter(Mandatory = $false)]
        [int] $LocationGeoId,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $SystemLocale
    )

    Write-Verbose -Message 'Getting the special account MUI settings.'

    $result = @{
        IsSingleInstance                 = $IsSingleInstance
        PreferredLanguage                = (Get-UICulture).Name
        LanguageCapabilities             = $LanguageCapabilities
        CopySettingsToDefaultUserAccount = $CopySettingsToDefaultUserAccount
    }

    if ($PSBoundParameters.ContainsKey('LocationGeoId'))
    {
        $result.LocationGeoId = (Get-WinHomeLocation).GeoId
    }

    if ($PSBoundParameters.ContainsKey('SystemLocale'))
    {
        $result.SystemLocale = (Get-WinSystemLocale).Name
    }

    $result
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
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Minimum', 'All')]
        [string] $LanguageCapabilities,

        [Parameter(Mandatory = $true)]
        [bool] $CopySettingsToDefaultUserAccount,

        [Parameter(Mandatory = $false)]
        [int] $LocationGeoId,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $SystemLocale
    )

    $result = $true

    if (-not (Test-SupportedLanguage -Language $PreferredLanguage))
    {
        New-InvalidArgumentException -Message ('The preferred language "{0}" is not supported.' -f $PreferredLanguage) -ArgumentName 'PreferredLanguage'
    }

    # Language pack package installation.
    $result = (Test-LanguagePackInstallation -Language $PreferredLanguage) -and $result

    # Language capability installation.
    $languageCapabilityNames = if ($LanguageCapabilities -eq 'Minimum')
    {
        $languageConstants[$PreferredLanguage].CapabilityNames.Minimum
    }
    else
    {
        $languageConstants[$PreferredLanguage].CapabilityNames.Minimum + $languageConstants[$PreferredLanguage].CapabilityNames.Additional
    }
    $result = (Test-LanguageCapabilityInstallation -LanguageCapabilityNames $languageCapabilityNames) -and $result

    # Get the current settings.
    $params = @{
        IsSingleInstance                 = $IsSingleInstance
        PreferredLanguage                = $PreferredLanguage
        LanguageCapabilities             = $LanguageCapabilities
        CopySettingsToDefaultUserAccount = $CopySettingsToDefaultUserAccount
    }
    if ($PSBoundParameters.ContainsKey('LocationGeoId')) { $params.LocationGeoId = $LocationGeoId }
    if ($PSBoundParameters.ContainsKey('SystemLocale')) { $params.SystemLocale = $SystemLocale }
    $currentSettings = Get-TargetResource @params -Verbose:$false

    # Language
    $subResult = ($PreferredLanguage -eq $currentSettings.PreferredLanguage)
    $result = $subResult -and $result
    if ($subResult)
    {
        Write-Verbose -Message ('The preferred language is already set to "{0}".' -f $PreferredLanguage)
    }
    else
    {
        Write-Verbose -Message ('The preferred language is "{0}" but should be "{1}". Change required.' -f $currentSettings.PreferredLanguage, $PreferredLanguage)
    }

    # CopySettingsToDefaultUserAccount
    if ($CopySettingsToDefaultUserAccount)
    {
        $params = @{
            PreferredLanguage = $PreferredLanguage
        }
        if ($PSBoundParameters.ContainsKey('LocationGeoId')) { $params.LocationGeoId = $LocationGeoId }
        $subResult = (Test-DefaultUserAccountSettings @params)
        $result = $subResult -and $result
        if ($subResult)
        {
            Write-Verbose -Message ('The default user account settings are already set to the required configuration.')
        }
        else
        {
            Write-Verbose -Message ('The default user account settings are not set to the required configuration.')
        }
    }

    # LocationGeoId
    if ($PSBoundParameters.ContainsKey('LocationGeoId'))
    {
        Write-Verbose -Message 'Testing the location geo ID.'

        $geoId = (Get-WinHomeLocation).GeoId
        $subResult = ($LocationGeoId -eq $geoId) -and $result
        $result = $subResult -and $result
        if ($subResult)
        {
            Write-Verbose -Message ('The location geo ID is already set to "{0}".' -f $LocationGeoId)
        }
        else
        {
            Write-Verbose -Message ('The location geo ID is "{0}" but should be "{1}". Change required.' -f $geoId, $LocationGeoId)
        }
    }

    # SystemLocale
    if ($PSBoundParameters.ContainsKey('SystemLocale'))
    {
        Write-Verbose -Message 'Testing the system locale.'

        if (-not (Test-CultureValue -CultureName $SystemLocale))
        {
            New-InvalidArgumentException -Message ('The system locale "{0}" is invalid.' -f $SystemLocale) -ArgumentName 'SystemLocale'
        }

        $locale = (Get-WinSystemLocale).Name
        $subResult = ($SystemLocale -eq $locale) -and $result
        $result = $subResult -and $result
        if ($subResult)
        {
            Write-Verbose -Message ('The system locale is already set to "{0}".' -f $SystemLocale)
        }
        else
        {
            Write-Verbose -Message ('The system locale is "{0}" but should be "{1}". Change required.' -f $locale, $SystemLocale)
        }
    }

    $result
}

function Test-LanguagePackInstallation
{
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Language
    )

    Write-Verbose -Message 'Testing the language pack installation.'

    $languagePackPackageName = $languageConstants[$Language].LanguagePack.PackageName
    $package = Get-WindowsPackage -Online -Verbose:$false | Where-Object -Property 'PackageName' -EQ -Value $languagePackPackageName
    $result = ($package -ne $null) -and ($package.PackageState -eq [Microsoft.Dism.Commands.PackageFeatureState]::Installed)
    $stateText = if ($result) { 'installed' } else { 'not installed' }
    Write-Verbose -Message ('The language pack for "{0}" is {1}.' -f $Language, $stateText)
    $result
}

function Test-LanguageCapabilityInstallation
{
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true)]
        [string[]] $LanguageCapabilityNames
    )

    Write-Verbose -Message 'Testing the language capability installation.'

    $result = $true

    $LanguageCapabilityNames | ForEach-Object -Process {
        $capability = Get-WindowsCapability -Online -Name $_ -Verbose:$false
        $subResult = $capability.State -eq [Microsoft.Dism.Commands.PackageFeatureState]::Installed
        $result = $subResult -and $result
        $stateText = if ($subResult) { 'installed' } else { 'not installed' }
        Write-Verbose -Message ('The "{0}" capability is {1}.' -f $_, $stateText)
    }
    $result
}

function Test-DefaultUserAccountSettings
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $PreferredLanguage,

        [Parameter(Mandatory = $false)]
        [int] $LocationGeoId
    )

    Write-Verbose -Message 'Testing the default user account settings.'

    $reuslt = $true

    $preferredUILanguages = (Get-Item -LiteralPath 'Registry::HKEY_USERS\.DEFAULT\Control Panel\Desktop').GetValue('PreferredUILanguages')
    if (($preferredUILanguages -eq $null) -or ($preferredUILanguages.Length -eq 0))
    {
        $result = $false
        Write-Verbose -Message 'The default user account''s PreferredUILanguages is not set.'
    }
    elseif ($preferredUILanguages[0] -ne $PreferredLanguage)
    {
        $result = $false
        Write-Verbose -Message ('The default user account''s PreferredUILanguages is "{0}" but should be "{1}". Change required.' -f $preferredUILanguages[0], $PreferredLanguage)
    }

    $localeName = (Get-Item -LiteralPath 'Registry::HKEY_USERS\.DEFAULT\Control Panel\International').GetValue('LocaleName')
    if ($localeName -ne $PreferredLanguage)
    {
        $result = $false
        Write-Verbose -Message ('The default user account''s LocaleName is "{0}" but should be "{1}". Change required.' -f $localeName, $PreferredLanguage)
    }

    if ($PSBoundParameters.ContainsKey('LocationGeoId'))
    {
        $nation = (Get-Item -LiteralPath 'Registry::HKEY_USERS\.DEFAULT\Control Panel\International\Geo').GetValue('Nation')
        if ($nation -ne $LocationGeoId.ToString())
        {
            $result = $false
            Write-Verbose -Message ('The default user account''s Nation is "{0}" but should be "{1}". Change required.' -f $nation, $LocationGeoId)
        }
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
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Minimum', 'All')]
        [string] $LanguageCapabilities,

        [Parameter(Mandatory = $true)]
        [bool] $CopySettingsToDefaultUserAccount,

        [Parameter(Mandatory = $false)]
        [int] $LocationGeoId,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $SystemLocale
    )

    if (-not (Test-SupportedLanguage -Language $PreferredLanguage))
    {
        New-InvalidArgumentException -Message ('The preferred language "{0}" is not supported.' -f $PreferredLanguage) -ArgumentName 'PreferredLanguage'
    }

    # Install the language pack.
    if (-not (Test-LanguagePackInstallation -Language $PreferredLanguage -Verbose:$false))
    {
        Install-LanguagePack -Language $PreferredLanguage
        $global:DSCMachineStatus = 1
    }

    # Install the language capabilities.
    $languageCapabilityNames = if ($LanguageCapabilities -eq 'Minimum')
    {
        $languageConstants[$PreferredLanguage].CapabilityNames.Minimum
    }
    else
    {
        $languageConstants[$PreferredLanguage].CapabilityNames.Minimum + $languageConstants[$PreferredLanguage].CapabilityNames.Additional
    }
    if (-not (Test-LanguageCapabilityInstallation -LanguageCapabilityNames $languageCapabilityNames -Verbose:$false))
    {
        Install-LanguageCapability -LanguageCapabilityNames $languageCapabilityNames
        $global:DSCMachineStatus = 1
    }

    if ($global:DSCMachineStatus -eq 1)
    {
        # Reboot first if installed the language pack or capabilities at this time.
        return
    }

    # Set special account settings.
    $params = @{
        PreferredLanguage                = $PreferredLanguage
        InputLanguageID                  = $languageConstants[$PreferredLanguage].InputLanguageID
        CopySettingsToDefaultUserAccount = $CopySettingsToDefaultUserAccount
    }
    if ($PSBoundParameters.ContainsKey('LocationGeoId')) { $params.LocationGeoId = $LocationGeoId }
    if ($PSBoundParameters.ContainsKey('SystemLocale')) { $params.SystemLocale = $SystemLocale }
    Set-LanguageOptions @params
    $global:DSCMachineStatus = 1
}

function Install-LanguagePack
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Language
    )

    # Get the anguage pack CAB file name.
    $langPackFilePath = Join-Path -Path $env:TEMP -ChildPath $languageConstants[$Language].LanguagePack.CabFileName

    # Download the lanchage pack.
    Write-Verbose -Message ('Downloading the language pack for "{0}".' -f $Language)

    $params = @{
        OffsetToCabFileInIsoFile = $languageConstants[$Language].LanguagePack.OffsetToCabFileInIsoFile
        CabFileSize              = $languageConstants[$Language].LanguagePack.CabFileSize
        CabFileHash              = $languageConstants[$Language].LanguagePack.CabFileHash
        DestinationFilePath      = $langPackFilePath
    }
    Invoke-LanguagePackCabFileDownload @params
    Write-Verbose -Message ('The language pack for "{0}" has been downloaded.' -f $Language)

    # Install the language pack.
    Write-Verbose -Message ('Installing the language pack for "{0}".' -f $Language)
    Add-WindowsPackage -Online -NoRestart -PackagePath $langPackFilePath -Verbose:$false
    Write-Verbose -Message ('The language pack for "{0}" has been installed.' -f $Language)

    # Delete the lang pack CAB file.
    Remove-Item -LiteralPath $langPackFilePath -Force
    Write-Verbose -Message 'The temporary files for the language pack are deleted.'
}

function Invoke-LanguagePackCabFileDownload
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [long] $OffsetToCabFileInIsoFile,

        [Parameter(Mandatory = $true)]
        [long] $CabFileSize,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $CabFileHash,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $DestinationFilePath
    )

    # Ref: Cannot configure a language pack for Windows Server 2019 Desktop Experience
    #      https://docs.microsoft.com/en-us/troubleshoot/windows-server/shell-experience/cannot-configure-language-pack-windows-server-desktop-experience
    $langPackIsoUri = 'https://software-download.microsoft.com/download/pr/17763.1.180914-1434.rs5_release_SERVERLANGPACKDVD_OEM_MULTI.iso'  # WS2019
    $request = [System.Net.HttpWebRequest]::Create($langPackIsoUri)
    $request.Method = 'GET'

    # Set the language pack CAB file data range.
    $request.AddRange('bytes', $OffsetToCabFileInIsoFile, $OffsetToCabFileInIsoFile + $CabFileSize - 1)

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
    $fileHash = Get-FileHash -Algorithm SHA1 -LiteralPath $DestinationFilePath
    if ($fileHash.Hash -ne $CabFileHash) {
        throw ('The file hash of the language pack CAB file "{0}" is not match to expected value. The download was may failed.') -f $DestinationFilePath
    }
}

function Install-LanguageCapability
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]] $LanguageCapabilityNames
    )

    $LanguageCapabilityNames | ForEach-Object -Process {
        $capability = Get-WindowsCapability -Online -Name $_ -Verbose:$false
        $capabilityState = $capability.State -eq [Microsoft.Dism.Commands.PackageFeatureState]::Installed
        if (-not $capabilityState)
        {
            Write-Verbose -Message ('Installing the "{0}" capability.' -f $_)
            Add-WindowsCapability -Online -Name $_ -Verbose:$false
            Write-Verbose -Message ('The capability "{0}" has been installed.' -f $_)
        }
    }
}

function Set-LanguageOptions
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $PreferredLanguage,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $InputLanguageID,

        [Parameter(Mandatory = $true)]
        [bool] $CopySettingsToDefaultUserAccount,

        [Parameter(Mandatory = $false)]
        [int] $LocationGeoId,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $SystemLocale
    )

    # Reference:
    # How to Automate Regional and Language settings in Windows Vista, Windows Server 2008, Windows 7 and in Windows Server 2008 R2
    # https://docs.microsoft.com/en-us/troubleshoot/windows-client/deployment/automate-regional-language-settings
    $xmlFragmentTemplateLocationPreferences = '<gs:LocationPreferences><gs:GeoID Value="{0}"/></gs:LocationPreferences>'
    $xmlFragmentTemplateSystemLocale = '<gs:SystemLocale Name="{0}"/>'
    $xmlFileContentTemplate = @'
<gs:GlobalizationServices xmlns:gs="urn:longhornGlobalizationUnattend">
    <gs:UserList>
        <gs:User UserID="Current" CopySettingsToSystemAcct="true" CopySettingsToDefaultUserAcct="{0}"/>
    </gs:UserList>
    <gs:UserLocale>
        <gs:Locale Name="{1}" SetAsCurrent="true"/>
    </gs:UserLocale>
    <gs:InputPreferences>
        <gs:InputLanguageID Action="add" ID="{2}" Default="true"/>
    </gs:InputPreferences>
    <gs:MUILanguagePreferences>
        <gs:MUILanguage Value="{1}"/>
        <gs:MUIFallback Value="en-US"/>
    </gs:MUILanguagePreferences>
    {3}
    {4}
</gs:GlobalizationServices>
'@

    # Create the XML file content.
    $xmlFragmentLocationPreferences = if ($PSBoundParameters.ContainsKey('LocationGeoId')) { $xmlFragmentTemplateLocationPreferences -f $LocationGeoId } else { '' }
    $xmlFragmentSystemLocale = if ($PSBoundParameters.ContainsKey('SystemLocale')) { $xmlFragmentTemplateSystemLocale -f $SystemLocale } else { '' }
    $fillValues = @(
        $CopySettingsToDefaultUserAccount.ToString().ToLowerInvariant(),
        $PreferredLanguage,
        $InputLanguageID,
        $xmlFragmentLocationPreferences,
        $xmlFragmentSystemLocale
    )
    $xmlFileContent = $xmlFileContentTemplate -f $fillValues

    Write-Verbose -Message ('XML: {0}' -f $xmlFileContent)

    # Create a new XML file and set the content.
    $xmlFileFilePath = Join-Path -Path $env:TEMP -ChildPath ((New-Guid).Guid + '.xml')
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

function Test-SupportedLanguage
{
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Language
    )

    (Test-CultureValue -CultureName $Language) -and ($languageConstants.ContainsKey($Language))
}

function Test-CultureValue
{
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true)]
        [string] $CultureName
    )

    $validCultures = [System.Globalization.CultureInfo]::GetCultures([System.Globalization.CultureTypes]::AllCultures).Name
    $CultureName -in $validCultures
}

function New-InvalidArgumentException
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Message,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ArgumentName
    )

    $argumentException = New-Object -TypeName 'ArgumentException' -ArgumentList $Message, $ArgumentName

    $params = @{
        TypeName     = 'System.Management.Automation.ErrorRecord'
        ArgumentList = $argumentException, $ArgumentName, 'InvalidArgument', $null
    }
    $errorRecord = New-Object @params
    throw $errorRecord
}

Export-ModuleMember -Function *-TargetResource
