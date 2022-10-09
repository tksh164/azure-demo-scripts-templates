param($eventGridEvent, $TriggerMetadata)

$VerbosePreference = [System.Management.Automation.ActionPreference]::Continue

#Write-Verbose -Message ('CONTEXT_SUBSCRIPTION_ID: {0}' -f $env:CONTEXT_SUBSCRIPTION_ID)
#Set-AzContext -Subscription $env:CONTEXT_SUBSCRIPTION_ID | Format-List *
#Get-AzContext | Format-List *

#$eventGridEvent | ConvertTo-Json

#Write-Verbose -Message ('*** $eventGridEvent.data.claims ***')
#$eventGridEvent.data.claims | Format-List *

#Write-Verbose -Message ('*** $eventGridEvent.data.authorization ***')
#$eventGridEvent.data.authorization | Format-List *

#Write-Verbose -Message ('*** $eventGridEvent.data.authorization.evidence ***')
#$eventGridEvent.data.authorization.evidence | Format-List *

$resourceId = $eventGridEvent.data.resourceUri
if ($resourceId -eq $null) {
    Write-Warning -Message 'ResourceId is null.'
    exit
}

# NOTE: Ignore resource types are filtered using the event subscription setting.
# $ignoreResourceTypes = @(
#     'providers/Microsoft.Resources/deployments',
#     'providers/Microsoft.Resources/tags'
# )
# foreach ($case in $ignoreResourceTypes) {
#     if ($resourceId -match $case) {
#         Write-Host 'Skipping event as resourceId contains: $case'
#         exit;
#     }
# }

$tags = (Get-AzTag -ResourceId $resourceId).Properties
if ($tags -eq $null) {
    Write-Warning -Message ('ResourceId {0} could not be found.' -f $resourceId)
    exit
}

$tagNames = @{
    Creator    = 'creator'
    CreatedJst = 'created-jst'
}

if ($tags.TagsProperty -ne $null) {
    foreach ($key in $tagNames.Keys) {
        if ($tags.TagsProperty.ContainsKey($tagNames[$key])) {
            Write-Verbose -Message ('The tag name "{0}" already exists on {1}.' -f $tagNames[$key], $resourceId)
            exit
        }
    }
}

# Retrieve the caller's name or ID.
$caller = $eventGridEvent.data.claims.name
if ($caller -eq $null) {
    if ($eventGridEvent.data.authorization.evidence.principalType -eq 'ServicePrincipal') {
        $caller = (Get-AzADServicePrincipal -ObjectId $eventGridEvent.data.authorization.evidence.principalId -ErrorAction SilentlyContinue).DisplayName
        if ($caller -eq $null) {
            Write-Warning -Message 'MSI may not have permission to read the applications from the directory.'
            $caller = 'SP:{0}' -f $eventGridEvent.data.authorization.evidence.principalId
        }
    }
    else {
        $caller = $eventGridEvent.data.authorization.evidence.principalId
    }
}

Write-Verbose -Message ('Caller: {0}, ResourceId: {1}' -f $caller, $resourceId)

$tagsAdded = @{
    $tagNames.Creator    = $caller
    $tagNames.CreatedJst = $eventGridEvent.eventTime.AddHours(9).ToString('yyyy-MM-dd HH:mm')
    #$tagNames.CreatedJst = (Get-Date).AddHours(9).ToString('yyyyMMdd-HHmm')
    #'created-jst-eg' = $eventGridEvent.eventTime.AddHours(9).ToString('yyyyMMdd-HHmm')
    #$tagNames.CreatedJst = $eventGridEvent.eventTime.AddHours(9).ToString('yyyy-MM-dd HH:mm:ss')
}
[void](Update-AzTag -ResourceId $resourceId -Operation Merge -Tag $tagsAdded)
Write-Verbose -Message ('Added tags to {0}.' -f $resourceId)
