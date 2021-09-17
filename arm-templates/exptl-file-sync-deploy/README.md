# Deploy Azure File Sync environment

## Template overview

Deploy the Azure File Sync environment including the Microsoft.StorageSync service principal role assignment.

### Deployment

All the below name and values are the default value.

- Resource group: `exptl-afs`
    - Storage accounts: `fsync*`
    - Role assignments
    - Storage Sync Service: `afs-fsync`
    - Cloud endpoints

### Template parameters

- `resourcePrefix`: Specify the prefix for the resource name.
- `storageAccountNamePrefix`: Specify the prefix for the storage account resource name.
- `syncGroupCount`: Specify the number of sync groups to create.
- `storageSyncPrincipalId`: The Microsoft.StorageSync service principal ID. This can get by:

    ```PowerShell
    (Get-AzADServicePrincipal -DisplayNameBeginsWith Microsoft.StorageSync | Select-Object -First 1).Id`
    ```

### Deploy

You can deploy this template using the `deploy.ps1` script.

```PowerShell
.\deploy.ps1
```

Also you can specify the resource group name via -ResourceGroupName parameter.

```PowerShell
.\deploy.ps1 -ResourceGroupName lab-afs1
```

## Helper scripts

### undeploy-afs.ps1

This script deletes all Azure File Sync related resources in the specified resource group such as Server endpoints, Cloud endpoints, Sync Groups, Registered servers, Storage Sync Service, Storage accounts.

```PowerShell
.\delete-afs-res.ps1 -ResourceGroupName lab-afs1
```

<!--
## Deployment steps

1. Deploy the following resources using the ARM template.
    - Storage Sync Service & Sync Groups
    - Storage Accounts
    - The template deployment takes around 1 minute with 30 Storage Accounts.

2. Add cloud endpoints using the PowerShell script.
    - Sometimes failed the cloud endpoint adding with the following error. The error happens even if add cloud endpoints through an ARM template. That is reason I add cloud endpoints through the script.

        ```
        VERBOSE: 11:47:56 PM - Creating Role Assignment...
        VERBOSE: Performing the operation "Create a new Cloud Endpoint f5cb05ee-210b-40d9-a18d-97c8d20276b3" on target "f5cb05ee-210b-40d9-a18d-97c8d20276b3".
        New-AzStorageSyncCloudEndpoint: D:\work\deploy-cloudendpoint.ps1:33
        Line |
        33 |                      New-AzStorageSyncCloudEndpoint @params
            |                      ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            | Long running operation failed with status 'Failed'. Additional Info:'Unable to read specified storage
            | account. Please check the permissions and try again after some time.' Code:
            | MgmtStorageAccountAuthorizationFailed Message: Unable to read specified storage account. Please check the
            | permissions and try again after some time. Target:
        ```
    - The PowerShell script execution takes around 35 minutes with 30 Sync Groups if no error.
    - You can simply re-run the PowerShell script if the error happened.

3. Deploy the file server VM.
    - Install Azure File Sync agent and register to Storage Sync Service.
    - Attach a data disk for files store and format it.

4. Add server endpoints using the PowerShell script.
    - The PowerShell script execution takes around 16 minutes with 30 Sync Groups if no error.
    - You can simply re-run the PowerShell script if the error happened.

5. You can delete all resources using the PowerShell script.
    - The synced folders on the server are remained even if delete the server endpoint and unregister the server.
    - You can re-register the server from Azure File Sync Updater on the server.
-->
