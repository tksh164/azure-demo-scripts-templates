#Requires -RunAsAdministrator

param (
    [Parameter(Mandatory = $true, Position = 0)]
    [string] $LangConfigFileName
)

$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
$VerbosePreference = [System.Management.Automation.ActionPreference]::Continue
Start-Transcript -OutputDirectory $PSScriptRoot

Import-LocalizedData -BindingVariable 'LangConfig' -BaseDirectory $PSScriptRoot -FileName ([System.IO.Path]::GetFileName($LangConfigFileName))

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

$params = @{
    PreferredLanguage                = $LangConfig.PreferredLanguage
    InputLanguageID                  = $LangConfig.InputLanguageID
    CopySettingsToDefaultUserAccount = $true
    LocationGeoId                    = $LangConfig.LocationGeoId
    SystemLocale                     = $LangConfig.SystemLocale
}
Set-LanguageOptions @params

Write-Warning -Message 'This system will be reboots after in 5 seconds.'

Stop-Transcript

Start-Sleep -Seconds 5
Restart-Computer
