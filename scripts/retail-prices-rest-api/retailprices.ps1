[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet(
        'Global',
        'Intercontinental',
        'centralus', 'northcentralus', 'southcentralus', 'westcentralus', 'eastus', 'eastus2', 'westus', 'westus2', 
        'North America', 'South America',
        'canadacentral', 'canadaeast', 'centralindia',
        'brazilsouth', 'brazilsoutheast',
        'Europe', 'northeurope', 'westeurope', 
        'uknorth', 'uksouth', 'uksouth2', 'ukwest',    
        'Germany', 'germanynorth', 'germanywestcentral',
        'francecentral', 'francesouth',
        'norwayeast', 'norwaywest',
        'switzerlandnorth', 'switzerlandwest',
        'Asia', 'eastasia', 'southeastasia',
        'China',
        'japaneast', 'japanwest',
        'koreacentral', 'koreasouth',
        'India', 'southindia', 'westindia',
        'australiacentral', 'australiacentral2', 'australiaeast', 'australiasoutheast',
        'Oceania',
        'uaecentral', 'uaenorth',
        'Middle East And Africa', 'southafricanorth', 'southafricawest', 
        'US Gov', 'US Gov Zone 1', 'US Gov Zone 2',
        'CN Zone 1', 'CN Zone 2', 'DE Zone 1',
        'Azure Stack', 'Azure Stack CN', 'Azure Stack US Gov',
        'Zone 1', 'Zone 2', 'Zone 3', 'Zone 4', 'Zone 5'
    )]
    [string] $ArmRegionName,

    [Parameter(Mandatory = $false)]
    [string] $Location,

    [Parameter(Mandatory = $false)]
    [string] $MeterId,

    [Parameter(Mandatory = $false)]
    [string] $MeterName,

    [Parameter(Mandatory = $false)]
    [string] $ProductId,

    [Parameter(Mandatory = $false)]
    [string] $SkuId,

    [Parameter(Mandatory = $false)]
    [string] $ProductName,

    [Parameter(Mandatory = $false)]
    [string] $SkuName,

    [Parameter(Mandatory = $false)]
    [string] $ServiceName,

    [Parameter(Mandatory = $false)]
    [string] $ServiceId,

    [Parameter(Mandatory = $false)]
    [ValidateSet('Analytics', 'Blockchain', 'Compute', 'Containers', 'Databases', 'Developer Tools', 'Integration', 'Internet of Things', 'Management and Governance', 'Networking', 'Other', 'Storage', 'Web')]
    [string] $ServiceFamily,

    [Parameter(Mandatory = $false)]
    [ValidateSet('Consumption', 'DevTestConsumption', 'Reservation')]
    [string] $PriceType,

    [Parameter(Mandatory = $false)]
    [string] $ArmSkuName
)

$filters = @()
if ($PSBoundParameters.ContainsKey('ArmRegionName')) { $filters += 'armRegionName eq ''{0}''' -f $ArmRegionName }
if ($PSBoundParameters.ContainsKey('Location')) { $filters += 'location eq ''{0}''' -f $Location }
if ($PSBoundParameters.ContainsKey('MeterId')) { $filters += 'meterId eq ''{0}''' -f $MeterId }
if ($PSBoundParameters.ContainsKey('MeterName')) { $filters += 'meterName eq ''{0}''' -f $MeterName }
if ($PSBoundParameters.ContainsKey('ProductId')) { $filters += 'productId eq ''{0}''' -f $ProductId }
if ($PSBoundParameters.ContainsKey('SkuId')) { $filters += 'skuId eq ''{0}''' -f $SkuId }
if ($PSBoundParameters.ContainsKey('ProductName')) { $filters += 'productName eq ''{0}''' -f $ProductName }
if ($PSBoundParameters.ContainsKey('SkuName')) { $filters += 'skuName eq ''{0}''' -f $SkuName }
if ($PSBoundParameters.ContainsKey('ServiceName')) { $filters += 'serviceName eq ''{0}''' -f $ServiceName }
if ($PSBoundParameters.ContainsKey('ServiceId')) { $filters += 'serviceId eq ''{0}''' -f $ServiceId }
if ($PSBoundParameters.ContainsKey('ServiceFamily')) { $filters += 'serviceFamily eq ''{0}''' -f $ServiceFamily }
if ($PSBoundParameters.ContainsKey('PriceType')) { $filters += 'type eq ''{0}''' -f $PriceType }
if ($PSBoundParameters.ContainsKey('ArmSkuName')) { $filters += 'armSkuName eq ''{0}''' -f $ArmSkuName }

$uri = 'https://prices.azure.com/api/retail/prices'
if ($filters.Length -ne 0)
{
    $uri = $uri + '?$filter=' + ($filters -join ' and ')
}

$priceList = @()
while ($true)
{
    $params = @{
        Uri         = $uri
        Method      = [Microsoft.PowerShell.Commands.WebRequestMethod]::Get
        ContentType = 'application/json;charset=utf-8'
    }
    $result = Invoke-RestMethod @params

    $priceList += $result.Items
    if ($result.NextPageLink -eq $null) { break }
    $uri = $result.NextPageLink
}

$priceList
