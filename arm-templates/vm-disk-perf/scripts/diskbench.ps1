#Requires -Version 7

param (
    [Parameter(Mandatory = $true)]
    [string] $ConfigFilePath,

    [Parameter(Mandatory = $true)]
    [string[]] $BenchmarkConfigFilePath,

    [Parameter(Mandatory = $false)]
    [int] $IntervalSeconds = 30
)

function Invoke-Webhook {
    param (
        [Parameter(Mandatory = $true)]
        [string] $Method,

        [Parameter(Mandatory = $true)]
        [string] $Url,

        [Parameter(Mandatory = $false)]
        [string] $Body
    )

    $params = @{
        Method      = $Method
        Uri         = $Url
        ContentType = 'application/json'
    }
    if ($PSBoundParameters.ContainsKey('Body')) {
        $params.Body = $Body
    }
    $result = Invoke-WebRequest @params
    Write-Host ('Webhook: {0} {1}' -f $result.StatusCode, $result.StatusDescription)
    Write-Verbose -Message $Body
}

function Invoke-DiskBenchmark
{
    param (
        [Parameter(Mandatory = $true)]
        [string] $ConfigFilePath
    )

    $config = Get-Content -LiteralPath $ConfigFilePath -Raw -Encoding utf8 | ConvertFrom-Json

    $timestamp = [datetime]::Now.ToString('yyyyMMdd-HHmmss')
    $outputFileExtension = [IO.Path]::GetExtension($config.outputFilePath)

    $params = @{
        FilePath               = $config.diskspdPath
        ArgumentList           = $config.diskspdArgs
        RedirectStandardOutput = $config.outputFilePath.Replace($outputFileExtension, ('-' + $timestamp + $outputFileExtension))
        NoNewWindow            = $true
        Wait                   = $true
    }
    Start-Process @params

    if ($config.webhook) {
        $params = @{
            Method = $config.webhook.method
            Url    = $config.webhook.url
        }
        if ($config.webhook.body) {
            $params.Body = ($config.webhook.body | ConvertTo-Json).Replace('{{datetime}}', [datetime]::Now.ToString('yyyy-MM-dd HH:mm:ss'))
        }
        Invoke-Webhook @params
    }
}

$config = Get-Content -LiteralPath $ConfigFilePath -Raw -Encoding utf8 | ConvertFrom-Json

if ($config.webhook) {
    $params = @{
        Method = $config.webhook.method
        Url    = $config.webhook.url
    }
    if ($config.webhook.bodyForStart) {
        $params.Body = ($config.webhook.bodyForStart | ConvertTo-Json).Replace('{{datetime}}', [datetime]::Now.ToString('yyyy-MM-dd HH:mm:ss'))
    }
    Invoke-Webhook @params
}

for ($i = 0; $i -lt $BenchmarkConfigFilePath.Length; $i++) {
    if ($i -ne 0) {
        Write-Host ('Waiting {0} seconds for the next benchmark invoking...' -f $IntervalSeconds)
        Start-Sleep -Seconds $IntervalSeconds
    }

    Write-Host ('Invoke benchmark with {0}' -f $BenchmarkConfigFilePath[$i])
    Invoke-DiskBenchmark -ConfigFilePath $BenchmarkConfigFilePath[$i]
}

if ($config.webhook) {
    $params = @{
        Method = $config.webhook.method
        Url    = $config.webhook.url
    }
    if ($config.webhook.bodyForEnd) {
        $params.Body = ($config.webhook.bodyForEnd | ConvertTo-Json).Replace('{{datetime}}', [datetime]::Now.ToString('yyyy-MM-dd HH:mm:ss'))
    }
    Invoke-Webhook @params
}
