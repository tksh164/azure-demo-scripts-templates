# How to get scheduled events 
function Get-ScheduledEvents
{
    param (
        [string] $Uri
    )

    $scheduledEvents = Invoke-RestMethod -Headers @{"Metadata"="true"} -URI $Uri -Method Get
    $json = ConvertTo-Json $scheduledEvents
    #Write-Host "Received following events: `n" $json
    #return $scheduledEvents
    return $json
}

function Add-ScheduledEventsLog
{
    param (
        [string] $LogFilePath,
        [string] $ScheduledEvents
    )

    Add-Content -LiteralPath $LogFilePath -Value (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') -Encoding UTF8
    Add-Content -LiteralPath $LogFilePath -Value $ScheduledEvents -Encoding UTF8
    Add-Content -LiteralPath $LogFilePath -Value '----------------' -Encoding UTF8
}

# Set up the scheduled events URI for a VNET-enabled VM
$localHostIP = '169.254.169.254'
$scheduledEventURI = 'http://{0}/metadata/scheduledevents?api-version=2017-08-01' -f $localHostIP 

$logFilePath = 'Q:\Work\ScheduledEvents\ScheduledEvents.txt'

while ($true)
{

    # Get events
    $scheduledEvents = Get-ScheduledEvents $scheduledEventURI

    Add-ScheduledEventsLog -LogFilePath $logFilePath -ScheduledEvents $scheduledEvents

    Start-Sleep -Seconds (60 * 5)
}
