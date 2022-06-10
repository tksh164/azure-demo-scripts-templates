param (
    [Parameter(Mandatory = $true)]
    [string] $StoreFolderPath,

    [Parameter(Mandatory = $true)]
    [uint64] $FileSize,

    [Parameter(Mandatory = $true)]
    [uint64] $NumOfFileCreating
)

$timeStarted = [datetime]::Now
for ([uint64] $numOfFileCreated = 0; $numOfFileCreated -lt $NumOfFileCreating; $numOfFileCreated++)
{
    $filePath = Join-Path -Path $StoreFolderPath -ChildPath (New-Guid).Guid
    [void] (fsutil file createnew $filePath $FileSize)
    Write-Progress -Activity 'Creating files...' -Status ('Created: {0}/{1}, Elapsed: {2}' -f $numOfFileCreated, $NumOfFileCreating, ([datetime]::Now - $timeStarted))

}

Write-Host ('Created: {0}/{1}' -f $numOfFileCreated, $NumOfFileCreating)
[datetime]::Now - $timeStarted
