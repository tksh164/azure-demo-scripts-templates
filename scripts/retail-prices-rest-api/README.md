# Azure Retail Prices REST API sample

## Example usage

### All prices in a region

```PowerShell
.\retailprices.ps1 -ArmRegionName japaneast
```

### Specific service family

```PowerShell
.\retailprices.ps1 -ArmRegionName japaneast -ServiceFamily Networking
```

```PowerShell
.\retailprices.ps1 -ArmRegionName Global -ServiceFamily Networking
```

### Specific service

```PowerShell
.\retailprices.ps1 -ServiceName ExpressRoute
```

### Specific SKU

```PowerShell
.\retailprices.ps1 -ArmRegionName japaneast -ArmSkuName Standard_D8ads_v5
```

### Output to grid view

```PowerShell
.\retailprices.ps1 -ArmRegionName japaneast -ArmSkuName Standard_D8ads_v5 | Out-GridView
```

## References

- [Azure Retail Prices overview](https://docs.microsoft.com/en-us/rest/api/cost-management/retail-prices/azure-retail-prices)
- https://prices.azure.com/api/retail/prices
