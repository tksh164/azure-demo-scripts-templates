using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

Write-Host "---- PowerShell HTTP trigger function processed a request ----"

$responseBody = @(
    [PSCustomObject] @{
        'client-ip'       = $Request.Headers.'client-ip'
        'x-forwarded-for' = $request.Headers.'x-forwarded-for'
        'user-agent'      = $Request.Headers.'user-agent'
        'dataSource'      = '$Request.Headers'
    },
    [PSCustomObject] @{
        'client-ip'       = $TriggerMetadata.Request.Headers.'client-ip'
        'x-forwarded-for' = $TriggerMetadata.Request.Headers.'x-forwarded-for'
        'user-agent'      = $TriggerMetadata.Request.Headers.'user-agent'
        'dataSource'      = '$TriggerMetadata.Request.Headers'
    },
    [PSCustomObject] @{
        'client-ip'       = $TriggerMetadata.'$request'.Headers.'client-ip'
        'x-forwarded-for' = $TriggerMetadata.'$request'.Headers.'x-forwarded-for'
        'user-agent'      = $TriggerMetadata.'$request'.Headers.'user-agent'
        'dataSource'      = '$TriggerMetadata.$request.Headers'
    }
)

$response = [HttpResponseContext] @{
    StatusCode = [HttpStatusCode]::OK
    Body       = $responseBody | ConvertTo-Json
}
Push-OutputBinding -Name Response -Value $response
