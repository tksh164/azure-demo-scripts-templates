#Requires -Version 5.0
#Requires -Modules AzureRM.Profile, AzureRM.Resources, AzureRM.Compute, AzureRM.Storage

[CmdletBinding()]
param (
    [string] $ResourceGroupName = 'Demo-SingleVM-DscExtension-RG',
    [string] $ResourceGroupLocation = 'Japan East',

    [string] $TemplateFilePath = '.\template.json',
    [string] $TemplateParametersFilePath = '.\template.parameters.json',

    [switch] $UploadArtifact,
    [string] $ArtifactStagingStorageAccountName,
    [string] $ArtifactStagingContainerName,
    [string] $ArtifactStagingDirectory = '.',
    [string] $DscSourceFolder = '.\DSC',

    [switch] $ValidateOnly
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3

# The constant values for the optional parameter hash table.
#$Key_ArtifactsLocation = '_artifactsLocation'
#$Key_ArtifactsLocationSasToken = '_artifactsLocationSasToken'
Set-Variable -Name 'Key_ArtifactsLocation' -Value '_artifactsLocation' -Option Constant
Set-Variable -Name 'Key_ArtifactsLocationSasToken' -Value '_artifactsLocationSasToken' -Option Constant

function Format-ValidationOutput
{
    param (
        $ValidationOutput,
        [int] $Depth = 0
    )

    Set-StrictMode -Off

    return @($ValidationOutput |
        Where-Object { $_ -ne $null } |
        ForEach-Object {
            @('  ' * $Depth + ': ' + $_.Message) + @(Format-ValidationOutput @($_.Details) ($Depth + 1))
        })
}

function GetArtifactsLocationInfo
{
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string] $TemplateParametersFilePath
    )

    $json = Get-Content -LiteralPath $TemplateParametersFilePath -Raw | ConvertFrom-Json
    if (($json | Get-Member -Type NoteProperty 'parameters') -ne $null) {
        $jsonParameters = $json.parameters
    }

    $artifactsLocation = $jsonParameters |
        Select-Object -Expand $Key_ArtifactsLocation -ErrorAction Ignore |
        Select-Object -Expand 'value' -ErrorAction Ignore
    $sasToken = $jsonParameters |
        Select-Object -Expand $Key_ArtifactsLocationSasToken -ErrorAction Ignore |
        Select-Object -Expand 'value' -ErrorAction Ignore

    return [PSCustomObject] @{
        ArtifactsLocation = $artifactsLocation
        SasToken          = $sasToken
    }
}

function UploadArtifactFile
{
    [OutputType([void])]
    param (
        [Parameter(Mandatory = $true)]
        [string] $ArtifactStagingDirectoryPath,

        [Parameter(Mandatory = $true)]
        [Microsoft.WindowsAzure.Commands.Common.Storage.LazyAzureStorageContext] $StorageContext,

        [Parameter(Mandatory = $true)]
        [string] $ContainerName
    )

    if (Test-Path -LiteralPath $ArtifactStagingDirectoryPath)
    {
        Get-ChildItem -LiteralPath $ArtifactStagingDirectoryPath -Recurse -File |
            ForEach-Object -Process {

                $sourcePath = $_.FullName
                $blobName = $sourcePath.Substring($ArtifactStagingDirectory.Length + 1)

                $params = @{
                    File      = $sourcePath
                    Blob      = $blobName
                    Container = $ContainerName
                    Context   = $StorageContext
                    Force     = $true
                }
                Set-AzureStorageBlobContent @params
            }
    }
}

function CreateDscConfigurationArchiveFile
{
    [OutputType([void])]
    param (
        [Parameter(Mandatory = $true)]
        [string] $DscSourceFolderPath
    )

    if (Test-Path -LiteralPath $DscSourceFolderPath)
    {
        Get-ChildItem -LiteralPath $DscSourceFolderPath -File -Filter '*.ps1' |
            ForEach-Object -Process {

                $dscSourceFilePath = $_.FullName

                $dscArchiveFileDir = [System.IO.Path]::GetDirectoryName($dscSourceFilePath)
                $dscArchiveFileName = [System.IO.Path]::GetFileNameWithoutExtension($dscSourceFilePath) + '.zip'
                $dscArchiveFilePath = Join-Path -Path $dscArchiveFileDir -ChildPath $dscArchiveFileName

                $params = @{
                    ConfigurationPath = $dscSourceFilePath
                    OutputArchivePath = $dscArchiveFilePath
                    Force             = $true
                    Verbose           = $true
                }
                Publish-AzureRmVMDscConfiguration @params
            }
    }
}

function CreateStagingStorageAccountIfNotExist
{
    [OutputType([Microsoft.Azure.Commands.Management.Storage.Models.PSStorageAccount])]
    param (
        [Parameter(Mandatory = $true)]
        [string] $StorageAccountName,

        [Parameter(Mandatory = $true)]
        [string] $StorageAccountLocation,

        [Parameter(Mandatory = $true)]
        [string] $StagingStorageAccountVariableName
    )

    $stagingStorageAccount = Get-AzureRmStorageAccount |
        Where-Object -FilterScript { $_.StorageAccountName -eq $StorageAccountName } |
        Select-Object -First 1

    if ($stagingStorageAccount -eq $null) {
        $storageResourceGroupName = 'ARM-Deploy-Staging'
        Write-Verbose -Message ('Create a new resource group "{0}" for the staging storage account...' -f $storageResourceGroupName)
        New-AzureRmResourceGroup -Location $StorageAccountLocation -Name $storageResourceGroupName -Force

        Write-Verbose -Message ('Create a new storage account "{0}" ...' -f $StorageAccountName)
        $params = @{
            ResourceGroupName  = $storageResourceGroupName
            Location           = $StorageAccountLocation
            StorageAccountName = $StorageAccountName
            SkuName            = 'Standard_LRS'
            Kind               = 'Storage'
        }
        $stagingStorageAccount = New-AzureRmStorageAccount @params
        $stagingStorageAccount
    }

    Set-Variable -Name $StagingStorageAccountVariableName -Value $stagingStorageAccount -Scope 1
}

function UploadArtifact
{
    [OutputType([object[]])]
    param (
        [Parameter(Mandatory = $true)]
        [string] $TemplateParametersFilePath,

        [Parameter(Mandatory = $true)]
        [string] $ArtifactStagingDirectory,

        [Parameter(Mandatory = $true)]
        [string] $DscSourceFolder,

        [Parameter(Mandatory = $true)]
        [string] $ResourceGroupName,

        [Parameter(Mandatory = $true)]
        [string] $ResourceGroupLocation,

        [Parameter(Mandatory = $true)][AllowEmptyString()]
        [string] $ArtifactStagingStorageAccountName,

        [Parameter(Mandatory = $true)][AllowEmptyString()]
        [string] $ArtifactStagingContainerName,

        [Parameter(Mandatory = $true)]
        [string] $ResultVariableName
    )

    # Create a new storage account if it doesn't already exist.
    if ($ArtifactStagingStorageAccountName -eq '')
    {
        $ArtifactStagingStorageAccountName = 'stage' + ((Get-AzureRmContext).Subscription.SubscriptionId).Replace('-', '').Substring(0, 19)
    }
    CreateStagingStorageAccountIfNotExist -StorageAccountName $ArtifactStagingStorageAccountName `
                                          -StorageAccountLocation $ResourceGroupLocation `
                                          -StagingStorageAccountVariableName 'stagingStorageAccount'

    # Create a new container if it doesn't already exist.
    if ($ArtifactStagingContainerName -eq '')
    {
        $ArtifactStagingContainerName = $ResourceGroupName.ToLowerInvariant() + '-stageartifacts'
    }
    New-AzureStorageContainer -Name $ArtifactStagingContainerName `
                              -Context $stagingStorageAccount.Context `
                              -ErrorAction SilentlyContinue

    # Create the DSC configuration archive file.
    CreateDscConfigurationArchiveFile -DscSourceFolderPath $DscSourceFolder

    # Copy the files from the local storage staging location to the storage account container.
    UploadArtifactFile -ArtifactStagingDirectoryPath $ArtifactStagingDirectory `
                       -StorageContext $stagingStorageAccount.Context `
                       -ContainerName $ArtifactStagingContainerName

    # Get the artifacts location and artifacts location SAS token from the template parameter file.
    $artifactsLocationInfo = GetArtifactsLocationInfo -TemplateParametersFilePath $TemplateParametersFilePath

    # Set the artifacts location.
    if ($artifactsLocationInfo.ArtifactsLocation -ne $null)
    {
        $artifactsLocation = $artifactsLocationInfo.ArtifactsLocation
    }
    else
    {
        $artifactsLocation = $stagingStorageAccount.Context.BlobEndPoint + $ArtifactStagingContainerName
    }

    # Set the artifacts location SAS token.
    if ($artifactsLocationInfo.SasToken -ne $null)
    {
        $artifactsLocationSasToken = $artifactsLocationInfo.SasToken
    }
    else
    {
        # Generate a SAS token for the artifacts location.
        $params = @{
            Context    = $stagingStorageAccount.Context
            Container  = $ArtifactStagingContainerName
            Permission = 'r'
            ExpiryTime = (Get-Date).AddHours(4)
        }
        $artifactsLocationSasToken = ConvertTo-SecureString -String (New-AzureStorageContainerSASToken @params) `
                                                            -AsPlainText -Force
    }

    $result = [PSCustomObject] @{
        ArtifactsLocation = $artifactsLocation
        SasToken          = $artifactsLocationSasToken
    }
    Set-Variable -Name $ResultVariableName -Value $result -Scope 1
}

function GetAbsolutePath
{
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [string] $RelativePath
    )

    return [System.IO.Path]::GetFullPath((Join-Path -Path (Get-Location).Path -ChildPath $RelativePath))
}

## Start here

Get-AzureRmContext

# Convert the relative paths to absolute paths.
$TemplateFilePath = GetAbsolutePath -RelativePath $TemplateFilePath
$TemplateParametersFilePath = GetAbsolutePath -RelativePath $TemplateParametersFilePath

$optionalParameters = New-Object -TypeName 'System.Collections.Hashtable'

if ($UploadArtifact)
{
    $params = @{
        TemplateParametersFile            = $TemplateParametersFilePath
        ArtifactStagingDirectory          = (GetAbsolutePath -RelativePath $ArtifactStagingDirectory)
        DscSourceFolder                   = (GetAbsolutePath -RelativePath $DscSourceFolder)
        ResourceGroupName                 = $ResourceGroupName
        ResourceGroupLocation             = $ResourceGroupLocation
        ArtifactStagingStorageAccountName = $ArtifactStagingStorageAccountName
        ArtifactStagingContainerName      = $ArtifactStagingContainerName
        ResultVariableName                = 'artifactInfo'
    }
    UploadArtifact @params

    $optionalParameters[$Key_ArtifactsLocation] = $artifactInfo.ArtifactsLocation
    $optionalParameters[$Key_ArtifactsLocationSasToken] = $artifactInfo.SasToken
}

# Create or update the resource group using the specified template file and template parameters file
New-AzureRmResourceGroup -Name $ResourceGroupName -Location $ResourceGroupLocation -Verbose -Force

if ($ValidateOnly)
{
    $params = @{
        ResourceGroupName     = $ResourceGroupName
        TemplateFile          = $TemplateFilePath
        TemplateParameterFile = $TemplateParametersFilePath
    }
    $errorMessages = Format-ValidationOutput (Test-AzureRmResourceGroupDeployment @params @optionalParameters)

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
    $deploymentName = ('{0}-{1}' -f (Get-ChildItem -LiteralPath $TemplateFilePath).BaseName, (Get-Date).ToString('MM-dd-HHmm'))
    $params = @{
        Name                  = $deploymentName
        ResourceGroupName     = $ResourceGroupName
        TemplateFile          = $TemplateFilePath
        TemplateParameterFile = $TemplateParametersFilePath
        Force                 = $true
        Verbose               = $true
        ErrorVariable         = 'errorMessages'
    }
    New-AzureRmResourceGroupDeployment @params @optionalParameters

    if ($errorMessages)
    {
        Write-Output '', 'Template deployment returned the following errors:',
            @(@($errorMessages) | ForEach-Object -Process { $_.Exception.Message.TrimEnd("`r`n") })
    }
}
