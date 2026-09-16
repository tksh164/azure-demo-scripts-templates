#Requires -Version 7

param (
    [Parameter(Mandatory = $true)]
    [string] $FirewallPolicyResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string] $FirewallPolicyName,

    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -PathType Leaf -LiteralPath $_ })]
    [string] $RuleJsonFilePath
)

$ruleCollectionGroupDefinitions = Get-Content -LiteralPath $RuleJsonFilePath -Raw -Encoding utf8 | ConvertFrom-Json -Depth 10

$ruleCollections = foreach ($ruleCollection in $ruleCollectionGroupDefinitions.RuleCollections) {
    $rules = foreach ($rule in $ruleCollection.Rules) {
        $params = @{
            Name          = $rule.Name
            SourceAddress = $rule.SourceAddress
            Protocol      = $rule.Protocol
            TargetFqdn    = $rule.TargetFqdn
        }
        New-AzFirewallPolicyApplicationRule @params
    }

    $params = @{
        Name       = $ruleCollection.Name
        Priority   = $ruleCollection.Priority
        ActionType = $ruleCollection.ActionType
        Rule       = $rules
    }
    New-AzFirewallPolicyFilterRuleCollection @params
}

$params = @{
    ResourceGroupName  = $firewallPolicyResourceGroupName
    FirewallPolicyName = $firewallPolicyName
    Name               = $ruleCollectionGroupDefinitions.Name
    Priority           = $ruleCollectionGroupDefinitions.Priority
    RuleCollection     = $ruleCollections
}
$ruleCollectionGroup = New-AzFirewallPolicyRuleCollectionGroup @params

$ruleCollectionGroup
