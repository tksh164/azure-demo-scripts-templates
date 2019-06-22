#
# Get a backup item.
#

$recoveryServicesVaultName = 'backup-vault'
$backupItemName = 'vm1'

$vault = Get-AzRecoveryServicesVault -Name $recoveryServicesVaultName
$container = Get-AzRecoveryServicesBackupContainer -VaultId $vault.ID -ContainerType AzureVM -FriendlyName $backupItemName
$item = Get-AzRecoveryServicesBackupItem -VaultId $vault.Id -Container $container -WorkloadType AzureVM

#
# Start the manual backup.
#

$jobStartTime = Get-Date
$jobDetail = Backup-AzRecoveryServicesBackupItem -VaultId $vault.ID -Item $item

#
# Wait for each subtask completion in the backup job.
#

if ($jobDetail.Status -eq 'InProgress')
{
    # Get the current time at started subtask operation.
    $allSubtasksStartTime = Get-Date

    $subtaskNames = 'Take Snapshot', 'Transfer data to vault'
    foreach ($subtaskName in $subtaskNames)
    {
        # Get the current time at started the subtask.
        $subtaskStartTime = Get-Date

        $subtask = $jobDetail.SubTasks.Where({ $_.Name -eq $subtaskName })
        Write-Host ('Waiting for the ''{0}'' subtask completion.' -f $subtask.Name) -NoNewline

        while ($subtask.Status -ne 'Completed')
        {
            Write-Host '.' -NoNewline
            Start-Sleep -Seconds 1
            $job = Get-AzRecoveryServicesBackupJob -VaultId $vault.ID -JobId $jobDetail.JobId 
            $jobDetail = Get-AzRecoveryServicesBackupJobDetail -VaultId $vault.ID -Job $job -WarningAction SilentlyContinue
            $subtask = $jobDetail.SubTasks.Where({ $_.Name -eq $subtaskName })
        }

        # Get the current time at ended the subtask.
        $subtaskEndTime = Get-Date

        Write-Host ''
        Write-Host ('Duration time for ''{0}'' subtask is {1}.' -f $subtaskName, ($subtaskEndTime - $subtaskStartTime).ToString('hh\:mm\:ss'))
    }

    # Get the current time at ended subtask operation.
    $allSubtasksEndTime = Get-Date

    Write-Host ('Duration time for all subtask is {0}.' -f ($allSubtasksEndTime - $allSubtasksStartTime).ToString('hh\:mm\:ss'))
}

#
# Wait for the backup job completion.
#

Write-Host 'Waiting for the job completion.' -NoNewline

while ($jobDetail.Status -ne 'Completed')
{
    Write-Host '.' -NoNewline
    Start-Sleep -Seconds 1
    $job = Get-AzRecoveryServicesBackupJob -VaultId $vault.ID -JobId $jobDetail.JobId 
    $jobDetail = Get-AzRecoveryServicesBackupJobDetail -VaultId $vault.ID -Job $job -WarningAction SilentlyContinue
}

# Get the current time at ended the job.
$jobEndTime = Get-Date

Write-Host ''
Write-Host ('Duration time for the job is {0}.' -f ($jobEndTime - $jobStartTime).ToString('hh\:mm\:ss'))
