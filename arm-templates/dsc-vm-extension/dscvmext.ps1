configuration install-windows-feature
{
    param (
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]
        $FeatureNameList
    )

    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'

    node localhost
    {
        WindowsFeatureSet windows-features
        {
            Ensure = 'Present'
            Name   = $FeatureNameList.ToArray()
        }
    }
}

configuration download-file
{
    param (
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]
        $UrlList,

        [Parameter(Mandatory = $true)]
        [string]
        $DownloadFolderPath
    )

    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'

    node localhost
    {
        File create-folder
        {
            DestinationPath = $DownloadFolderPath
            Type            = 'Directory'
            Ensure          = 'Present'
        }

        Script download-file
        {
            GetScript = {
                @{ Result = 'GetScript reuslt' }
            }

            TestScript = {
                $result = $true
                foreach ($url in $using:UrlList) {
                    Write-Verbose -Message ('URL: {0}' -f $url)

                    $tempFilePath = Join-Path -Path $using:DownloadFolderPath -ChildPath (New-Guid).Guid.ToString()
                    Write-Verbose -Message ('TempFilePath: {0}' -f $tempFilePath)

                    $response = Invoke-WebRequest -Method Head -Uri $url -OutFile $tempFilePath -UseBasicParsing -PassThru
                    Remove-Item -LiteralPath $tempFilePath -Force
                    Write-Verbose -Message ('StatusCode: {0}' -f $response.StatusCode)

                    $downloadedFileName =
                        if ($response.Headers.ContainsKey('Content-Disposition') -and
                            ($response.Headers['Content-Disposition'] -match '.*filename=(.+)')) {
                            $Matches[1]
                        } else {
                            $uri = [Uri]$url
                            $uri.Segments[$uri.Segments.Length - 1]
                        }
                    Write-Verbose -Message ('DownloadedFileName: {0}' -f $downloadedFileName)
                    
                    $donwnloadedFilePath = Join-Path -Path $using:DownloadFolderPath -ChildPath $downloadedFileName
                    $result = $result -and (Test-Path -PathType Leaf -LiteralPath $donwnloadedFilePath)
                    if ($result) {
                        Write-Verbose -Message ('The "{0}" had already downloaded.' -f $donwnloadedFilePath)
                    } else {
                        Write-Verbose -Message ('The "{0}" had not download yet.' -f $donwnloadedFilePath)
                    }
                }
                $result
            }

            SetScript = {
                foreach ($url in $using:UrlList) {
                    Write-Verbose -Message ('URL: {0}' -f $url)

                    $tempFilePath = Join-Path -Path $using:DownloadFolderPath -ChildPath (New-Guid).Guid.ToString()
                    Write-Verbose -Message ('TempFilePath: {0}' -f $tempFilePath)

                    $response = Invoke-WebRequest -Method Get -Uri $url -OutFile $tempFilePath -UseBasicParsing -PassThru
                    Write-Verbose -Message ('StatusCode: {0}' -f $response.StatusCode)

                    $downloadedFileName =
                        if ($response.Headers.ContainsKey('Content-Disposition') -and
                            ($response.Headers['Content-Disposition'] -match '.*filename=(.+)')) {
                            $Matches[1]
                        } else {
                            $uri = [Uri]$url
                            $uri.Segments[$uri.Segments.Length - 1]
                        }
                    Write-Verbose -Message ('DownloadedFileName: {0}' -f $downloadedFileName)
                    
                    # Delete the file if the file already exist then rename the new file.
                    $donwnloadedFilePath = Join-Path -Path $using:DownloadFolderPath -ChildPath $downloadedFileName
                    if (Test-Path -PathType Leaf -LiteralPath $donwnloadedFilePath)
                    {
                        Remove-Item -LiteralPath $donwnloadedFilePath -Force
                    }
                    Rename-Item -Path $tempFilePath -NewName $downloadedFileName
                }
            }
            DependsOn = '[File]create-folder'
        }
    }
}

configuration raw-configuration
{
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $RawConfig
    )

    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Invoke-Expression -Command $RawConfig
}
