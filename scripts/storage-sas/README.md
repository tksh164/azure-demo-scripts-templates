# Azure Storage SAS

- **create-udsas.ps1** for create SAS, User delegation SAS and User-bound user delegation SAS.

    ```powershell
    PS C:\> .\create-udsas.ps1
    PS C:\> SAS URL: https://account.blob.core.windows.net/con1/test.txt?....
    ```

    - You need update some variables in the script before run it.

        ```powershell
        # Blob
        $blobUrl = 'https://account.blob.core.windows.net/con1/test.txt'

        # Signed user's tenant ID. Signed user means the user who creates SAS.
        $signedUserTenantId = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'

        # SAS configuraton
        $start = '2026-03-05T08:30:32Z'
        $expiry = '2026-03-05T16:45:32Z'

        $serviceVersion = '2026-04-06'

        # For user-bound user-delegation SAS tokens.
        $delegatedEndUserObjectId = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
        ```

- **access-ubudsas.ps1** for access to user-bound user delegation SAS.

    ```powershell
    PS C:\> .\access-ubudsas.ps1 -SasUrl 'https://account.blob.core.windows.net/con1/test.txt?....'
    ```

Reference for shared access Signature
- [Create an account SAS](https://learn.microsoft.com/rest/api/storageservices/create-account-sas)
- [Create a service SAS](https://learn.microsoft.com/rest/api/storageservices/create-service-sas)

Reference for user delegation SAS
- [Create a user delegation SAS](https://learn.microsoft.com/rest/api/storageservices/create-user-delegation-sas)
