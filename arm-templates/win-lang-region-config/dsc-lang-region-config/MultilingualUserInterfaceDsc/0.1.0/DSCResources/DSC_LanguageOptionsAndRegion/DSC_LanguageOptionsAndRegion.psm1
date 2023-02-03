$languageConstants = Import-PowerShellDataFile -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath 'lang-params.psd1')

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

    Write-Verbose -Message 'Getting the special account MUI configuration.'

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
    $osVersion = Get-OSVersion

    if (-not (Test-SupportedWindowsVersion -OSVersion $osVersion))
    {
        Write-Verbose -Message 'Current system''s Windows version is not supported.'
        return $result
    }

    if (-not (Test-SupportedLanguage -OSVersion $osVersion -Language $PreferredLanguage))
    {
        Write-Verbose -Message ('The preferred language "{0}" is not supported in OS version "{1}".' -f $PreferredLanguage, $osVersion)
        return $result
    }

    # Language pack package installation.
    $result = $result -and (Test-LanguagePackInstallation -OSVersion $osVersion -Language $PreferredLanguage)

    # Language capability installation.
    $languageCapabilityNames = Get-LanguageCapabilityNames -OSVersion $osVersion -Language $PreferredLanguage -CapabilityLevel $LanguageCapabilities
    $result = $result -and (Test-LanguageCapabilityInstallation -LanguageCapabilityNames $languageCapabilityNames)

    # Get the current configuration.
    $params = @{
        IsSingleInstance                 = $IsSingleInstance
        PreferredLanguage                = $PreferredLanguage
        LanguageCapabilities             = $LanguageCapabilities
        CopySettingsToDefaultUserAccount = $CopySettingsToDefaultUserAccount
    }
    if ($PSBoundParameters.ContainsKey('LocationGeoId')) { $params.LocationGeoId = $LocationGeoId }
    if ($PSBoundParameters.ContainsKey('SystemLocale')) { $params.SystemLocale = $SystemLocale }
    $currentConfig = Get-TargetResource @params -Verbose:$false

    # Language
    $subResult = ($PreferredLanguage -eq $currentConfig.PreferredLanguage)
    if ($subResult)
    {
        Write-Verbose -Message ('The preferred language is already set to "{0}".' -f $PreferredLanguage)
    }
    else
    {
        Write-Verbose -Message ('The preferred language is "{0}" but should be "{1}". Change required.' -f $currentConfig.PreferredLanguage, $PreferredLanguage)
    }
    $result = $result -and $subResult

    # CopySettingsToDefaultUserAccount
    if ($CopySettingsToDefaultUserAccount)
    {
        $params = @{
            PreferredLanguage = $PreferredLanguage
        }
        if ($PSBoundParameters.ContainsKey('LocationGeoId')) { $params.LocationGeoId = $LocationGeoId }
        $subResult = (Test-DefaultUserAccountSettings @params)
        if ($subResult)
        {
            Write-Verbose -Message ('The default user account settings are already set to the required configuration.')
        }
        else
        {
            Write-Verbose -Message ('The default user account settings are not set to the required configuration.')
        }
        $result = $result -and $subResult
    }

    # LocationGeoId
    if ($PSBoundParameters.ContainsKey('LocationGeoId'))
    {
        Write-Verbose -Message 'Testing the location geo ID.'

        $geoId = (Get-WinHomeLocation).GeoId
        $subResult = $LocationGeoId -eq $geoId
        if ($subResult)
        {
            Write-Verbose -Message ('The location geo ID is already set to "{0}".' -f $LocationGeoId)
        }
        else
        {
            Write-Verbose -Message ('The location geo ID is "{0}" but should be "{1}". Change required.' -f $geoId, $LocationGeoId)
        }
        $result = $result -and $subResult
    }

    # SystemLocale
    if ($PSBoundParameters.ContainsKey('SystemLocale'))
    {
        Write-Verbose -Message 'Testing the system locale.'

        if (-not (Test-CultureValue -CultureName $SystemLocale))
        {
            throw ('The system locale "{0}" is invalid.' -f $SystemLocale)
        }

        $locale = (Get-WinSystemLocale).Name
        $subResult = $SystemLocale -eq $locale
        if ($subResult)
        {
            Write-Verbose -Message ('The system locale is already set to "{0}".' -f $SystemLocale)
        }
        else
        {
            Write-Verbose -Message ('The system locale is "{0}" but should be "{1}". Change required.' -f $locale, $SystemLocale)
        }
        $result = $result -and $subResult
    }

    $result
}

function Get-OSVersion
{
    [CmdletBinding()]
    [OutputType([string])]
    param ()

    $osVersion = (Get-CimInstance -ClassName 'Win32_OperatingSystem' -Verbose:$false).Version
    Write-Verbose -Message ('Current system''s Windows version is "{0}".' -f $osVersion)
    $osVersion
}

function Test-SupportedWindowsVersion
{
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $OSVersion
    )

    $languageConstants.ContainsKey($OSVersion)
}

function Test-LanguagePackInstallation
{
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $OSVersion,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Language
    )

    Write-Verbose -Message 'Testing the language pack installation.'

    $languagePackPackageName = $languageConstants[$OSVersion][$Language].LanguagePack.PackageName
    $package = Get-WindowsPackage -Online -Verbose:$false | Where-Object -Property 'PackageName' -Like -Value $languagePackPackageName
    $result = ($package -ne $null) -and ($package.PackageState -eq [Microsoft.Dism.Commands.PackageFeatureState]::Installed)
    $stateText = if ($result) { 'installed' } else { 'not installed' }
    Write-Verbose -Message ('The language pack for "{0}" is {1}.' -f $Language, $stateText)
    $result
}

function Get-LanguageCapabilityNames
{
    [CmdletBinding()]
    [OutputType([string[]])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $OSVersion,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Language,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Minimum', 'All')]
        [string] $CapabilityLevel
    )

    if ($CapabilityLevel -eq 'Minimum')
    {
        $languageConstants[$OSVersion][$Language].CapabilityNames.Minimum
    }
    else
    {
        $languageConstants[$OSVersion][$Language].CapabilityNames.Minimum + $languageConstants[$OSVersion][$Language].CapabilityNames.Additional
    }
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
    foreach ($capabilityName in $LanguageCapabilityNames)
    {
        try
        {
            $capability = Get-WindowsCapability -Online -Name $capabilityName -Verbose:$false
            $subResult = $capability.State -eq [Microsoft.Dism.Commands.PackageFeatureState]::Installed
            $stateText = if ($subResult) { 'installed' } else { 'not installed' }
            Write-Verbose -Message ('The "{0}" capability is {1}.' -f $capabilityName, $stateText)
            $result = $result -and $subResult
        }
        catch
        {
            $result = $false
            Write-Verbose (@'
Exception:
{0}
ScriptStackTrace:
{1}
CategoryInfo: {2}
FullyQualifiedErrorId: {3}
'@ -f $errorMessage, $scriptStackTrace, $categoryInfo, $fullyQualifiedErrorId)
        }
    }
    $result
}

function Test-DefaultUserAccountSettings
{
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $PreferredLanguage,

        [Parameter(Mandatory = $false)]
        [int] $LocationGeoId
    )

    Write-Verbose -Message 'Testing the default user account settings.'

    $result = $true

    # PreferredUILanguages
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

    # LocaleName
    $localeName = (Get-Item -LiteralPath 'Registry::HKEY_USERS\.DEFAULT\Control Panel\International').GetValue('LocaleName')
    if ($localeName -ne $PreferredLanguage)
    {
        $result = $false
        Write-Verbose -Message ('The default user account''s LocaleName is "{0}" but should be "{1}". Change required.' -f $localeName, $PreferredLanguage)
    }

    # LocationGeoId
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

    $osVersion = Get-OSVersion

    # Install the language pack.
    if (-not (Test-LanguagePackInstallation -OSVersion $osVersion -Language $PreferredLanguage -Verbose:$false))
    {
        Install-LanguagePack -OSVersion $osVersion -Language $PreferredLanguage
        $global:DSCMachineStatus = 1
    }

    # Install the language capabilities.
    $languageCapabilityNames = Get-LanguageCapabilityNames -OSVersion $osVersion -Language $PreferredLanguage -CapabilityLevel $LanguageCapabilities
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
        [string] $OSVersion,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Language
    )

    # Get the language pack CAB file name.
    $langPackFilePath = Join-Path -Path $env:TEMP -ChildPath $languageConstants[$OSVersion][$Language].LanguagePack.CabFileName

    # Download the lanchage pack.
    Write-Verbose -Message ('Downloading the language pack "{0}" for "{1}".' -f $Language, $OSVersion)

    $params = @{
        langPackIsoUri           = $languageConstants[$OSVersion].langPackIsoUri
        OffsetToCabFileInIsoFile = $languageConstants[$OSVersion][$Language].LanguagePack.OffsetToCabFileInIsoFile
        CabFileSize              = $languageConstants[$OSVersion][$Language].LanguagePack.CabFileSize
        CabFileHash              = $languageConstants[$OSVersion][$Language].LanguagePack.CabFileHash
        DestinationFilePath      = $langPackFilePath
    }
    Invoke-LanguagePackCabFileDownload @params
    Write-Verbose -Message ('The language pack "{0}" for "{1}" has been downloaded.' -f $Language, $OSVersion)

    # Install the language pack.
    Write-Verbose -Message ('Installing the language pack "{0}".' -f $Language)
    Add-WindowsPackage -Online -NoRestart -PackagePath $langPackFilePath -Verbose:$false
    Write-Verbose -Message ('The language pack "{0}" has been installed.' -f $Language)

    # Delete the language pack CAB file.
    Remove-Item -LiteralPath $langPackFilePath -Force
    Write-Verbose -Message 'The temporary files for the language pack are deleted.'
}

function Invoke-LanguagePackCabFileDownload
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $langPackIsoUri,

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

    Write-Verbose -Message ('Downloading the language pack from "{0}".' -f $langPackIsoUri)

    $request = [System.Net.HttpWebRequest]::Create($langPackIsoUri)
    $request.Method = 'GET'

    # Set the language pack CAB file data range.
    $request.AddRange('bytes', $OffsetToCabFileInIsoFile, $OffsetToCabFileInIsoFile + $CabFileSize - 1)

    # Donwload the language pack CAB file.
    $response = $request.GetResponse()
    $reader = New-Object -TypeName 'System.IO.BinaryReader' -ArgumentList $response.GetResponseStream()
    $fileStream = [System.IO.File]::Create($DestinationFilePath)
    $contents = $reader.ReadBytes($response.ContentLength)
    $fileStream.Write($contents, 0, $contents.Length)
    $fileStream.Dispose()
    $reader.Dispose()
    $response.Close()
    $response.Dispose()

    # Verify integrity of the downloaded language pack CAB file.
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
    # - Guide to Windows Vista Multilingual User Interface
    #   https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-vista/cc721887(v=ws.10)
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

    Write-Verbose -Message ('MUI XML: {0}' -f $xmlFileContent)

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
        [string] $OSVersion,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Language
    )

    (Test-CultureValue -CultureName $Language) -and ($languageConstants[$OSVersion].ContainsKey($Language))
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

Export-ModuleMember -Function *-TargetResource
