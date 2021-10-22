# Download the File Server Capacity Tool
# https://www.microsoft.com/en-us/download/details.aspx?id=55947

$fsctDownloadUrl = 'https://download.microsoft.com/download/C/B/C/CBC1FB9E-6809-4B30-B81F-D279C63BEBDC/V1.3-64bit.zip'
$fsctFilePath = 'C:\FSCT-V1.3-64bit.zip'

curl.exe -Lo $fsctFilePath $fsctDownloadUrl

Push-Location
Set-Location -LiteralPath ([System.IO.Path]::GetDirectoryName($fsctFilePath))
Expand-Archive -LiteralPath $fsctFilePath 
Pop-Location
