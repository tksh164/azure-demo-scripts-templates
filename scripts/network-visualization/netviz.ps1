function Search-VNet {
    param (
        [Parameter(Mandatory = $true)]
        [string] $ResourceGroup,
    
        [Parameter(Mandatory = $true)]
        [string] $VNetName
    )

$query = @'
resources
| where type =~ "Microsoft.Network/virtualNetworks"
    and resourceGroup =~ "{0}"
    and name =~ "{1}" 
'@ -f $ResourceGroup, $VNetName

    $vnet = Search-AzGraph -Query $query -First 1
    # TODO: Handle if $vnet is null
    return $vnet
}

function Search-ResourceById {
    param (
        [Parameter(Mandatory = $true)]
        [string] $ResourceId
    )

$query = @'
resources
| where id =~ "{0}"
'@ -f $ResourceId

    $resource = Search-AzGraph -Query $query -First 1
    # TODO: Handle if $vnet is null
    return $resource
}

function New-VirtualNetworkObject {
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject] $ArgResult
    )

    $vnetObject = [PSCustomObject]@{
        Id      = $ArgResult.id
        Name    = $ArgResult.name
        Subnets = @()
    }
    $vnetObject.Subnets += $ArgResult.properties.subnets | ForEach-Object -Process { New-SubnetObject -ArgResult $_ }
    return $vnetObject
}

function New-SubnetObject {
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject] $ArgResult
    )

    $subnetObject = [PSCustomObject] @{
        Id               = $ArgResult.id
        Name             = $ArgResult.name
        AddressPrefix    = $ArgResult.properties.addressPrefix
        IpConfigurations = @()
    }

    $subnetObject.IpConfigurations += $ArgResult.properties.ipConfigurations.id | ForEach-Object -Process {
        $ipConfigurationResIdParts = $_ -split '/'
        $ipConfigurationResName = $ipConfigurationResIdParts[-1]
        $networkInterfaceResId = $ipConfigurationResIdParts[0..8] -join '/'
        $argNic = Search-ResourceById -ResourceId $networkInterfaceResId
        $ipConfig = $argNic.properties.ipConfigurations | Where-Object -FilterScript { $_.name -eq $ipConfigurationResName }
        New-IpConfigurationObject -ArgResult $ipConfig
    }
    return $subnetObject
}

function New-IpConfigurationObject {
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject] $ArgResult
    )

    $ipConfig = $ArgResult.properties.ipConfigurations | Where-Object -FilterScript { $_.name -eq $IpConfigurationName }
    $ipConfigObject = [PSCustomObject]@{
        Id                   = $ArgResult.id
        Name                 = $ArgResult.name
        PrivateIPAddress     = $ArgResult.properties.privateIPAddress
    }
    return $ipConfigObject
}

function Format-NetworkDiagram {
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject] $VirtualNetworkObject
    )

    Write-Host ('Virtual Network: {0}' -f $VirtualNetworkObject.Name)
    $VirtualNetworkObject.Subnets | ForEach-Object -Process {
        $subnet = $_
        Write-Host ('  Subnet: {0} - {1}' -f $subnet.Name, $subnet.AddressPrefix)
        $subnet.IpConfigurations | ForEach-Object -Process {
            $ipConfig = $_
            Write-Host ('    IP Configuration: {0}' -f $ipConfig.Name)
            Write-Host ('      Private IP Address: {0}' -f $ipConfig.PrivateIPAddress)
        }
    }
}


$resourceGroup = 'azloc-portal3'
$vnetName = 'hcilab-vnet'
$argVNet = Search-VNet -ResourceGroup $resourceGroup -VNetName $vnetName

$vnetObj = New-VirtualNetworkObject -ArgResult $argVNet

Format-NetworkDiagram -VirtualNetworkObject $vnetObj
