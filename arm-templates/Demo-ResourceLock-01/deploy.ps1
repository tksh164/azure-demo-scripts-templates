param (
    [string] $ResourceGroupName = 'Demo-ResourceLock-RG',
    [string] $ResourceGroupLocation = 'Japan East',
    [string] $TemplateFile = 'template.json',
    [string] $TemplateParametersFile = 'parameters.json',
    [switch] $ValidateOnly
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3

function Format-ValidationOutput
{
    param (
        $ValidationOutput,
        [int] $Depth = 0
    )

    Set-StrictMode -Off
    return @($ValidationOutput |
        Where-Object { $_ -ne $null } |
        ForEach-Object { @('  ' * $Depth + ': ' + $_.Message) + @(Format-ValidationOutput @($_.Details) ($Depth + 1)) })
}

Get-AzContext

$OptionalParameters = New-Object -TypeName Hashtable
$TemplateFile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $TemplateFile))
$TemplateParametersFile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $TemplateParametersFile))

New-AzResourceGroup -Name $ResourceGroupName -Location $ResourceGroupLocation -Tag @{ 'Usage' = 'Demo' } -Verbose -Force

if ($ValidateOnly)
{
    $params = @{
        ResourceGroupName     = $ResourceGroupName
        TemplateFile          = $TemplateFile
        TemplateParameterFile = $TemplateParametersFile
    }
    $errorMessages = Format-ValidationOutput (Test-AzResourceGroupDeployment @params @OptionalParameters)

    if ($errorMessages)
    {
        Write-Output '', 'Validation returned the following errors:', @($errorMessages), '', 'Template is invalid.'
    }
    else
    {
        Write-Output '', 'Template is valid.'
    }
}
else
{
    $params = @{
        Name                  = ('{0}-{1}'-f (Get-ChildItem -LiteralPath $TemplateFile).BaseName, (Get-Date).ToUniversalTime().ToString('MMdd-HHmm'))
        ResourceGroupName     = $ResourceGroupName
        TemplateFile          = $TemplateFile
        TemplateParameterFile = $TemplateParametersFile
        Force                 = $true
        Verbose               = $true
        ErrorVariable         = 'errorMessages'
    }
    New-AzResourceGroupDeployment @params @OptionalParameters

    if ($errorMessages)
    {
        Write-Output '', 'Template deployment returned the following errors:', @(@($errorMessages) | ForEach-Object { $_.Exception.Message.TrimEnd("`r`n") })
    }
}
