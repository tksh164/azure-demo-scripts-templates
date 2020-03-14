$VerbosePreference = 'Continue'

$source = @{
    Name          = 'ilb1'
    ResourceGroup = 'lab-ilb'
}

$destination = @{
    Name          = $source.Name
    ResourceGroup = $source.ResourceGroup
    Sku           = 'Standard'
    #Sku           = 'Basic'
}

## end of script settings

function GetResourceNameFromId
{
    param (
        [Parameter(Mandatory = $true)]
        [string] $Id
    )
    $lastIndex = $Id.LastIndexOf('/')
    $Id.Substring($lastIndex + 1)
}

function GetNetInterfaceInfoFromId
{
    param (
        [Parameter(Mandatory = $true)]
        [string] $NetInterfaceIpConfigId
    )
    $parts = $NetInterfaceIPConfigId.Split('/')
    $parts[4], $parts[8], $parts[10]
}

# Get the source load balancer.

Write-Verbose -Message 'Get the source load balancer...'

$params = @{
    ResourceGroupName = $source.ResourceGroup
    Name              = $source.Name
}
$sourceLoadBalancer = Get-AzLoadBalancer @params

# Save the source load balancer configurations.

Write-Verbose -Message 'Save the source load balancer configuration...'

$sourceLoadBalancer | Out-File -LiteralPath ('{0}.source.txt' -f $sourceLoadBalancer.Name) -Force

# Create the frontend IP configurations.

Write-Verbose -Message 'Create the frontend IP configurations for the destination load balancer...'

$destinationFrontendIpConfigs = @()
foreach ($sourceIpConfig in $sourceLoadBalancer.FrontendIpConfigurations)
{
    $params = @{
        Name   = $sourceIpConfig.Name
        Subnet = $sourceIpConfig.Subnet
        Zone   = $sourceIpConfig.Zones
    }
    if ($sourceIpConfig.PrivateIpAllocationMethod -eq 'Static')
    {
        $params.PrivateIpAddress = $sourceIpConfig.PrivateIpAddress
    }
    $destinationFrontendIpConfigs += New-AzLoadBalancerFrontendIpConfig @params
}

# Create the inbound NAT rules.

Write-Verbose -Message 'Create the inbound NAT rules for the destination load balancer...'

$destinationInboundNatRuleConfigs = @()
foreach ($sourceRule in $sourceLoadBalancer.InboundNatRules)
{
    $frontendIpConfigName = GetResourceNameFromId -Id $sourceRule.FrontendIPConfiguration.Id

    $params = @{
        Name                    = $sourceRule.Name
        Protocol                = $sourceRule.Protocol
        FrontendPort            = $sourceRule.FrontendPort
        BackendPort             = $sourceRule.BackendPort
        IdleTimeoutInMinutes    = $sourceRule.IdleTimeoutInMinutes
        EnableFloatingIP        = $sourceRule.EnableFloatingIP
        EnableTcpReset          = $sourceRule.EnableTcpReset
        FrontendIpConfiguration = $destinationFrontendIpConfigs | Where-Object -Property 'Name' -EQ -Value $frontendIpConfigName
    }
    $destinationInboundNatRuleConfigs += New-AzLoadBalancerInboundNatRuleConfig @params
}

# Create the backend pools.

Write-Verbose -Message 'Create the backend pools for the destination load balancer...'

$destinationBackendAddressPools = @()
foreach ($sourcePool in $sourceLoadBalancer.BackendAddressPools)
{
    $destinationBackendAddressPools += New-AzLoadBalancerBackendAddressPoolConfig -Name $sourcePool.Name
}

# Create the probes.

Write-Verbose -Message 'Create the probes for the destination load balancer...'

$destinationProbes = @()
foreach ($sourceProbes in $sourceLoadBalancer.Probes)
{
    $params = @{
        Name              = $sourceProbes.Name
        Port              = $sourceProbes.Port
        IntervalInSeconds = $sourceProbes.IntervalInSeconds
        ProbeCount        = $sourceProbes.NumberOfProbes
        Protocol          = $sourceProbes.Protocol
        RequestPath       = $sourceProbes.RequestPath
    }
    $destinationProbes += New-AzLoadBalancerProbeConfig @params
}

# Create the load balancing rules.

Write-Verbose -Message 'Create the load balancing rules for the destination load balancer...'

$destinationLoadBalancingRules = @()
foreach ($sourceRule in $sourceLoadBalancer.LoadBalancingRules)
{
    $frontendIpConfigName = GetResourceNameFromId -Id $sourceRule.FrontendIPConfiguration.Id
    $backendAddressPoolName = GetResourceNameFromId -Id $sourceRule.BackendAddressPool.Id
    $probeName = GetResourceNameFromId -Id $sourceRule.Probe.Id

    $params = @{
        Name                    = $sourceRule.Name
        Protocol                = $sourceRule.Protocol
        LoadDistribution        = $sourceRule.LoadDistribution
        FrontendPort            = $sourceRule.FrontendPort
        BackendPort             = $sourceRule.BackendPort
        IdleTimeoutInMinutes    = $sourceRule.IdleTimeoutInMinutes
        EnableFloatingIP        = $sourceRule.EnableFloatingIP
        EnableTcpReset          = $sourceRule.EnableTcpReset
        FrontendIpConfiguration = $destinationFrontendIpConfigs | Where-Object -Property 'Name' -EQ -Value $frontendIpConfigName
        BackendAddressPool      = $destinationBackendAddressPools | Where-Object -Property 'Name' -EQ -Value $backendAddressPoolName
        Probe                   = $destinationProbes | Where-Object -Property 'Name' -EQ -Value $probeName
    }
    $destinationLoadBalancingRules += New-AzLoadBalancerRuleConfig @params
}

# Remove the source load balancer.

Write-Verbose -Message 'Remove the source load balancer...'

$params = @{
    ResourceGroupName = $source.ResourceGroup
    Name              = $source.Name
    Force             = $true
}
Remove-AzLoadBalancer @params

# Create the destination balancer.

Write-Verbose -Message 'Create the destination load balancer...'

$params = @{
    ResourceGroupName       = $destination.ResourceGroup
    Name                    = $destination.Name
    Location                = $sourceLoadBalancer.Location
    Tag                     = $sourceLoadBalancer.Tag
    Sku                     = $destination.Sku
    FrontendIpConfiguration = $destinationFrontendIpConfigs
    BackendAddressPool      = $destinationBackendAddressPools
    Probe                   = $destinationProbes
    LoadBalancingRule       = $destinationLoadBalancingRules
    InboundNatRule          = $destinationInboundNatRuleConfigs
    InboundNatPool          = $sourceLoadBalancer.InboundNatPools
}
$destinationLoadBalancer = New-AzLoadBalancer @params

# Update the backend address pool of the destination load balancer.

Write-Verbose -Message 'Update the backend address pool of the destination load balancer...'

foreach ($sourcePool in $sourceLoadBalancer.BackendAddressPools)
{
    $sourceLoadBalancerBackendAddressPoolName = $sourcePool.Name

    foreach ($sourceIpConfig in $sourcePool.BackendIpConfigurations)
    {
        ($netInterfaceResourceGroup, $netInterfaceName, $netInterfaceIpConfigName) = GetNetInterfaceInfoFromId -NetInterfaceIpConfigId $sourceIpConfig.Id

        $netInterface = Get-AzNetworkInterface -ResourceGroupName $netInterfaceResourceGroup -Name $netInterfaceName
        $backend = Get-AzLoadBalancerBackendAddressPoolConfig -LoadBalancer $destinationLoadBalancer -Name $sourceLoadBalancerBackendAddressPoolName

        $netInterfaceIpConfig = $netInterface.IpConfigurations | Where-Object -Property Name -EQ -Value $netInterfaceIpConfigName
        $netInterfaceIpConfig.LoadBalancerBackendAddressPools = $backend

        Set-AzNetworkInterface -NetworkInterface $netInterface | Out-Null
    }
}

# Save the destination load balancer configurations.

Write-Verbose -Message 'Save the destination load balancer configuration...'

$params = @{
    ResourceGroupName = $destination.ResourceGroup
    Name              = $destination.Name
}
$destinationLoadBalancer = Get-AzLoadBalancer @params
$destinationLoadBalancer | Out-File -LiteralPath ('{0}.destination.txt' -f $destinationLoadBalancer.Name) -Force
