[CmdletBinding()]
param (
    [string] $ResourceGroupName = 'exptl-langregion',
    [string] $ResourceGroupLocation = 'japaneast',
    [string] $TemplateFile = './template.json',
    [string] $TemplateParametersFile = './parameters.json',
    [HashTable] $ResourceGroupTag = @{ 'usage' = 'experimental' },
    [switch] $WhatIf,
    [switch] $ValidateOnly
)

$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
Set-StrictMode -Version 3

$TemplateFilePath = [IO.Path]::GetFullPath([IO.Path]::Combine($PSScriptRoot, $TemplateFile))
$TemplateParametersFilePath = [IO.Path]::GetFullPath([IO.Path]::Combine($PSScriptRoot, $TemplateParametersFile))

Get-AzContext

New-AzResourceGroup -Name $ResourceGroupName -Location $ResourceGroupLocation -Tag $ResourceGroupTag -Verbose -Force

if ($ValidateOnly)
{
    $params = @{
        ResourceGroupName = $ResourceGroupName
        TemplateFile      = $TemplateFilePath
    }

    if (Test-Path -LiteralPath $TemplateParametersFilePath -PathType Leaf)
    {
        $params.TemplateParameterFile = $TemplateParametersFilePath
    }

    $result = Test-AzResourceGroupDeployment @params
    if ($result.Count -eq 0)
    {
        Write-Output -InputObject '', 'Template is valid.'
    }
    else
    {
        $result    
    }
}
else
{
    $params = @{
        ResourceGroupName = $ResourceGroupName
        TemplateFile      = $TemplateFilePath
        WhatIf            = $WhatIf
    }

    if (Test-Path -LiteralPath $TemplateParametersFilePath -PathType Leaf)
    {
        $params.TemplateParameterFile = $TemplateParametersFilePath
    }

    if (-not $WhatIf)
    {
        $params.Name    = ('{0}-{1}'-f (Get-Item -LiteralPath $TemplateFilePath).BaseName, (Get-Date).ToUniversalTime().ToString('MMdd-HHmm'))
        $params.Force   = $true
        $params.Verbose = $true
    }

    New-AzResourceGroupDeployment @params
}
