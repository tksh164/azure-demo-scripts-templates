#Requires -Version 7

param (
    [Parameter(Mandatory = $true)]
    [string] $SasUrl
)

$token = (Get-AzAccessToken -ResourceTypeName Storage).Token
$response = Invoke-RestMethod -Method Get -Uri $SasUrl -Authentication Bearer -Token $token
$response
