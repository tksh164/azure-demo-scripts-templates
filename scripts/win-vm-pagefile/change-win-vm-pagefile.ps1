$vmName = 'vm1'
$rgName = 'vm-b-series'

# Change the page file settings within the Azure VM.

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

$script = @'
Get-CimInstance -ClassName 'Win32_PageFileSetting' | Select-Object -Property Name,InitialSize,MaximumSize,SettingId | ConvertTo-Json -Compress
New-CimInstance -ClassName 'Win32_PageFileSetting' -Property @{ Name = 'C:\pagefile.sys' } | Out-Null
Get-CimInstance -ClassName 'Win32_PageFileSetting' -Filter "Name = 'D:\\pagefile.sys'" | Remove-CimInstance
Get-CimInstance -ClassName 'Win32_PageFileSetting' | Select-Object -Property Name,InitialSize,MaximumSize,SettingId | ConvertTo-Json -Compress
'@
$result = Invoke-AzVMRunCommand -ResourceGroupName $rgName -Name $vmName -CommandId 'RunPowerShellScript' -ScriptString $script -Verbose
$result.Value[0]
$result.Value[1]

$stopWatch.Stop()
$stopWatch.Elapsed.toString('hh\:mm\:ss')

# Restart/Stop the Azure VM.

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

Restart-AzVM -ResourceGroupName $rgName -Name $vmName -Verbose
#Stop-AzVM -ResourceGroupName $rgName -Name $vmName -Verbose

$stopWatch.Stop()
$stopWatch.Elapsed.toString('hh\:mm\:ss')
