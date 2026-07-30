[CmdletBinding()]
param(
    [ValidateSet('Small', 'Normal', 'Large')]
    [string]$DataScale = 'Normal',

    [ValidateRange(3, 20)]
    [int]$Runs = 3,

    [string]$InputDirectory = '',

    [string]$OutputPath = ''
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if (-not $InputDirectory) {
    $InputDirectory = Join-Path $repoRoot '.hermes\tmp\performance'
}
if (-not $OutputPath) {
    $OutputPath = Join-Path $repoRoot "performance\baselines\$($DataScale.ToLowerInvariant()).json"
}

$reports = @()
$candidateFiles = @(
    Get-ChildItem -LiteralPath $InputDirectory -Filter 'performance-*.json' -File |
        Where-Object { $_.Name -ne 'performance-latest.json' } |
        Sort-Object LastWriteTime -Descending
)
foreach ($file in $candidateFiles) {
    $report = Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json
    $hotRun3Count = @(
        $report.trace.events |
            Where-Object { $_.category -eq 'journey' -and $_.name -like '*_hot_3' }
    ).Count
    if ($report.environment.dataScale -eq $DataScale -and
        -not $report.failure -and
        $report.summary.status -ne 'FAIL' -and
        $hotRun3Count -ge 4) {
        $reports += [pscustomobject]@{ File = $file; Report = $report }
        if ($reports.Count -ge $Runs) { break }
    }
}

if ($reports.Count -lt $Runs) {
    throw "Need $Runs successful $DataScale reports in $InputDirectory; found $($reports.Count)."
}

function Get-Median([double[]]$Values) {
    $ordered = @($Values | Sort-Object)
    $middle = [math]::Floor($ordered.Count / 2)
    if ($ordered.Count % 2 -eq 1) { return $ordered[$middle] }
    return ($ordered[$middle - 1] + $ordered[$middle]) / 2
}

$journeyNames = @(
    $reports[0].Report.trace.events |
        Where-Object category -eq 'journey' |
        ForEach-Object name
)
$journeys = [ordered]@{}
foreach ($name in $journeyNames) {
    $durations = @(
        foreach ($entry in $reports) {
            $event = $entry.Report.trace.events |
                Where-Object { $_.category -eq 'journey' -and $_.name -eq $name } |
                Select-Object -First 1
            if (-not $event) { throw "Journey '$name' is missing from $($entry.File.Name)." }
            [double]$event.durationMs
        }
    )
    $journeys[$name] = [ordered]@{
        durationMs = [math]::Round((Get-Median $durations), 2)
    }
}

$baseline = [ordered]@{
    schemaVersion = 1
    generatedAt = (Get-Date).ToUniversalTime().ToString('o')
    platform = 'windows'
    mode = 'profile'
    dataScale = $DataScale
    aggregation = 'median'
    runCount = $Runs
    sourceFiles = @($reports | ForEach-Object { $_.File.Name })
    journeys = $journeys
}

$parent = Split-Path -Parent $OutputPath
New-Item -ItemType Directory -Force -Path $parent | Out-Null
$json = $baseline | ConvertTo-Json -Depth 8
[System.IO.File]::WriteAllText(
    $OutputPath,
    ($json -replace "`r`n", "`n") + "`n",
    [System.Text.UTF8Encoding]::new($false)
)
Write-Host "Baseline written to $OutputPath"
