# 🦑 Deploy Squid proxy virtual machine into virtual network

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#view/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2Ftksh164%2Fazure-demo-scripts-templates%2Fmaster%2Farm-templates%2Fpreconfigured%2Fsquid-proxy%2Ftemplate.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2Ftksh164%2Fazure-demo-scripts-templates%2Fmaster%2Farm-templates%2Fpreconfigured%2Fsquid-proxy%2Fuiform.json)

## Template overview

Deploy a virtual machine as a proxy server using Squid into a new virtual network or an existing virtual network.

You can use the proxy server from within the virtual network with the following address.

```
<Proxy server's private IP address>:3128
```

## Notes

- Squid is installed through the template deployment.
- Squid is active with the default config and `http_access allow localnet`.

## TODO

- [ ] Add Public IP address option
