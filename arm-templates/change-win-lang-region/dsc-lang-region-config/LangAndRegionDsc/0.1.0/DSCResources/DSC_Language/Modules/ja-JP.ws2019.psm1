$language = 'ja'

function Install-LanguagePack
{
    [CmdletBinding()]
    param ()

    # Download the lang pack CAB file.
    Write-Verbose -Message ('Downloading the language pack for "{0}".' -f $language)
    $langPackFilePath = Join-Path -Path $env:TEMP -ChildPath 'Microsoft-Windows-Server-Language-Pack_x64_ja-jp.cab'
    Get-JapaneseLangPackCabFile -DestinationFilePath $langPackFilePath
    Write-Verbose -Message ('The download of the language pack for "{0}" is completed.' -f $language)

    # Install the language pack.
    Write-Verbose -Message ('Installing the language pack for "{0}".' -f $language)
    Add-WindowsPackage -Online -NoRestart -PackagePath $langPackFilePath -Verbose:$false
    Write-Verbose -Message ('The installation of the language pack for "{0}" is completed.' -f $language)

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
    Write-Verbose -Message ('The language pack for "{0}" is {1}.' -f $language, $stateText)
    $result
}

$languageCapabilityNames = @(
    'Language.Basic~~~ja-JP~0.0.1.0',
    'Language.Fonts.Jpan~~~und-JPAN~0.0.1.0',
    'Language.Handwriting~~~ja-JP~0.0.1.0',
    'Language.OCR~~~ja-JP~0.0.1.0',
    'Language.Speech~~~ja-JP~0.0.1.0',
    'Language.TextToSpeech~~~ja-JP~0.0.1.0'
)

function Install-LanguageCapability
{
    [CmdletBinding()]
    param ()

    $languageCapabilityNames | ForEach-Object -Process {
        if (-not (Test-WindowsCapabilityInstallationState -WindowsCapabilityName $_))
        {
            Write-Verbose -Message ('Installing the capability "{0}".' -f $_)
            Add-WindowsCapability -Online -Name $_ -Verbose:$false
            Write-Verbose -Message ('The installation of the capability "{0}" is completed.' -f $_)
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
        Write-Verbose -Message ('The capability "{0}" is {1}.' -f $_, $stateText)
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

function Set-PreferredLanguage
{
    [CmdletBinding()]
    param ()

    $langList = Get-WinUserLanguageList
    $jaItems = $langList | Where-Object -Property 'LanguageTag' -EQ -Value $language
    $jaItems | ForEach-Object -Process { $langList.Remove($_) }
    $langList.Insert(0, $language)
    Set-WinUserLanguageList -LanguageList $langList -Force
    Write-Verbose -Message ('The preferred language for the current user updated to "{0}"' -f $language)
}

function Test-PreferredLanguage
{
    [CmdletBinding()]
    [OutputType([bool])]
    param ()

    $langList = Get-WinUserLanguageList
    $currentLanguage = $langList[0].LanguageTag
    $result = $currentLanguage -eq $language
    Write-Verbose -Message ('The preferred language is "{0}" but should be "{1}". Change required.' -f $currentLanguage, $language)
    $result
}

function Set-UILanguage
{
    [CmdletBinding()]
    param ()

    Set-WinUILanguageOverride -Language ja-JP
    Write-Verbose -Message ('The Windows UI language for the current user updated to "{0}"' -f $language)
}

Export-ModuleMember -Function @(
    'Install-LanguagePack',
    'Test-LanguagePack'
    'Install-LanguageCapability',
    'Test-LanguageCapability',
    'Set-PreferredLanguage',
    'Test-PreferredLanguage',
    'Set-UILanguage'
)
