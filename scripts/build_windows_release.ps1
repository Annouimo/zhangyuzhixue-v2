[CmdletBinding()]
param(
    [switch]$Build,
    [switch]$IncludeTeacher,
    [switch]$AllowDirty
)

$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
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
Write-Host "  Apps: student$(if ($IncludeTeacher) { ' + teacher' } else { '' })"

Push-Location $repoRoot
try {
    Invoke-CheckedCommand "python" @("scripts\audit_release_inputs.py")
    $releasePaths = @(
        "flutter_app", "packages/shared", "scripts/generate_version.py",
        "scripts/audit_release_inputs.py", "scripts/build_windows_release.ps1",
        "docs/07-工作流/build_script_student.iss"
    )
    if ($IncludeTeacher) {
        $releasePaths += @("teacher_app", "docs/07-工作流/build_script_teacher.iss")
    }
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
    Invoke-CheckedCommand "python" @("scripts\generate_version.py")
    Invoke-CheckedCommand $flutter @("--no-version-check", "build", "windows", "--release") (Join-Path $repoRoot "flutter_app")
    Invoke-CheckedCommand $iscc @((Join-Path $repoRoot "docs\07-工作流\build_script_student.iss"))
    if ($IncludeTeacher) {
        Invoke-CheckedCommand $flutter @("--no-version-check", "build", "windows", "--release") (Join-Path $repoRoot "teacher_app")
        Invoke-CheckedCommand $iscc @((Join-Path $repoRoot "docs\07-工作流\build_script_teacher.iss"))
    }
    Invoke-CheckedCommand "python" @("scripts\create_release_manifest.py", "--output", (Join-Path $distRoot "release-manifest.json"))
    Write-Host "Release artifacts: $distRoot"
}
finally { Pop-Location }
