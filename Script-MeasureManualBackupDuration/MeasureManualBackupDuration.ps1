#Requires -Version 5.1
#Requires -Modules @{ ModuleName = 'Az.RecoveryServices'; ModuleVersion = '1.4.1' }

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string] $RecoveryServicesVaultName,

    [Parameter(Mandatory = $true)]
    [string] $BackupItemName
)

$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop

function Get-BackupJobSubtask
{
    param (
        [Parameter(Mandatory = $true)]
        [string] $VaultId,

        [Parameter(Mandatory = $true)]
        [string] $JobId,

        [Parameter(Mandatory = $true)]
        [string] $SubtaskName
    )    

    $jobDetail = Get-AzRecoveryServicesBackupJobDetail -VaultId $VaultId -JobId $JobId -WarningAction SilentlyContinue  # Suppress the breaking changes warnings.
    $subtask = $jobDetail.SubTasks.Where({ $_.Name -eq $SubtaskName })
    $subtask
}

function Wait-BackupJobSubtaskCompletion
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $VaultId,

        [Parameter(Mandatory = $true)]
        [string] $JobId,

        [Parameter(Mandatory = $true)]
        [string[]] $SubtaskName
    )    

    $results = @()

    foreach ($currentSubtaskName in $SubtaskName)
    {
        $result = [PSCustomObject] @{
            Name     = $currentSubtaskName
            Start    = Get-Date
            End      = $null
            Duration = $null
        }

        $subtask = Get-BackupJobSubtask -VaultId $VaultId -JobId $JobId -SubtaskName $currentSubtaskName
        while ($subtask.Status -ne 'Completed')
        {
            Write-Verbose -Message ('{0}: Waiting for the ''{1}'' subtask completion...' -f (Get-Date).ToString('yyyy-MM-dd HH:mm:ss'), $currentSubtaskName)
            Start-Sleep -Seconds 1
            $subtask = Get-BackupJobSubtask -VaultId $VaultId -JobId $JobId -SubtaskName $currentSubtaskName
        }

        $result.End = Get-Date
        $result.Duration = $result.End - $result.Start
        $results += $result

        Write-Verbose -Message ('{0}: Subtask ''{1}'' was completed with {2}.' -f (Get-Date).ToString('yyyy-MM-dd HH:mm:ss'), $currentSubtaskName, $result.Duration.ToString('hh\:mm\:ss'))
    }

    ,$results
}

function Wait-BackupJobCompletion
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $VaultId,

        [Parameter(Mandatory = $true)]
        [string] $JobId
    )    

    $jobDetail = Get-AzRecoveryServicesBackupJobDetail -VaultId $VaultId -JobId $JobId -WarningAction SilentlyContinue  # Suppress the breaking changes warnings.

    while ($jobDetail.Status -eq 'InProgress')
    {
        Write-Verbose -Message ('{0}: Waiting for the job completion...' -f (Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))
        Start-Sleep -Seconds 1
        $jobDetail = Get-AzRecoveryServicesBackupJobDetail -VaultId $vault.ID -JobId $jobDetail.JobId -WarningAction SilentlyContinue  # Suppress the breaking changes warnings.
    }

    $jobDetail
}

function Wait-BackupJob
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $VaultId,

        [Parameter(Mandatory = $true)]
        [string] $JobId
    )    

    $jobDetail = Get-AzRecoveryServicesBackupJobDetail -VaultId $VaultId -JobId $JobId -WarningAction SilentlyContinue  # Suppress the breaking changes warnings.

    if ($jobDetail.BackupManagementType -ne [Microsoft.Azure.Commands.RecoveryServices.Backup.Cmdlets.Models.BackupManagementType]::AzureVM)
    {
        throw ('Unsupported backup management type: {0}' -f $jobDetail.BackupManagementType)
    }

    $results = [PSCustomObject] @{
        Job       = $null
        Subtasks  = $null
    }

    if ($jobDetail.Status -eq 'InProgress')
    {
        $results.Subtasks = Wait-BackupJobSubtaskCompletion -VaultId $VaultId -JobId $jobDetail.JobId -SubtaskName 'Take Snapshot','Transfer data to vault'
    }

    $results.Job = Wait-BackupJobCompletion -VaultId $VaultId -JobId $jobDetail.JobId

    $results
}

$vault = Get-AzRecoveryServicesVault -Name $RecoveryServicesVaultName
$container = Get-AzRecoveryServicesBackupContainer -VaultId $vault.ID -ContainerType AzureVM -FriendlyName $BackupItemName
$item = Get-AzRecoveryServicesBackupItem -VaultId $vault.Id -Container $container -WorkloadType AzureVM

$jobDetail = Backup-AzRecoveryServicesBackupItem -VaultId $vault.ID -Item $item
$results = Wait-BackupJob -VaultId $vault.ID -JobId $jobDetail.JobId -Verbose  # TODO remove verbose option.

$results.Job | Format-List -Property '*'
$results.Subtasks | Format-List -Property '*'
