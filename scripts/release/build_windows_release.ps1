[CmdletBinding()]
param(
    [switch]$Build,
    [switch]$AllowDirty
)

$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$flutter = "D:\Programs\flutter\bin\flutter.bat"
$iscc = "D:\Programs\Inno Setup 7\ISCC.exe"
$distRoot = Join-Path $repoRoot "dist\windows"

function Invoke-CheckedCommand {
    param([string]$Executable, [string[]]$Arguments, [string]$WorkingDirectory = $repoRoot)
    Push-Location $WorkingDirectory
    try {
        & $Executable @Arguments
        if ($LASTEXITCODE -ne 0) { throw "$Executable failed with exit code $LASTEXITCODE" }
    }
    finally { Pop-Location }
}

Write-Host "Windows client release"
Write-Host "  Mode: $(if ($Build) { 'BUILD' } else { 'DRY-RUN' })"
Write-Host "  App: student"

Push-Location $repoRoot
try {
    Invoke-CheckedCommand "python" @("scripts\audit\audit_release_inputs.py")
    $releasePaths = @(
        "flutter_app", "packages/shared", "scripts/release/generate_version.py",
        "scripts/audit/audit_release_inputs.py", "scripts/release/build_windows_release.ps1",
        "scripts/release/windows_installer.iss"
    )
    $dirty = & git -c safe.directory=D:/Hermes/zhangyuzhixue_app_v2 status --porcelain -- @releasePaths
    if ($LASTEXITCODE -ne 0) { throw "Unable to inspect release Git status" }
    if ($dirty -and -not $AllowDirty) {
        throw "Release inputs have uncommitted changes. Commit them or pass -AllowDirty explicitly."
    }
    $commit = (& git -c safe.directory=D:/Hermes/zhangyuzhixue_app_v2 rev-parse HEAD).Trim()
    if (-not $commit) { throw "Unable to resolve release commit" }
    if (-not (Test-Path -LiteralPath $flutter -PathType Leaf)) { throw "Flutter SDK not found: $flutter" }
    if (-not (Test-Path -LiteralPath $iscc -PathType Leaf)) { throw "Inno Setup not found: $iscc" }
    Write-Host "  Commit: $commit"
    if (-not $Build) {
        Write-Host "DRY-RUN complete. No build or installer was created."
        exit 0
    }

    $env:FLUTTER_SUPPRESS_ANALYTICS = "true"
    Invoke-CheckedCommand "python" @("scripts\release\generate_version.py")
    Invoke-CheckedCommand $flutter @("--no-version-check", "build", "windows", "--release") (Join-Path $repoRoot "flutter_app")
    Invoke-CheckedCommand $iscc @((Join-Path $repoRoot "scripts\release\windows_installer.iss"))
    Invoke-CheckedCommand "python" @("scripts\release\create_release_manifest.py", "--output", (Join-Path $distRoot "release-manifest.json"))
    Write-Host "Release artifacts: $distRoot"
}
finally { Pop-Location }
