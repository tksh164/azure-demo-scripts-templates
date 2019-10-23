#Requires -Version 3.0
#Requires -Module Az.Accounts
#Requires -Module Az.Resources

Param(
    [string] $ResourceGroupName = 'Demo-VMSS-RG',
    [string] $ResourceGroupLocation = 'Japan East',
    [string] $TemplateFile = 'template.json',
    [string] $TemplateParametersFile = 'parameters.json',
    [switch] $ValidateOnly
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3

function Format-ValidationOutput {
    param ($ValidationOutput, [int] $Depth = 0)
    Set-StrictMode -Off
    return @($ValidationOutput | Where-Object { $_ -ne $null } | ForEach-Object { @('  ' * $Depth + ': ' + $_.Message) + @(Format-ValidationOutput @($_.Details) ($Depth + 1)) })
}

Get-AzContext

$OptionalParameters = New-Object -TypeName Hashtable
$TemplateFile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $TemplateFile))
$TemplateParametersFile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $TemplateParametersFile))


# Create or update the resource group using the specified template file and template parameters file
New-AzResourceGroup -Name $ResourceGroupName -Location $ResourceGroupLocation -Tag @{ 'Usage' = 'Demo' } -Verbose -Force

if ($ValidateOnly) {
    $ErrorMessages = Format-ValidationOutput (Test-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName `
                                                                             -TemplateFile $TemplateFile `
                                                                             -TemplateParameterFile $TemplateParametersFile `
                                                                             @OptionalParameters)
    if ($ErrorMessages) {
        Write-Output '', 'Validation returned the following errors:', @($ErrorMessages), '', 'Template is invalid.'
    }
    else {
        Write-Output '', 'Template is valid.'
    }
}
else {
    New-AzResourceGroupDeployment -Name ((Get-ChildItem $TemplateFile).BaseName + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm')) `
                                  -ResourceGroupName $ResourceGroupName `
                                  -TemplateFile $TemplateFile `
                                  -TemplateParameterFile $TemplateParametersFile `
                                  @OptionalParameters `
                                  -Force -Verbose `
                                  -ErrorVariable ErrorMessages
    if ($ErrorMessages) {
        Write-Output '', 'Template deployment returned the following errors:', @(@($ErrorMessages) | ForEach-Object { $_.Exception.Message.TrimEnd("`r`n") })
    }
}
