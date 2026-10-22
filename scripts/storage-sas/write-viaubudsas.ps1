#Requires -Version 7

param (
    [Parameter(Mandatory = $true)]
    [string] $SasUrl,

    [Parameter(Mandatory = $false)]
    [string] $Content = '{0} - The blob content.' -f (Get-Date)
)

$token = (Get-AzAccessToken -ResourceTypeName Storage).Token
$params = @{
    Method         = 'Put'
    Uri            = $SasUrl
    Authentication = 'Bearer'
    Token          = $token
    Headers        = @{
        'x-ms-blob-type' = 'BlockBlob'
        'x-ms-version'   = '2026-04-06'
    }
    ContentType = 'text/plain; charset=utf-8'
    Body        = $Content
}
Invoke-RestMethod @params
