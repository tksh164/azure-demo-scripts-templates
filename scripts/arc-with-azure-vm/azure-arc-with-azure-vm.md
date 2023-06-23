# Azure Arc-enabled servers using Azure VM

Azure Arc-enabled servers is not designed or supported to enable management of virtual machines running in Azure. However, you can use Azure VM with Azure Arc-enabled servers for evaluation and testing purposes.

- [Evaluate Azure Arc-enabled servers on an Azure virtual machine](https://learn.microsoft.com/en-us/azure/azure-arc/servers/plan-evaluate-on-azure-virtual-machine)

## For Windows Azure VM

1. Remove the Azure VM's extensions. You can do this by run the following in Azure Cloud Shell.

    ```powershell
    $rgName = 'vmext-rg'
    $vmName = 'vm1'
    Get-AzVMExtension -ResourceGroupName $rgName -VMName $vmName | Remove-AzVMExtension -Force -Verbose
    ```
2. Connect to the Azure VM with RDP then run the following commands.

    ```powershell
    # Disable and stop the Azure VM guest agent.
    Set-Service -Name 'WindowsAzureGuestAgent' -StartupType Disabled -Verbose
    Stop-Service -Name 'WindowsAzureGuestAgent' -Force -Verbose

    # Create a new Windows Firewall rule that blocks communication with Azure Instance Metadata Service (IMDS).
    New-NetFirewallRule -Name 'BlockAzureIMDS' -DisplayName 'Block access to Azure IMDS' -Enabled True -Profile Any -Direction Outbound -Action Block -RemoteAddress '169.254.169.254' -Verbose
    ```

## For Linux Azure VM (Ubuntu)

1. Remove the Azure VM's extensions. You can do this by run the following in Azure Cloud Shell.

    ```powershell
    $rgName = 'vmext-rg'
    $vmName = 'vm1'
    Get-AzVMExtension -ResourceGroupName $rgName -VMName $vmName | Remove-AzVMExtension -Force -Verbose
    ```
2. Connect to the Azure VM with SSH then run the following commands.

    ```shell
    # Deprovision of the Azure VM guest agent.
    CURRENT_HOSTNAME=$(hostname)
    sudo systemctl stop walinuxagent
    sudo waagent -deprovision -force
    sudo rm -rf /var/lib/waagent
    sudo hostnamectl set-hostname $CURRENT_HOSTNAME

    # Block communication with Azure Instance Metadata Service (IMDS).
    sudo ufw --force enable
    sudo ufw deny out from any to 169.254.169.254
    sudo ufw default allow incoming
    ```
