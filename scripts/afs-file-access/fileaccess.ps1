param (
    [Parameter(Mandatory = $true)]
    [string] $FilePath,

    [Parameter(Mandatory = $false)]
    [string] $Notes = ''
)

$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop

Add-Type -Language CSharp -TypeDefinition @'
using System;
using System.IO;
using System.ComponentModel;
using System.Runtime.InteropServices;
using Microsoft.Win32.SafeHandles;

public static class Win32Native
{
    [DllImport("kernel32.dll", EntryPoint = "CreateFileW", ExactSpelling = true, CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern SafeFileHandle CreateFile(
        string lpFileName,
        [MarshalAs(UnmanagedType.U4)] FileAccess dwDesiredAccess,
        [MarshalAs(UnmanagedType.U4)] FileShare dwShareMode,
        IntPtr lpSecurityAttributes,
        [MarshalAs(UnmanagedType.U4)] FileMode dwCreationDisposition,
        [MarshalAs(UnmanagedType.U4)] FileAttributes dwFlagsAndAttributes,
        IntPtr hTemplateFile
    );

    const uint FILE_FLAG_OPEN_NO_RECALL = 0x00100000;

    [DllImport("kernel32.dll", EntryPoint = "ReadFile", ExactSpelling = true, SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool ReadFile(
        SafeFileHandle hFile,
        [Out] byte[] lpBuffer,
        [MarshalAs(UnmanagedType.U4)] uint nNumberOfBytesToRead,
        [MarshalAs(UnmanagedType.U4)] out uint lpNumberOfBytesRead,
        IntPtr lpOverlapped
    );

    public static uint ScanAllFileContent(string filePath, bool withNoRecallFlag)
    {
        var flagsAndAttributes = withNoRecallFlag ? (uint)FileAttributes.Normal | FILE_FLAG_OPEN_NO_RECALL : (uint)FileAttributes.Normal;
        using (var fileHandle = CreateFile(filePath, FileAccess.Read, FileShare.Read, IntPtr.Zero, FileMode.Open, (FileAttributes)flagsAndAttributes, IntPtr.Zero))
        {
            var buffer = new byte[4096];
            uint readBytes, totalReadBytes = 0;
            while (true)
            {
                var result = ReadFile(fileHandle, buffer, (uint)buffer.Length, out readBytes, IntPtr.Zero);
                if (!result) throw new Win32Exception(Marshal.GetLastWin32Error(), "ReadFile() failed.");
                if (result && readBytes == 0) break;  // Finish reading.
                totalReadBytes += readBytes;
            }
            return totalReadBytes;
        }
    }
}
'@

$startTimestamp = [DateTime]::Now.ToString('yyyy-MM-dd HH:mm:ss.fff')

$elapsedTime = Measure-Command -Expression {
    $script:totalReadBytes = [Win32Native]::ScanAllFileContent($FilePath, $false)
}

@(
    $startTimestamp,
    $elapsedTime.Days,
    $elapsedTime.Hours,
    $elapsedTime.Minutes,
    $elapsedTime.Seconds,
    $elapsedTime.Milliseconds,
    $script:totalReadBytes,
    $FilePath,
    $Notes
) -join "`t"
