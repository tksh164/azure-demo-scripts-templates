[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string] $ConfigurationFilePath,

    [Parameter(Mandatory = $false)]
    [string] $ConfigurationName,

    [Parameter(Mandatory = $false)]
    [string] $PackageName,

    [Parameter(Mandatory = $false)]
    [string] $Type = 'AuditAndSet',

    [Parameter(Mandatory = $false)]
    [string[]] $FilesToInclude
)

if (-not (Test-Path -PathType Leaf -LiteralPath $ConfigurationFilePath)) {
    throw ('"{0}" does not exist.' -f $ConfigurationFilePath)
}

if (-not $PSBoundParameters.ContainsKey('ConfigurationName')) {
    $ConfigurationName = [IO.Path]::GetFileNameWithoutExtension($ConfigurationFilePath)
}

if (-not $PSBoundParameters.ContainsKey('PackageName')) {
    $PackageName = [IO.Path]::GetFileNameWithoutExtension($ConfigurationFilePath)
}

# Dot-sourcing the configuration file.
. $ConfigurationFilePath

# Compile the configuration.
$mofFile = (& $ConfigurationName)

# Create a new guest configuration package.
$params = @{
    Name          = $PackageName
    Configuration = $mofFile.FullName
    Type          = $Type
    Force         = $true
}
if ($PSBoundParameters.ContainsKey('FilesToInclude')) {
    $params.FilesToInclude = $FilesToInclude
}
$guestConfigPackage = New-GuestConfigurationPackage @params

# Compute the package's file hash.
$fileHashResult = Get-FileHash -Algorithm SHA256 $guestConfigPackage.Path

[PSCUstomObject] @{
    Name = $guestConfigPackage.Name
    Path = $guestConfigPackage.Path
    Hash = $fileHashResult.Hash
} | Format-List
