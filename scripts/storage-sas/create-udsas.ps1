#Requires -Version 7

$ErrorActionPreference = 'Stop'

function Get-UserDelegationKey {
    param (
        [Parameter(Mandatory = $true)]
        [string] $StorageServiceVersion,

        [Parameter(Mandatory = $true)]
        [string] $BlobUrl,

        [Parameter(Mandatory = $true)]
        [string] $Start,

        [Parameter(Mandatory = $true)]
        [string] $Expiry,

        [Parameter(Mandatory = $true)]
        [string] $DelegatedUserTenantId
    )

    $uri = [uri]$BlobUrl
    $requestUri = '{0}://{1}/?restype=service&comp=userdelegationkey' -f $uri.Scheme, $uri.Host
    $headers = @{
        'x-ms-version' = $StorageServiceVersion
        #'x-ms-client-request-id' = ''  # Optional
    }
    $token = (Get-AzAccessToken -ResourceTypeName Storage).Token
    $payload = @'
<?xml version="1.0" encoding="utf-8"?>  
<KeyInfo>  
    <Start>{0}</Start>
    <Expiry>{1}</Expiry>
    <!--<DelegatedUserTid>{2}</DelegatedUserTid>--><!-- Optional -->
</KeyInfo>    
'@ -f $Start, $Expiry, $DelegatedUserTenantId

    $response = Invoke-RestMethod -Uri $requestUri -Method Post -Authentication Bearer -Token $token -Headers $headers -Body $payload
    $xmlString = $response.TrimStart([char]0xFEFF)  # Remove BOM
    return [xml]$xmlString
}

function Get-StringToSign {
    param (
        [Parameter(Mandatory = $true)]
        [string] $ServiceVersion,

        [Parameter(Mandatory = $true)]
        [string] $BlobUrl,

        [Parameter(Mandatory = $true)]
        [System.Collections.Specialized.OrderedDictionary] $SasParams
    )

    $canonicalizedResource = Get-CanonicalizedResourceInfo -BlobUrl $blobUrl

    $stringToSignArray = switch ($ServiceVersion) {
        { @('2024-11-04') -contains $_ } {
            @(
                $SasParams['signedPermissions'].Value,                   # signedPermissions
                ($SasParams['signedStart'].Value ?? ''),                 # signedStart (Optional)
                $SasParams['signedExpiry'].Value,                        # signedExpiry
                $canonicalizedResource,                                  # canonicalizedResource
                $SasParams['signedObjectId'].Value,                      # signedObjectId / signedKeyObjectId
                $SasParams['signedTenantId'].Value,                      # signedTenantId / signedKeyTenantId
                $SasParams['signedKeyStartTime'].Value,                  # signedKeyStartTime
                $SasParams['signedKeyExpiryTime'].Value,                 # signedKeyExpiryTime
                $SasParams['signedKeyService'].Value,                    # signedKeyService
                $SasParams['signedKeyVersion'].Value,                    # signedKeyVersion
                ($SasParams['signedAuthorizedObjectId'].Value ?? ''),    # signedAuthorizedObjectId (Optional)
                ($SasParams['signedUnauthorizedObjectId'].Value ?? ''),  # signedUnauthorizedObjectId (Optional)
                ($SasParams['signedCorrelationId'].Value ?? ''),         # signedCorrelationId (Optional)
                ($SasParams['signedIP'].Value ?? ''),                    # signedIP (Optional)
                $SasParams['signedProtocol'].Value,                      # signedProtocol (Optional)
                $SasParams['signedVersion'].Value,                       # signedVersion
                $SasParams['signedResource'].Value                       # signedResource
                ($SasParams['signedSnapshotTime'].Value ?? ''),          # signedSnapshotTime (Optional)
                ($SasParams['signedEncryptionScope'].Value ?? ''),       # signedEncryptionScope (Optional)
                ($SasParams['Cache-Control'].Value ?? ''),               # rscc (Optional)
                ($SasParams['Content-Disposition'].Value ?? ''),         # rscd (Optional)
                ($SasParams['Content-Encoding'].Value ?? ''),            # rsce (Optional)
                ($SasParams['Content-Language'].Value ?? ''),            # rscl (Optional)
                ($SasParams['Content-Type'].Value ?? '')                 # rsct (Optional)
            )
        }
        { @('2026-04-06') -contains $_ } {
            @(
                $SasParams['signedPermissions'].Value,                       # signedPermissions
                ($SasParams['signedStart'].Value ?? ''),                     # signedStart (Optional)
                $SasParams['signedExpiry'].Value,                            # signedExpiry
                $canonicalizedResource,                                      # canonicalizedResource
                $SasParams['signedObjectId'].Value,                          # signedObjectId / signedKeyObjectId
                $SasParams['signedTenantId'].Value,                          # signedTenantId / signedKeyTenantId
                $SasParams['signedKeyStartTime'].Value,                      # signedKeyStartTime
                $SasParams['signedKeyExpiryTime'].Value,                     # signedKeyExpiryTime
                $SasParams['signedKeyService'].Value,                        # signedKeyService
                $SasParams['signedKeyVersion'].Value,                        # signedKeyVersion
                ($SasParams['signedAuthorizedObjectId'].Value ?? ''),        # signedAuthorizedObjectId (Optional)
                ($SasParams['signedUnauthorizedObjectId'].Value ?? ''),      # signedUnauthorizedObjectId (Optional)
                ($SasParams['signedCorrelationId'].Value ?? ''),             # signedCorrelationId (Optional)
                ($SasParams['signedKeyDelegatedUserTenantId'].Value ?? ''),  # signedKeyDelegatedUserTenantId (Optional)
                ($SasParams['signedDelegatedUserObjectId'].Value ?? ''),     # signedDelegatedUserObjectId (Optional)
                ($SasParams['signedIP'].Value ?? ''),                        # signedIP (Optional)
                ($SasParams['signedProtocol'].Value ?? ''),                  # signedProtocol (Optional)
                $SasParams['signedVersion'].Value,                           # signedVersion
                $SasParams['signedResource'].Value                           # signedResource
                ($SasParams['signedSnapshotTime'].Value ?? ''),              # signedSnapshotTime (Optional)
                ($SasParams['signedEncryptionScope'].Value ?? ''),           # signedEncryptionScope (Optional)
                ($SasParams['signedRequestHeaders'].Value ?? ''),            # canonicalizedSignedRequestHeaders / signedRequestHeaders (Optional)
                ($SasParams['signedRequestQueryParameters'].Value ?? ''),    # canonicalizedSignedRequestQueryParameters / signedRequestQueryParameters (Optional)
                ($SasParams['Cache-Control'].Value ?? ''),                   # rscc (Optional)
                ($SasParams['Content-Disposition'].Value ?? ''),             # rscd (Optional)
                ($SasParams['Content-Encoding'].Value ?? ''),                # rsce (Optional)
                ($SasParams['Content-Language'].Value ?? ''),                # rscl (Optional)
                ($SasParams['Content-Type'].Value ?? '')                     # rsct (Optional)
            )
        }
        default {
            throw 'Unsupported service version by this script.'
        }
    }
    
    return $stringToSignArray -join "`n"
}

function Get-CanonicalizedResourceInfo {
    param (
        [Parameter(Mandatory = $true)]
        [string] $BlobUrl
    )

    $uri = [uri]$BlobUrl

    $storageAccountName = $uri.Host.Split('.')[0]
    $serviceType = $uri.Host.Split('.')[1]
    $path = $uri.AbsolutePath

    if ($serviceType -eq 'dfs') {
        $serviceType = 'blob'
    }

    if ($serviceType -eq 'table') {
        $path = $path -replace '\(.+\)', ''
    }

    return '/{0}/{1}{2}' -f $serviceType, $storageAccountName, $path
}

function Get-Signature {
    param (
        [Parameter(Mandatory = $true)]
        [string] $Message,

        [Parameter(Mandatory = $true)]
        [string] $SigningKeyBase64
    )

    $messageBytes = [System.Text.Encoding]::UTF8.GetBytes($Message)
    $signingKeyBytes = [System.Convert]::FromBase64String($SigningKeyBase64)

    $hmac = New-Object -TypeName 'System.Security.Cryptography.HMACSHA256'
    $hmac.Key = $signingKeyBytes
    $signatureBytes = $hmac.ComputeHash($messageBytes)
    $signatureBase64 = [System.Convert]::ToBase64String($signatureBytes)
    $hmac.Dispose()

    return [System.Uri]::EscapeDataString($signatureBase64)
}

function Get-SasToken {
    param (
        [Parameter(Mandatory = $true)]
        [System.Collections.Specialized.OrderedDictionary] $SasParams
    )

    $sasTokenParts = foreach ($fieldName in $SasParams.Keys) {
        $sasParams[$fieldName].ParamName + '=' + $sasParams[$fieldName].Value
    }
    return $sasTokenParts -join '&'
}

# Blob
$blobUrl = 'https://account.blob.core.windows.net/con1/test.txt'

# Signed user's tenant ID. Signed user means the user who creates SAS.
$signedUserTenantId = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'

# SAS configuraton
$start = '2026-03-05T08:30:32Z'
$expiry = '2026-03-05T16:45:32Z'

#$serviceVersion = '2024-11-04'
$serviceVersion = '2026-04-06'

# For user-bound user-delegation SAS tokens.
$delegatedEndUserObjectId = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'

#
#

$responseXml = Get-UserDelegationKey -StorageServiceVersion $serviceVersion -blobUrl $blobUrl -Start $start -Expiry $expiry -DelegatedUserTenantId $signedUserTenantId
$userDelegationKey = $responseXml.UserDelegationKey.Value
$sasParams = [ordered]@{
    # SAS
    'signedResource'    = [PSCustomObject]@{ ParamName = 'sr';    Value = 'b' }              # signedResource
    'signedPermissions' = [PSCustomObject]@{ ParamName = 'sp';    Value = 'r' }              # signedPermissions
    'signedProtocol'    = [PSCustomObject]@{ ParamName = 'spr';   Value = 'https' }          # signedProtocol (Optional)
    'signedVersion'     = [PSCustomObject]@{ ParamName = 'sv';    Value = $serviceVersion }  # signedVersion
    'signedStart'       = [PSCustomObject]@{ ParamName = 'st';    Value = $start }           # signedStart (Optional)
    'signedExpiry'      = [PSCustomObject]@{ ParamName = 'se';    Value = $expiry }          # signedExpiry

    # TODO: Test to the following parameters.
    # 'Cache-Control'       = [PSCustomObject]@{ ParamName = '';    Value = 'rscc' }  # rscc (Optional)
    # 'Content-Disposition' = [PSCustomObject]@{ ParamName = '';    Value = 'rscd' }  # rscd (Optional)
    # 'Content-Encoding'    = [PSCustomObject]@{ ParamName = '';    Value = 'rsce' }  # rsce (Optional)
    # 'Content-Language'    = [PSCustomObject]@{ ParamName = '';    Value = 'rscl' }  # rscl (Optional)
    # 'Content-Type'        = [PSCustomObject]@{ ParamName = '';    Value = 'rsct' }  # rsct (Optional)

    # User delegation SAS
    'signedObjectId'      = [PSCustomObject]@{ ParamName = 'skoid'; Value = $responseXml.UserDelegationKey.SignedOid }      # signedObjectId
    'signedTenantId'      = [PSCustomObject]@{ ParamName = 'sktid'; Value = $responseXml.UserDelegationKey.SignedTid }      # signedTenantId
    'signedKeyStartTime'  = [PSCustomObject]@{ ParamName = 'skt';   Value = $responseXml.UserDelegationKey.SignedStart }    # signedKeyStartTime
    'signedKeyExpiryTime' = [PSCustomObject]@{ ParamName = 'ske';   Value = $responseXml.UserDelegationKey.SignedExpiry }   # signedKeyExpiryTime
    'signedKeyService'    = [PSCustomObject]@{ ParamName = 'sks';   Value = $responseXml.UserDelegationKey.SignedService }  # signedKeyService
    'signedKeyVersion'    = [PSCustomObject]@{ ParamName = 'skv';   Value = $responseXml.UserDelegationKey.SignedVersion }  # signedKeyVersion

    # User-bound user delegation SAS
    #'signedDelegatedUserObjectId'    = [PSCustomObject]@{ ParamName = 'sduoid'; Value = $delegatedEndUserObjectId }  # signedDelegatedUserObjectId
    #'signedKeyDelegatedUserTenantId' = [PSCustomObject]@{ ParamName = 'skdutid '; Value = '' }  # signedKeyDelegatedUserTenantId

    # Common
    'signature' = [PSCustomObject]@{ ParamName = 'sig';   Value = '' }  # signature
}

$stringToSign = Get-StringToSign -ServiceVersion $serviceVersion -BlobUrl $blobUrl -SasParams $sasParams
$signature = Get-Signature -Message $stringToSign -SigningKeyBase64 $userDelegationKey
$sasParams['signature'].Value = $signature

$sasToken = Get-SasToken -SasParams $sasParams

$sasUrl = $blobUrl + '?' + $sasToken
Write-Host ('SAS URL: ' + $sasUrl)
