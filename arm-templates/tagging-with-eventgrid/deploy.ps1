[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string] $EventGridSystemTopicResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string] $EventGridSystemTopicName,

    [Parameter(Mandatory = $false)]
    [string] $FuncAppResourceGroupName = 'resource-tagging-app',

    [Parameter(Mandatory = $false)]
    [string] $FuncAppResourceGroupLocation = 'japaneast'
)

$VerbosePreference = [System.Management.Automation.ActionPreference]::Continue
$WarningPreference = [System.Management.Automation.ActionPreference]::Continue
$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop

$funcApp = [PSCustomObject] @{
    ResourceGroupName     = $FuncAppResourceGroupName
    ResourceGroupLocation = $FuncAppResourceGroupLocation
}

$eventGridSystemTopic = [PSCustomObject] @{
    ResourceGroupName = $EventGridSystemTopicResourceGroupName
    Name              = $EventGridSystemTopicName
}

Get-AzContext | Format-List

# Deploy a Function App.

$params = @{
    ResourceGroupName = $funcApp.ResourceGroupName
    Location          = $funcApp.ResourceGroupLocation
    Force             = $true
    Verbose           = $true
}
New-AzResourceGroup @params

$params = @{
    ResourceGroupName = $funcApp.ResourceGroupName
    Name              = 'funcapp-{0}' -f ((Get-Date).ToUniversalTime().ToString('yyyyMMdd-HHmmss'))
    TemplateFile      = Join-Path -Path $PSScriptRoot -ChildPath 'templates' -AdditionalChildPath 'function-app', 'template.json'
    Force             = $true
    Verbose           = $true
}
$result = New-AzResourceGroupDeployment @params

$funcAppName = $result.Outputs.functionAppName.Value
$funcAppResourceId = $result.Outputs.functionAppResourceId.Value
$systemAssignedIdentityObjectId = $result.Outputs.SystemAssignedIdentityObjectId.Value

# TODO: Scope

try
{
    New-AzRoleAssignment -ObjectId $systemAssignedIdentityObjectId -RoleDefinitionName 'Reader'  -Verbose -ErrorAction Stop
}
catch
{
    Write-Warning -Message ('Failed to role assignment wih the "Reader" role. You need assign this role to the system assigned identity {0} manually later.' -f $systemAssignedIdentityObjectId)
}

try
{
    New-AzRoleAssignment -ObjectId $systemAssignedIdentityObjectId -RoleDefinitionName 'Tag Contributor' -Verbose -ErrorAction Stop
}
catch
{
    Write-Warning -Message ('Failed to role assignment wih the "Tag Contributor" role. You need assign this role to the system assigned identity {0} manually later.' -f $systemAssignedIdentityObjectId)
}

# Deopy a function into the Function App.

$funcAppSrcDirPath = Join-Path -Path $PSScriptRoot -ChildPath 'functionapp'
$funcAppZipFilePath = Join-Path -Path $PSScriptRoot -ChildPath 'functionapp.zip'

Push-Location
Set-Location -LiteralPath $funcAppSrcDirPath
Compress-Archive -Path '*' -DestinationPath $funcAppZipFilePath -Force -Verbose
Pop-Location

$params = @{
    ResourceGroupName = $funcApp.ResourceGroupName
    Name              = $funcAppName
    ArchivePath       = $funcAppZipFilePath
    Force             = $true
    Verbose           = $true
}
Publish-AzWebApp @params

# Deploy an Event Subscription.

$params = @{
    ResourceGroupName       = $eventGridSystemTopic.ResourceGroupName
    Name                    = 'event-subscription-{0}' -f ((Get-Date).ToUniversalTime().ToString('yyyyMMdd-HHmmss'))
    TemplateFile            = Join-Path -Path $PSScriptRoot -ChildPath 'templates' -AdditionalChildPath 'event-subscription', 'template.json'
    TemplateParameterObject = @{
        'eventGridSystemTopicName' = $eventGridSystemTopic.Name
        'functionAppResourceId'    = $funcAppResourceId
    }
    Force                   = $true
    Verbose                 = $true
}
New-AzResourceGroupDeployment @params
