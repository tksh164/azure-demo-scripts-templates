$language = 'ja'
$languageCapabilityNames = @(
    'Language.Basic~~~ja-JP~0.0.1.0',
    'Language.Fonts.Jpan~~~und-JPAN~0.0.1.0',
    'Language.Handwriting~~~ja-JP~0.0.1.0',
    'Language.OCR~~~ja-JP~0.0.1.0',
    'Language.Speech~~~ja-JP~0.0.1.0',
    'Language.TextToSpeech~~~ja-JP~0.0.1.0'
)

function Install-LanguagePack
{
    [CmdletBinding()]
    param ()

    # Download the lang pack CAB file.
    Write-Verbose -Message ('Downloading the language pack for "{0}".' -f $language)
    $langPackFilePath = Join-Path -Path $env:TEMP -ChildPath 'Microsoft-Windows-Server-Language-Pack_x64_ja-jp.cab'
    Get-JapaneseLangPackCabFile -DestinationFilePath $langPackFilePath

    # Install the language pack.
    Write-Verbose -Message ('Installing the language pack for "{0}".' -f $language)
    Add-WindowsPackage -Online -NoRestart -PackagePath $langPackFilePath -Verbose:$false

    # Delete the lang pack CAB file.
    Write-Verbose -Message 'Deleting a temporary file for the language pack.'
    Remove-Item -LiteralPath $langPackFilePath -Force
}

function Test-LanguagePack
{
    [CmdletBinding()]
    [OutputType([bool])]
    param ()

    $result = $true

    if (Test-LanguagePackInstallationState)
    {
        Write-Verbose -Message ('The language pack for "{0}" is already installed.' -f $language)
    }
    else
    {
        Write-Verbose -Message ('The language pack for "{0}" is not installed.' -f $language)
        $result = $false
    }

    $result
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
        throw ('The "{0}" is corrupted. The download was may failed.') -f $DestinationFilePath
    }
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

function Install-LanguageCapability
{
    [CmdletBinding()]
    param ()

    $languageCapabilityNames | ForEach-Object -Process {
        if (-not (Test-WindowsCapabilityInstallationState -WindowsCapabilityName $_))
        {
            Write-Verbose -Message ('Installing capability "{0}".' -f $_)
            Add-WindowsCapability -Online -Name $_ -Verbose:$false
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
        if (Test-WindowsCapabilityInstallationState -WindowsCapabilityName $_)
        {
            Write-Verbose -Message ('Capability "{0}" is already installed.' -f $_)
        }
        else
        {
            Write-Verbose -Message ('Capability "{0}" is not installed.' -f $_)
            $result = $false
        }
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

    Write-Verbose -Message ('Setting the preferred language to "{0}"' -f $language)

    $langList = Get-WinUserLanguageList
    $jaItems = $langList | Where-Object -Property 'LanguageTag' -EQ -Value $language
    $jaItems | ForEach-Object -Process { $langList.Remove($_) }
    $langList.Insert(0, $language)
    Set-WinUserLanguageList -LanguageList $langList -Force
}

function Test-PreferredLanguage
{
    [CmdletBinding()]
    [OutputType([bool])]
    param ()

    $result = $true

    $langList = Get-WinUserLanguageList
    if ($langList[0].LanguageTag -eq $language)
    {
        Write-Verbose -Message ('The preferred language is already set to "{0}"' -f $language)
    }
    else
    {
        Write-Verbose -Message ('The preferred language is not set to "{0}"' -f $language)
        $result = $false
    }

    $result
}

function Set-UILanguage
{
    [CmdletBinding()]
    param ()

    Write-Verbose -Message ('Setting the Windows UI language to "{0}"' -f $language)
    Set-WinUILanguageOverride -Language ja-JP
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
