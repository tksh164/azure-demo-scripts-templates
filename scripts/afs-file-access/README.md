# File access script for Azure File Sync

## Background

File accesses to tiered files from PowerShell scripts/.NET apps that will not cause recall because [Get-Content](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/get-content) cmdlet and [FileStream](https://docs.microsoft.com/en-us/dotnet/api/system.io.filestream) class are add the [FILE_FLAG_OPEN_NO_RECALL](https://docs.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-createfilew) flag to CreateFile call internally.

## This script

This script for test for the cloud tiering feature of Azure File Sync. This script use P/Invoke in the PowerShell script. You can control with/without FILE_FLAG_OPEN_NO_RECALL flag for CreateFile.

```powershell
# Without FILE_FLAG_OPEN_NO_RECALL flag. The file will recall.
[Win32Native]::ScanAllFileContent($filePath, $false)

# With FILE_FLAG_OPEN_NO_RECALL flag. The file will not recall.
[Win32Native]::ScanAllFileContent($filePath, $true)
```

## Examples

```powershell
PS C:\> .\fileaccess.ps1 -FilePath '\\dc-vm1\group1\5gb-01.dat'
2021-07-27 02:13:57.163 0       0       1       13      540     1073741824      \\dc-vm1\group1\5gb-01.dat
```

You can add the notes for the test using Notes parameter also.

```powershell
PS C:\> .\fileaccess.ps1 -FilePath '\\dc-vm1\group1\5gb-01.dat' -Notes 'Test case 1a'
2021-07-27 02:13:57.163 0       0       1       13      540     1073741824      \\dc-vm1\group1\5gb-01.dat      Test case 1a
```

The result output as TSV format, so you can redirect the result of multiple tests to a TSV file. The TSV file easily summarize in Excel.

```powershell
PS C:\> .\fileaccess.ps1 -FilePath '\\dc-vm1\group1\5gb-01.dat' -Notes 'Test case 1b' >> results.tsv
```
