using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

Write-Host "*** PowerShell HTTP trigger function processed a request ***"

$response = [HttpResponseContext] @{
    StatusCode = [HttpStatusCode]::OK
    Body = '--- $Request.Headers ---' + "`n" +
           'Client IP: {0}' -f $Request.Headers.'client-ip' + "`n" +
           'x-forwarded-for: {0}' -f $request.Headers.'x-forwarded-for' + "`n" +
           'user-agent: {0}' -f $Request.Headers.'user-agent' + "`n" +
           "`n" +
           '--- $TriggerMetadata.Request.Headers ---' + "`n" +
           'Client IP: {0}' -f $TriggerMetadata.Request.Headers.'client-ip' + "`n" +
           'x-forwarded-for: {0}' -f $TriggerMetadata.Request.Headers.'x-forwarded-for' + "`n" +
           'user-agent: {0}' -f $TriggerMetadata.Request.Headers.'user-agent' + "`n" +
           "`n" +
           '--- $TriggerMetadata.$request.Headers ---' + "`n" +
           'Client IP: {0}' -f $TriggerMetadata.'$request'.Headers.'client-ip' + "`n" +
           'x-forwarded-for: {0}' -f $TriggerMetadata.'$request'.Headers.'x-forwarded-for' + "`n" +
           'user-agent: {0}' -f $TriggerMetadata.'$request'.Headers.'user-agent'

}
Push-OutputBinding -Name Response -Value $response
