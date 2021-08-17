Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'Common.psm1') -Verbose:$false

$targetLanguageTag = 'ja'
$targetLanguageTagLong = 'ja-JP'
$targetLanguageInputMethodTip = '0411:{03B5835F-F03C-411B-9CE2-AA23E1171E36}{A76C93D9-5523-4E90-AAFA-4DB112F9AC76}'

function Test-Language
{
    [CmdletBinding()]
    [OutputType([bool])]
    param ()

    $result = $true
    $result = (Test-LanguagePack -Verbose) -and $result
    $result = (Test-LanguageCapability -Verbose) -and $result
    $result = (Test-UILanguage -Verbose) -and $result
    $result = (Test-InputMethodLanguage -Verbose) -and $result
    #$result = (Test-SystemAccountCopyState -Verbose) -and $result
    #$result = (Test-DefaultAccountCopyState -Verbose) -and $result
    #$result = (Test-PreferredLanguage -Verbose) -and $result
    #$result = (Test-CultureInfo -Verbose) -and $result
    $result
}

function Set-Language
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [bool] $CopyToDefaultAccount
    )

    if (-not (Test-LanguagePack))
    {
        Install-LanguagePack -Verbose
        $global:DSCMachineStatus = 1
    }

    if (-not (Test-LanguageCapability))
    {
        Install-LanguageCapability -Verbose
        $global:DSCMachineStatus = 1
    }

    # Skip the UI language configuration if already scheduled reboot.
    if (($global:DSCMachineStatus -ne 1) -and (-not (Test-UILanguage)))
    {
        Set-UILanguage -Verbose
        $global:DSCMachineStatus = 1
    }

    # Skip the input method language configuration if already scheduled reboot.
    if ($global:DSCMachineStatus -ne 1)
    {
        #if ((-not (Test-InputMethodLanguage)) -or (-not (Test-SystemAccountCopyState)) -or ($CopyToDefaultAccount -and (-not (Test-DefaultAccountCopyState))))
        #if ((-not (Test-InputMethodLanguage)) -or ($CopyToDefaultAccount -and (-not (Test-DefaultAccountCopyState))))
        if (-not (Test-InputMethodLanguage))
        {
            Set-InputMethodLanguage -Verbose
            Copy-LanguageSttingsToSpecialAccount -CopyToSystemAccount $true -CopyToDefaultAccount $CopyToDefaultAccount
            $global:DSCMachineStatus = 1
        }
    }
}

function Install-LanguagePack
{
    [CmdletBinding()]
    param ()

    # Download the lang pack CAB file.
    Write-Verbose -Message ('Downloading the language pack for "{0}".' -f $targetLanguageTagLong)
    $langPackFilePath = Join-Path -Path $env:TEMP -ChildPath 'Microsoft-Windows-Server-Language-Pack_x64_ja-jp.cab'
    Get-JapaneseLangPackCabFile -DestinationFilePath $langPackFilePath
    Write-Verbose -Message ('The language pack for "{0}" has been downloaded.' -f $targetLanguageTagLong)

    # Install the language pack.
    Write-Verbose -Message ('Installing the language pack for "{0}".' -f $targetLanguageTagLong)
    Add-WindowsPackage -Online -NoRestart -PackagePath $langPackFilePath -Verbose:$false
    Write-Verbose -Message ('The language pack for "{0}" has been installed.' -f $targetLanguageTagLong)

    # Delete the lang pack CAB file.
    Remove-Item -LiteralPath $langPackFilePath -Force
    Write-Verbose -Message 'The temporary files for the language pack are deleted.'
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
    $langPackIsoUri = 'https://software-download.microsoft.com/download/pr/17763.1.180914-1434.rs5_release_SERVERLANGPACKDVD_OEM_MULTI.iso'  # WS2019
    $request = [System.Net.HttpWebRequest]::Create($langPackIsoUri)
    $request.Method = 'GET'

    # Set the Japanese language pack CAB file data range.
    $offsetToJpLangCabFileInIsoFile = 1003644928
    $jpLangCabFileSize = 62015873
    $request.AddRange('bytes', $offsetToJpLangCabFileInIsoFile, $offsetToJpLangCabFileInIsoFile + $jpLangCabFileSize - 1)

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
    $jpLangCabFileHash = 'B562ECD51AFD32DB6E07CB9089691168C354A646'
    $fileHash = Get-FileHash -Algorithm SHA1 -LiteralPath $DestinationFilePath
    if ($fileHash.Hash -ne $jpLangCabFileHash) {
        throw ('The file hash of the language pack CAB file "{0}" is not match to expected value. The download was may failed.') -f $DestinationFilePath
    }
}

function Test-LanguagePack
{
    [CmdletBinding()]
    [OutputType([bool])]
    param ()

    $langPackPackageName = 'Microsoft-Windows-Server-LanguagePack-Package~31bf3856ad364e35~amd64~ja-JP~10.0.17763.1'
    $package = Get-WindowsPackage -Online -Verbose:$false | Where-Object -Property 'PackageName' -EQ -Value $langPackPackageName
    $result = $package -ne $null
    $stateText = if ($result) { 'installed' } else { 'not installed' }
    Write-Verbose -Message ('The language pack for "{0}" is {1}.' -f $targetLanguageTagLong, $stateText)
    $result
}

$languageCapabilityNames = @(
    'Language.Basic~~~ja-JP~0.0.1.0',
    'Language.Fonts.Jpan~~~und-JPAN~0.0.1.0'#,
    #'Language.Handwriting~~~ja-JP~0.0.1.0',
    #'Language.OCR~~~ja-JP~0.0.1.0',
    #'Language.Speech~~~ja-JP~0.0.1.0',
    #'Language.TextToSpeech~~~ja-JP~0.0.1.0'
)

function Install-LanguageCapability
{
    [CmdletBinding()]
    param ()

    $languageCapabilityNames | ForEach-Object -Process {
        if (-not (Test-WindowsCapabilityInstallationState -WindowsCapabilityName $_))
        {
            Write-Verbose -Message ('Installing the "{0}" capability.' -f $_)
            Add-WindowsCapability -Online -Name $_ -Verbose:$false
            Write-Verbose -Message ('The capability "{0}" has been installed.' -f $_)
        }
    }
}

function Test-LanguageCapability
{
    [CmdletBinding()]
    [OutputType([bool])]
    param ()

    $result = $true

    $languageCapabilityNames | ForEach-Object -Process {
        $subResult = Test-WindowsCapabilityInstallationState -WindowsCapabilityName $_
        if (-not $subResult) { $result = $false }
        $stateText = if ($subResult) { 'installed' } else { 'not installed' }
        Write-Verbose -Message ('The "{0}" capability is {1}.' -f $_, $stateText)
    }

    $result
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

# function Test-PreferredLanguage
# {
#     [CmdletBinding()]
#     [OutputType([bool])]
#     param ()

#     $langList = Get-WinUserLanguageList
#     $currentLanguage = $langList[0].LanguageTag
#     $result = $currentLanguage -eq $targetLanguageTag
#     if ($result)
#     {
#         Write-Verbose -Message ('The preferred language is already set to "{0}".' -f $currentLanguage)
#     }
#     else
#     {
#         Write-Verbose -Message ('The preferred language is "{0}" but should be "{1}". Change required.' -f $currentLanguage, $targetLanguageTag)
#     }
#     $result
# }

# function Set-PreferredLanguage
# {
#     [CmdletBinding()]
#     param ()

#     $langList = Get-WinUserLanguageList
#     #$jaItems = $langList | Where-Object -Property 'LanguageTag' -EQ -Value $language
#     #$jaItems | ForEach-Object -Process { $langList.Remove($_) }
#     $langList.Insert(0, $language)
#     Set-WinUserLanguageList -LanguageList $langList -Force
#     Write-Verbose -Message ('The preferred language for the current user updated to "{0}"' -f $language)
# }

# function Test-CultureInfo
# {
#     [CmdletBinding()]
#     [OutputType([bool])]
#     param ()

#     Write-Verbose -Message 'Testing the culture.'

#     $currentCultureLanguage = (Get-Culture).IetfLanguageTag
#     $result = $currentCultureLanguage -eq $languageLong
#     if ($result)
#     {
#         Write-Verbose -Message ('The culture is already set to "{0}".' -f $currentCultureLanguage)
#     }
#     else
#     {
#         Write-Verbose -Message ('The culture is "{0}" but should be "{1}". Change required.' -f $currentCultureLanguage, $languageLong)
#     }
#     $result
# }

# function Set-CultureInfo
# {
#     [CmdletBinding()]
#     [OutputType([bool])]
#     param ()

#     Set-Culture -CultureInfo $languageLong
#     Write-Verbose -Message ('The culture for the current user updated to "{0}"' -f $languageLong)
# }

function Test-UILanguage
{
    [CmdletBinding()]
    [OutputType([bool])]
    param ()

    $uiLanguageOverride = Get-WinUILanguageOverride
    $currentUILanguage = if ($uiLanguageOverride -eq $null) { 'n/a' } else { $uiLanguageOverride.IetfLanguageTag }

    $result = $currentUILanguage -eq $targetLanguageTag
    if ($result)
    {
        Write-Verbose -Message ('The UI language is already set to "{0}".' -f $currentUILanguage)
    }
    else
    {
        Write-Verbose -Message ('The UI language is "{0}" but should be "{1}". Change required.' -f $currentUILanguage, $targetLanguageTag)
    }

    $result
}

function Set-UILanguage
{
    [CmdletBinding()]
    param ()

    Set-WinUILanguageOverride -Language $targetLanguageTag
    Write-Verbose -Message ('The UI language for the current user updated to "{0}"' -f $targetLanguageTag)
}

function Test-InputMethodLanguage
{
    [CmdletBinding()]
    [OutputType([bool])]
    param ()

    $inputMethodOverride = Get-WinDefaultInputMethodOverride
    $currentInputMethodTip = if ($inputMethodOverride -eq $null) { 'n/a' } else { $inputMethodOverride.InputMethodTip }

    $result = $currentInputMethodTip -eq $targetLanguageInputMethodTip
    if ($result)
    {
        Write-Verbose -Message ('The input method language is already set to "{0}".' -f $targetLanguageTag)
    }
    else
    {
        Write-Verbose -Message ('The input method language is "{0}" but should be "{1}". Change required.' -f $currentInputMethodTip, $targetLanguageTag)
    }

    $result
}

function Set-InputMethodLanguage
{
    [CmdletBinding()]
    param ()

    $langList = Get-WinUserLanguageList
    $langList.Insert(0, $targetLanguageTag)
    Set-WinUserLanguageList -LanguageList $langList -Force
    Write-Verbose -Message ('The preferred language for the current user updated to "{0}"' -f $targetLanguageTag)

    Set-WinDefaultInputMethodOverride -InputTip $targetLanguageInputMethodTip
    Write-Verbose -Message ('The input method language for the current user updated to "{0}"' -f $targetLanguageTag)
}

function Test-SystemAccountCopyState
{
    [CmdletBinding()]
    [OutputType([bool])]
    param ()

    $result = Test-AccountCopyState -AccountSid 'S-1-5-18'
    if ($result)
    {
        Write-Verbose -Message 'The system account''s language setting has been copied.'
    }
    else
    {
        Write-Verbose -Message 'The system account''s language setting has not yet copied. Copy required.'
    }
    $result
}

function Test-DefaultAccountCopyState
{
    [CmdletBinding()]
    [OutputType([bool])]
    param ()

    $result = Test-AccountCopyState -AccountSid '.DEFAULT'
    if ($result)
    {
        Write-Verbose -Message 'The default account''s language setting has been copied.'
    }
    else
    {
        Write-Verbose -Message 'The default account''s language setting has not yet copied. Copy required.'
    }
    $result
}

function Test-AccountCopyState
{
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true)]
        [string] $AccountSid
    )

    $result = $true

    $localeName = (Get-Item -LiteralPath ('Registry::HKEY_USERS\{0}\Control Panel\International' -f $AccountSid)).GetValue('LocaleName')
    $result = ($localeName -eq $targetLanguageTagLong) -and $result

    $preferredUILanguages = (Get-Item -LiteralPath ('Registry::HKEY_USERS\{0}\Control Panel\Desktop' -f $AccountSid)).GetValue('PreferredUILanguages')
    if ($preferredUILanguages -eq $null)
    {
        $result = $false
    }
    else
    {
        if ($preferredUILanguages.Length -eq 0)
        {
            $result = $false
        }
        else
        {
            $result = ($preferredUILanguages[0] -eq $targetLanguageTagLong) -and $result
        }
    }

    $result
}

Export-ModuleMember -Function @(
    'Test-Language',
    'Set-Language'
)
