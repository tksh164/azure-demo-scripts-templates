#Requires -RunAsAdministrator

param (
    [Parameter(Mandatory = $true, Position = 0)]
    [string] $LangConfigFileName
)

$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
$VerbosePreference = [System.Management.Automation.ActionPreference]::Continue
Start-Transcript -OutputDirectory $PSScriptRoot

Import-LocalizedData -BindingVariable 'LangConfig' -BaseDirectory $PSScriptRoot -FileName ([System.IO.Path]::GetFileName($LangConfigFileName))

function Install-LanguagePack
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Language
    )

    # Get the anguage pack CAB file name.
    $langPackFilePath = Join-Path -Path $env:TEMP -ChildPath $LangConfig.LanguagePack.CabFileName

    # Download the lanchage pack.
    Write-Verbose -Message ('Downloading the language pack for "{0}".' -f $Language)

    $params = @{
        IsoFileUri               = $LangConfig.LanguagePack.IsoFileUri
        OffsetToCabFileInIsoFile = $LangConfig.LanguagePack.OffsetToCabFileInIsoFile
        CabFileSize              = $LangConfig.LanguagePack.CabFileSize
        CabFileHash              = $LangConfig.LanguagePack.CabFileHash
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
        [ValidateNotNullOrEmpty()]
        [string] $IsoFileUri,

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

    $request = [System.Net.HttpWebRequest]::Create($IsoFileUri)
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

Set-TimeZone -Id $LangConfig.TimeZoneId
Install-LanguagePack -Language $LangConfig.PreferredLanguage
Install-LanguageCapability -LanguageCapabilityNames ($LangConfig.CapabilityNames.Minimum + $LangConfig.CapabilityNames.Additional)

Write-Warning -Message 'This system will be reboots after in 5 seconds.'

Stop-Transcript

Start-Sleep -Seconds 5
Restart-Computer
