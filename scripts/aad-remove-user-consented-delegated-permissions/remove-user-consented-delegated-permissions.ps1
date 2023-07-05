#requires -Modules @{ ModuleName = 'Microsoft.Graph.Authentication'; ModuleVersion = '1.28.0' }
#requires -Modules @{ ModuleName = 'Microsoft.Graph.Identity.SignIns'; ModuleVersion = '1.28.0' }

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, HelpMessage = 'The object ID of the service principal that has delegated permission grants.')]
    [guid] $ServicePrincipalObjectId,

    [Parameter(Mandatory = $true, HelpMessage = 'The object ID of the user principal that granted delegated permissions to the service principal.')]
    [guid] $UserPrincipalObjectId,

    [Parameter(Mandatory = $false, HelpMessage = 'The Azure AD tenant ID that has the target service principal and user principal.')]
    [guid] $TenantId
)

# Sign-in
$params = @{
    TenantId = $TenantId.ToString()
    Scopes   = @(
        'DelegatedPermissionGrant.ReadWrite.All'  # List and delete delegated permission grants.
    )
}
Connect-MgGraph @params

# Get all consented delegated permission grants of the service principal by the user.
$params = @{
    Filter = '(clientId eq ''{0}'') and (principalId eq ''{1}'')' -f $ServicePrincipalObjectId.ToString(), $UserPrincipalObjectId.ToString()
    All    = $true
}
$permissionGrantsForUserPrincipal = Get-MgOAuth2PermissionGrant @params

# Delete all consented delegated permission grants of the service principal by the user.
$permissionGrantsForUserPrincipal | Foreach-Object -Process {
    Remove-MgOAuth2PermissionGrant -OAuth2PermissionGrantId $_.Id
}

# Sign-out
Disconnect-MgGraph
