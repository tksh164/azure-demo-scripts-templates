function Test-WindowsVersion
{
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Version
    )

    $currentSystemVersion = (Get-CimInstance -ClassName 'Win32_OperatingSystem' -Verbose:$false).Version
    Write-Verbose -Message ('Current system''s Windows version is "{0}".' -f $currentSystemVersion)
    $currentSystemVersion -eq $Version
}

# $phaseOneCompletionFlagFilePath = Join-Path -Path $env:TEMP -ChildPath 'DSC_Language-PhaseOneCompleted'

# function Set-PhaseOneCompletionFlag
# {
#     [CmdletBinding()]
#     param ()

#     Write-Verbose -Message 'Setting the phase one completion flag.'
#     Set-Content -LiteralPath $PhaseOneCompletionFlagFilePath -Value '' -Force
# }

# function Clear-PhaseOneCompletionFlag
# {
#     [CmdletBinding()]
#     param ()

#     Write-Verbose -Message 'Clearing the phase one completion flag.'
#     Remove-Item -LiteralPath $PhaseOneCompletionFlagFilePath -Force
# }

# function Test-PhaseOneCompletionFlag
# {
#     [CmdletBinding()]
#     [OutputType([bool])]
#     param ()

#     $result = [System.IO.File]::Exists($PhaseOneCompletionFlagFilePath)
#     $flagState = if ($result) { 'set' } else { 'not set' }
#     Write-Verbose -Message ('The phase one completion flag is {0} in currently.' -f $flagState)
#     $result
# }

function Copy-LanguageSttingsToSpecialAccount
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [bool] $CopyToSystemAccount = $false,

        [Parameter(Mandatory = $false)]
        [bool] $CopyToDefaultAccount = $false
    )

    if (-not ($CopyToDefaultAccount -or $CopyToSystemAccount))
    {
        Write-Verbose -Message 'Skip the copy of the language settings because any switch not specified.'
        return
    }

    $targetAccountText = if ($CopyToDefaultAccount -and $CopyToSystemAccount) { 'the default account and system account' } elseif ($CopyToDefaultAccount) { 'the default account' } elseif ($CopyToSystemAccount) { 'the system account' }
    Write-Verbose -Message ('Copying the current user language settings to {0}.' -f $targetAccountText)

    # Reference:
    # How to Automate Regional and Language settings in Windows Vista, Windows Server 2008, Windows 7 and in Windows Server 2008 R2
    # https://docs.microsoft.com/en-us/troubleshoot/windows-client/deployment/automate-regional-language-settings
    $xmlFileContentTemplate = @'
<gs:GlobalizationServices xmlns:gs="urn:longhornGlobalizationUnattend">
    <gs:UserList>
        <gs:User UserID="Current" CopySettingsToSystemAcct="{0}" CopySettingsToDefaultUserAcct="{1}"/> 
    </gs:UserList>
</gs:GlobalizationServices>
'@

    # Create a new XML file and set the content.
    $xmlFileFilePath = Join-Path -Path $env:TEMP -ChildPath ((New-Guid).Guid + '.xml')
    $xmlFileContent = ($xmlFileContentTemplate -f $CopyToSystemAccount.ToString().ToLowerInvariant(), $CopyToDefaultAccount.ToString().ToLowerInvariant())
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

Export-ModuleMember -Function @(
    'Test-WindowsVersion',
    # 'Set-PhaseOneCompletionFlag',
    # 'Clear-PhaseOneCompletionFlag',
    # 'Test-PhaseOneCompletionFlag',
    'Copy-LanguageSttingsToSpecialAccount'
)
