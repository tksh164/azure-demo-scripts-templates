[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft\.Compute/hostGroups/[^/]+/hosts/[^/]+$')]
    [string] $HostId
)

$ErrorActionPreference = 'Stop'

Write-Host "Searching for virtual machines on Dedicated Host '$HostId'..."
$virtualMachines = @(
    Get-AzVM | Where-Object -FilterScript {
        ($_.Host.Id -ne $null) -and ($_.Host.Id.Equals($HostId, [System.StringComparison]::OrdinalIgnoreCase))
    }
)

if ($virtualMachines.Count -eq 0) {
    Write-Host 'No virtual machines were found on the specified Dedicated Host.'
    return
}

Write-Host "Found $($virtualMachines.Count) virtual machine(s):"
$virtualMachines |
    Sort-Object ResourceGroupName, Name |
    Format-Table Name, ResourceGroupName, Location -AutoSize |
    Out-Host

$failures = [System.Collections.Generic.List[object]]::new()

foreach ($virtualMachine in $virtualMachines) {
    $vmTarget = "$($virtualMachine.ResourceGroupName)/$($virtualMachine.Name)"

    try {
        Write-Host "Deleting '$vmTarget'..."
        Remove-AzVM -ResourceGroupName $virtualMachine.ResourceGroupName -Name $virtualMachine.Name -Force -NoWait | Out-Null

        Write-Host "Deleted '$vmTarget'."
    }
    catch {
        $failures.Add([PSCustomObject] @{
            VirtualMachine = $vmTarget
            Error          = $_.Exception.Message
        })
        Write-Error "Failed to process '$vmTarget': $($_.Exception.Message)" -ErrorAction Continue
    }
}

if ($failures.Count -gt 0) {
    $failures | Format-Table -AutoSize | Out-Host
    throw "$($failures.Count) virtual machine(s) could not be deleted."
}

Write-Host 'All selected virtual machines were deallocated and deleted successfully.'
