param (
    [Parameter(Mandatory = $true)]
    [string] $ActionToFind,

    [Parameter(Mandatory = $false)]
    [string] $Scope = '/'
)

Get-AzRoleDefinition -Scope $Scope | ForEach-Object -Process {
    $roleDefinition = $_
    $isInActions = $false
    $isInNotActions = $false

    foreach ($action in $roleDefinition.Actions) {
        if ($ActionToFind -like $action) {
            $isInActions = $true
            break
        }
    }

    foreach ($notAction in $roleDefinition.NotActions) {
        if ($ActionToFind -like $notAction) {
            $isInNotActions = $true
            break
        }
    }

    if ($isInActions -and (-not $isInNotActions)) {
        [PSCustomObject] @{
            Name             = $roleDefinition.Name
            Id               = $roleDefinition.Id
            Description      = $roleDefinition.Description
            IsCustom         = $roleDefinition.IsCustom
            AssignableScopes = $roleDefinition.AssignableScopes.ToArray()
            Actions          = $roleDefinition.Actions.ToArray()
            NotActions       = $roleDefinition.NotActions.ToArray()
            DataActions      = $roleDefinition.DataActions.ToArray()
            NotDataActions   = $roleDefinition.NotDataActions.ToArray()
        }
    }
}
