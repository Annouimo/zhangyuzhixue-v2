[CmdletBinding()]
param(
    [ValidateSet('Quick', 'StudentData', 'StudentUi', 'StudentIntegration', 'Golden', 'Student', 'Server', 'E2E', 'All')]
    [string]$Suite = 'Quick',

    [string]$FlutterPath = '',

    [string]$PythonPath = 'python',

    [switch]$UpdateGoldens
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$logRoot = Join-Path $repoRoot '.hermes\tmp\test-logs'
$lockPath = Join-Path $repoRoot '.hermes\tmp\test-runner.lock'
New-Item -ItemType Directory -Force -Path $logRoot | Out-Null

if (-not $FlutterPath) {
    $flutterCommand = Get-Command flutter -ErrorAction SilentlyContinue
    if ($flutterCommand) {
        $FlutterPath = $flutterCommand.Source
    } elseif (Test-Path 'D:\Programs\flutter\bin\flutter.bat') {
        $FlutterPath = 'D:\Programs\flutter\bin\flutter.bat'
    }
}

$lockStream = $null
try {
    $lockStream = [System.IO.File]::Open(
        $lockPath,
        [System.IO.FileMode]::OpenOrCreate,
        [System.IO.FileAccess]::ReadWrite,
        [System.IO.FileShare]::None
    )
} catch {
    throw 'Another project test run is active. Wait for it to finish before starting Flutter again.'
}

function Invoke-TestProcess {
    param(
        [string]$Name,
        [string]$FilePath,
        [string[]]$Arguments,
        [string]$WorkingDirectory,
        [int]$TimeoutMinutes
    )

    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $stdoutPath = Join-Path $logRoot "$stamp-$Name.stdout.log"
    $stderrPath = Join-Path $logRoot "$stamp-$Name.stderr.log"
    $argumentLine = ($Arguments | ForEach-Object {
        if ($_ -match '[\s"]') { '"' + ($_ -replace '"', '\"') + '"' } else { $_ }
    }) -join ' '

    Write-Host "[$Name] Starting in $WorkingDirectory"
    Write-Host "[$Name] Logs: $stdoutPath"

    $processOptions = @{
        FilePath = $FilePath
        ArgumentList = $argumentLine
        WorkingDirectory = $WorkingDirectory
        RedirectStandardOutput = $stdoutPath
        RedirectStandardError = $stderrPath
        NoNewWindow = $true
        PassThru = $true
    }
    $process = Start-Process @processOptions
    $null = $process.Handle

    if (-not $process.WaitForExit($TimeoutMinutes * 60 * 1000)) {
        try { $process.Kill($true) } catch { Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue }
        Write-Host "[$Name] Timed out after $TimeoutMinutes minutes." -ForegroundColor Red
        Get-Content $stdoutPath -Tail 80 -ErrorAction SilentlyContinue | ForEach-Object { Write-Host $_ }
        Get-Content $stderrPath -Tail 80 -ErrorAction SilentlyContinue | ForEach-Object { Write-Host $_ }
        return 124
    }

    # Flush redirected output and refresh ExitCode after the timed wait.
    $process.WaitForExit()
    $process.Refresh()
    $exitCode = $process.ExitCode

    Get-Content $stdoutPath -ErrorAction SilentlyContinue | ForEach-Object { Write-Host $_ }
    Get-Content $stderrPath -ErrorAction SilentlyContinue | ForEach-Object { Write-Host $_ }
    Write-Host "[$Name] Exit code: $exitCode"
    return $exitCode
}

function Invoke-FlutterSuite {
    param(
        [string]$Name,
        [string]$WorkingDirectory,
        [string[]]$TestArguments,
        [int]$TimeoutMinutes
    )

    if (-not $FlutterPath -or -not (Test-Path $FlutterPath)) {
        throw 'Flutter was not found. Pass -FlutterPath or add Flutter to PATH.'
    }

    $env:FLUTTER_SUPPRESS_ANALYTICS = 'true'
    $processOptions = @{
        Name = $Name
        FilePath = $FlutterPath
        Arguments = @('--no-version-check', 'test') + $TestArguments
        WorkingDirectory = $WorkingDirectory
        TimeoutMinutes = $TimeoutMinutes
    }
    return Invoke-TestProcess @processOptions
}

function Invoke-FlutterAnalyze {
    param(
        [string]$Name,
        [string]$WorkingDirectory
    )

    if (-not $FlutterPath -or -not (Test-Path $FlutterPath)) {
        throw 'Flutter was not found. Pass -FlutterPath or add Flutter to PATH.'
    }

    $env:FLUTTER_SUPPRESS_ANALYTICS = 'true'
    $processOptions = @{
        Name = $Name
        FilePath = $FlutterPath
        Arguments = @('--no-version-check', 'analyze')
        WorkingDirectory = $WorkingDirectory
        TimeoutMinutes = 10
    }
    return Invoke-TestProcess @processOptions
}

$studentDir = Join-Path $repoRoot 'flutter_app'
$serverDir = Join-Path $repoRoot 'server'
$pytestCacheDir = Join-Path $repoRoot '.hermes\tmp\pytest-cache'
$pytestBaseTemp = Join-Path $repoRoot '.hermes\tmp\pytest-temp'
$results = [ordered]@{}

function Invoke-ServerSuite {
    New-Item -ItemType Directory -Force -Path (Join-Path $serverDir 'staticfiles') | Out-Null
    New-Item -ItemType Directory -Force -Path $pytestCacheDir | Out-Null
    New-Item -ItemType Directory -Force -Path $pytestBaseTemp | Out-Null

    $options = @{
        Name = 'server-flake8'
        FilePath = $PythonPath
        Arguments = @('-m', 'flake8', '--config', '.flake8')
        WorkingDirectory = $serverDir
        TimeoutMinutes = 5
    }
    $exitCode = Invoke-TestProcess @options
    if ($exitCode -ne 0) { return $exitCode }

    $options = @{
        Name = 'server-migrations'
        FilePath = $PythonPath
        Arguments = @('manage.py', 'makemigrations', '--check')
        WorkingDirectory = $serverDir
        TimeoutMinutes = 5
    }
    $exitCode = Invoke-TestProcess @options
    if ($exitCode -ne 0) { return $exitCode }

    $options = @{
        Name = 'server-pytest'
        FilePath = $PythonPath
        Arguments = @(
            '-m', 'pytest', '-v', '--tb=short',
            '-o', "cache_dir=$pytestCacheDir",
            '--basetemp', $pytestBaseTemp
        )
        WorkingDirectory = $serverDir
        TimeoutMinutes = 10
    }
    return Invoke-TestProcess @options
}

try {
    switch ($Suite) {
        'Quick' {
            $smokeTests = @(
                'test/data/api/api_client_test.dart',
                'test/data/database/database_provider_test.dart',
                'test/data/sync/sync_pusher_test.dart',
                'test/pages/login_page_test.dart',
                'test/support/ui_test_harness_test.dart',
                'test/widget_test.dart'
            )
            $options = @{
                Name = 'student-quick'
                WorkingDirectory = $studentDir
                TestArguments = $smokeTests + @('--tags', 'smoke', '--reporter', 'expanded', '--timeout', '2m', '--concurrency', '1')
                TimeoutMinutes = 5
            }
            $results.StudentQuick = Invoke-FlutterSuite @options
        }
        'StudentData' {
            $options = @{
                Name = 'student-data'
                WorkingDirectory = $studentDir
                TestArguments = @('test/data', '--reporter', 'expanded', '--timeout', '2m', '--concurrency', '1')
                TimeoutMinutes = 15
            }
            $results.StudentData = Invoke-FlutterSuite @options
        }
        'StudentUi' {
            $options = @{
                Name = 'student-ui'
                WorkingDirectory = $studentDir
                TestArguments = @('test/pages', 'test/widgets', 'test/support', 'test/widget_test.dart', '--reporter', 'expanded', '--timeout', '2m', '--concurrency', '1')
                TimeoutMinutes = 20
            }
            $results.StudentUi = Invoke-FlutterSuite @options
        }
        'StudentIntegration' {
            $options = @{
                Name = 'student-integration'
                WorkingDirectory = $studentDir
                TestArguments = @('test/data/integration', '--tags', 'integration', '--reporter', 'expanded', '--timeout', '2m', '--concurrency', '1')
                TimeoutMinutes = 10
            }
            $results.StudentIntegration = Invoke-FlutterSuite @options
        }
        'Golden' {
            $goldenArguments = @(
                'test/golden/student_ui_golden_test.dart',
                '--tags', 'golden',
                '--reporter', 'expanded',
                '--timeout', '2m',
                '--concurrency', '1'
            )
            if ($UpdateGoldens) {
                $goldenArguments += '--update-goldens'
            }
            $goldenName = 'student-golden'
            if ($UpdateGoldens) {
                $goldenName = 'student-golden-update'
            }
            $options = @{
                Name = $goldenName
                WorkingDirectory = $studentDir
                TestArguments = $goldenArguments
                TimeoutMinutes = 10
            }
            $results.StudentGolden = Invoke-FlutterSuite @options
        }
        'Student' {
            $results.StudentAnalyze = Invoke-FlutterAnalyze -Name 'student-analyze' -WorkingDirectory $studentDir
            if ($results.StudentAnalyze -eq 0) {
                $options = @{
                    Name = 'student'
                    WorkingDirectory = $studentDir
                    TestArguments = @('--exclude-tags', 'golden', '--reporter', 'expanded', '--timeout', '2m', '--concurrency', '1')
                    TimeoutMinutes = 25
                }
                $results.Student = Invoke-FlutterSuite @options
            }
        }
        'Server' {
            $results.Server = Invoke-ServerSuite
        }
        'E2E' {
            $options = @{
                Name = 'windows-e2e'
                WorkingDirectory = $studentDir
                TestArguments = @('integration_test/windows_smoke_test.dart', '-d', 'windows', '--tags', 'integration', '--reporter', 'expanded', '--timeout', '5m')
                TimeoutMinutes = 15
            }
            $results.E2E = Invoke-FlutterSuite @options
        }
        'All' {
            $results.StudentAnalyze = Invoke-FlutterAnalyze -Name 'student-analyze' -WorkingDirectory $studentDir
            if ($results.StudentAnalyze -eq 0) {
                $results.Student = Invoke-FlutterSuite -Name 'student' -WorkingDirectory $studentDir -TestArguments @('--exclude-tags', 'golden', '--reporter', 'expanded', '--timeout', '2m', '--concurrency', '1') -TimeoutMinutes 25
            }
            $results.Server = Invoke-ServerSuite
        }
    }
} finally {
    if ($lockStream) { $lockStream.Dispose() }
}

Write-Host ''
Write-Host 'Test summary'
$results.GetEnumerator() | ForEach-Object { Write-Host ("  {0}: {1}" -f $_.Key, $_.Value) }

if (($results.Values | Where-Object { $_ -ne 0 }).Count -gt 0) {
    exit 1
}
