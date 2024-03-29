# Private link service (Static NAT IP address assignment)

This template deploy the private link service (provider's side only).

## Deploy

You can deploy this template from the following:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Ftksh164%2Fazure-demo-scripts-templates%2Fmaster%2Farm-templates%2Fprivate-link-services%2Fstatic-nat-ip%2Ftemplate.json)

Also you can deploy this template using `deploy.ps1` script.

```
PS > .\deploy.ps1
```

`deploy.ps1` script can specify the resource group via `-ResourceGroupName` parameter.

```
PS > .\deploy.ps1 -ResourceGroupName lab-privatelink
```

## Template overview

### Deployment

- Resource group: `lab-privatelink-static`
    - VNet: `provider-vnet`
        - Subnet: `private-link-service-subnet`
            - Network interface for private link service NAT: `provider-pls.nic.<GUID>`
        - Subnet: `backend-subnet`
            - Internal load balancer: `backend-lbi`
    - Private link service: `provider-pls`

### Not deployment

- The backend pool of internal load balancer is not configured (empty).

## Notes

- `deploy.ps1` script needs [Az module](https://www.powershellgallery.com/packages/Az/).
