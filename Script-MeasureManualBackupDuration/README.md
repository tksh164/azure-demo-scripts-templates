# Measure the manual backup duration

This script measures the manual backup duration include each subtask by Azure VM backup.

## Example

```
PS > .\MeasureManualBackupDuration.ps1 -RecoveryServicesVaultName backup-vault -BackupItemName vm1
VERBOSE: 2019-06-22 20:45:51: Waiting for the 'Take Snapshot' subtask completion...
VERBOSE: 2019-06-22 20:45:53: Waiting for the 'Take Snapshot' subtask completion...
VERBOSE: 2019-06-22 20:45:55: Waiting for the 'Take Snapshot' subtask completion...
...
VERBOSE: 2019-06-22 20:53:20: Subtask 'Take Snapshot' was completed with 00:07:31.
VERBOSE: 2019-06-22 20:53:21: Waiting for the 'Transfer data to vault' subtask completion...
VERBOSE: 2019-06-22 20:53:23: Waiting for the 'Transfer data to vault' subtask completion...
VERBOSE: 2019-06-22 20:53:26: Waiting for the 'Transfer data to vault' subtask completion...
...
VERBOSE: 2019-06-22 21:06:50: Waiting for the 'Transfer data to vault' subtask completion...
VERBOSE: 2019-06-22 21:06:53: Waiting for the 'Transfer data to vault' subtask completion...
VERBOSE: 2019-06-22 21:06:55: Waiting for the 'Transfer data to vault' subtask completion...
VERBOSE: 2019-06-22 21:06:57: Subtask 'Transfer data to vault' was completed with 00:13:36.

DynamicErrorMessage  :
Properties           : {[VM Name, vm1], [Backup Size, 0 MB]}
SubTasks             : {Take Snapshot, Transfer data to vault}
VmVersion            : Compute
IsCancellable        : False
IsRetriable          : False
ErrorDetails         :
ActivityId           : d46e574e-0452-4b56-b3e7-2c13b9a19d29
JobId                : bedf03d4-2099-47db-9816-d31e61771057
Operation            : Backup
Status               : Completed
WorkloadName         : vm1
StartTime            : 6/22/2019 11:45:43 AM
EndTime              : 6/22/2019 12:06:57 PM
Duration             : 00:21:13.5090264
BackupManagementType : AzureVM



Name     : Take Snapshot
Start    : 6/22/2019 8:45:49 PM
End      : 6/22/2019 8:53:20 PM
Duration : 00:07:31.0306249

Name     : Transfer data to vault
Start    : 6/22/2019 8:53:20 PM
End      : 6/22/2019 9:06:57 PM
Duration : 00:13:36.6140588
```
