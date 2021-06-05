# Deploy large Azure File Sync environment

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
            | Long running operation failed with status 'Failed'. Additional Info:'Unable to read specified storage account. Please check the permissions and try again after some time.' Code: MgmtStorageAccountAuthorizationFailed Message: Unable to read specified storage account. Please check the permissions and try again after some time. Target:
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
