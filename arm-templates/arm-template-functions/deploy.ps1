[CmdletBinding()]
param (
    [string] $ResourceGroupName = 'armtest',
    [string] $ResourceGroupLocation = 'japaneast',
    [string] $TemplateFile,
    #[string] $TemplateParametersFile = './parameters.json',
    [HashTable] $ResourceGroupTag = @{ 'usage' = 'experimental' }
)

$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
Set-StrictMode -Version 3

$templateFilePath = [IO.Path]::GetFullPath([IO.Path]::Combine($PSScriptRoot, $TemplateFile))
#$templateParametersFilePath = [IO.Path]::GetFullPath([IO.Path]::Combine($PSScriptRoot, $TemplateParametersFile))

Get-AzContext

New-AzResourceGroup -Name $ResourceGroupName -Location $ResourceGroupLocation -Tag $ResourceGroupTag -Verbose -Force

$params = @{
    ResourceGroupName       = $ResourceGroupName
    Name                    = 'arm-template-function-test-{0}'-f (Get-Date).ToUniversalTime().ToString('yyyyMMdd-HHmmss')
    TemplateFile            = $templateFilePath
    DeploymentDebugLogLevel = 'All'
    #WhatIf                  = $true
    Force                   = $true
    Verbose                 = $true
}
New-AzResourceGroupDeployment @params
