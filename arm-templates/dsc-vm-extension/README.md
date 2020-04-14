# DSC VM extension

## Template overview

Virtual machine with DSC VM extension.

### Deployments

All the below names are the default value.

- Resource group: `lab-dscext`
- Virtual network: `dscext-vnet`
    - IPv4 address space: `10.0.0.0/16`
    - Subnet: `default`
        - Address prefix: `10.0.0.0/24`
        - Virtual machine: `dscext-vm1`
            - For RDP connection from Internet.
            - OS disk: `dscext-vm1-osdisk`
            - Network interface: `dscext-vm1-nic`
                - Private IP address: `10.0.0.5`, Static
            - Public IP address: `dscext-vm1-ip`
            - Network security group: `dscext-vm1-nsg`

### Non-deployments

- n/a

## Notes

- The deploy.ps1 script needs [Az module](https://www.powershellgallery.com/packages/Az/).

## Configuration in dscvmext.ps1 (dscvmext.zip)

| Name | Description |
| ---- | ---- |
| raw-configuration | The DSC configuration for general purpose. You can define the configuration in the ARM template. |
| install-windows-feature | Install Windows features. |
| download-file | Download the file from the specified URL to the specified local file system path. |

### Example for raw-configuration

```json
{
    "type": "Microsoft.Compute/virtualMachines/extensions",
    "apiVersion": "2019-07-01",
    "name": "vm1/Microsoft.Powershell.DSC",
    "location": "japaneast",
    "dependsOn": [
        "[resourceId('Microsoft.Compute/virtualMachines', 'vm1')]"
    ],
    "properties": {
        "publisher": "Microsoft.Powershell",
        "type": "DSC",
        "typeHandlerVersion": "2.80",
        "autoUpgradeMinorVersion": true,
        "settings": {
            "wmfVersion": "latest",
            "privacy": {
                "dataCollection": "enable"
            },
            "configuration": {
                "url": "https://github.com/tksh164/azure-demo-scripts-templates/raw/master/arm-templates/dsc-vm-extension/dscvmext.zip",
                "script": "dscvmext.ps1",
                "function": "raw-configuration"
            },
            "configurationArguments": {
                "RawConfig": "
                    node localhost
                    {
                        LocalConfigurationManager 
                        {
                            RebootNodeIfNeeded = $true
                        }
                        # Enable IP forwarding and reboot the OS to apply the IP forwarding registry settings.
                        $regPath = 'HKLM:\\SYSTEM\\CurrentControlSet\\Services\\Tcpip\\Parameters'
                        $regName = 'IPEnableRouter'
                        Script Reboot {
                            TestScript = {
                                $regValue = Get-ItemProperty -LiteralPath $using:regPath -Name $using:regName -ErrorAction SilentlyContinue
                                ($regValue -ne $null) -and ($regValue.IPEnableRouter -eq 1)
                            }
                            SetScript  = {
                                Set-ItemProperty -LiteralPath $using:regPath -Name $using:regName -Value 1 -Force
                                $global:DSCMachineStatus = 1
                            }
                            GetScript  = { @{ Result = 'GetScript reuslt' } }
                        }
                    }
                "
            }
        },
        "protectedSettings": {}
    }
}
```

### Example for install-windows-feature

```json
{
    "type": "Microsoft.Compute/virtualMachines/extensions",
    "apiVersion": "2019-07-01",
    "name": "vm1/Microsoft.Powershell.DSC",
    "location": "japaneast",
    "dependsOn": [
        "[resourceId('Microsoft.Compute/virtualMachines', 'vm1')]"
    ],
    "properties": {
        "publisher": "Microsoft.Powershell",
        "type": "DSC",
        "typeHandlerVersion": "2.80",
        "autoUpgradeMinorVersion": true,
        "settings": {
            "wmfVersion": "latest",
            "privacy": {
                "dataCollection": "enable"
            },
            "configuration": {
                "url": "https://github.com/tksh164/azure-demo-scripts-templates/raw/master/arm-templates/dsc-vm-extension/dscvmext.zip",
                "script": "dscvmext.ps1",
                "function": "install-windows-feature"
            },
            "configurationArguments": {
                "FeatureNameList": [
                    "Web-Server",
                    "Web-Mgmt-Console"
                ]
            }
        },
        "protectedSettings": {}
    }
}
```

### Example for download-file

```json
{
    "type": "Microsoft.Compute/virtualMachines/extensions",
    "apiVersion": "2019-07-01",
    "name": "vm1/Microsoft.Powershell.DSC",
    "location": "japaneast",
    "dependsOn": [
        "[resourceId('Microsoft.Compute/virtualMachines', 'vm1')]"
    ],
    "properties": {
        "publisher": "Microsoft.Powershell",
        "type": "DSC",
        "typeHandlerVersion": "2.80",
        "autoUpgradeMinorVersion": true,
        "settings": {
            "wmfVersion": "latest",
            "privacy": {
                "dataCollection": "enable"
            },
            "configuration": {
                "url": "https://github.com/tksh164/azure-demo-scripts-templates/raw/master/arm-templates/dsc-vm-extension/dscvmext.zip",
                "script": "dscvmext.ps1",
                "function": "download-file"
            },
            "configurationArguments": {
                "UrlList": [
                    // Wireshark
                    "https://1.as.dl.wireshark.org/win64/Wireshark-win64-3.2.2.exe",
                    // Microsoft Edge Beta channel
                    "https://c2rsetup.officeapps.live.com/c2r/downloadEdge.aspx?ProductreleaseID=Edge&platform=Default&version=Edge&source=EdgeInsiderPage&Channel=Beta&language=en"
                ],
                "DownloadFolderPath": "C:\\work"
            }
        },
        "protectedSettings": {}
    }
}
```

