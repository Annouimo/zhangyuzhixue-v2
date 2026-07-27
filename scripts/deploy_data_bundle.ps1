[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("qbank", "courses")]
    [string]$DbType,
    [Parameter(Mandatory = $true)]
    [string]$Bundle,
    [switch]$Deploy,
    [switch]$AllowDirty,
    [switch]$ForceUpdate,
    [string]$Message = "",
    [string]$SshKey = "C:\Users\Annouimo\.ssh\id_rsa"
)

$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$bundlePath = (Resolve-Path -LiteralPath $Bundle).Path
$server = "root@82.157.115.219"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$releaseId = "$DbType-$timestamp"
$tempRoot = Join-Path $repoRoot ".hermes\tmp\data-release-$releaseId"
$manifestPath = Join-Path $tempRoot "manifest.json"
$remoteBundle = "/tmp/zhangyuzhixue-$releaseId.db.gz"
$remoteManifest = "/tmp/zhangyuzhixue-$releaseId.json"
$projectRoot = "/opt/zhangyuzhixue-v2/server"
$backupRoot = "/var/backups/zhangyuzhixue-v2/data-bundles"
$lockFile = "$projectRoot/media/db/.release.lock"

function Invoke-CheckedCommand {
    param([string]$Executable, [string[]]$Arguments)
    & $Executable @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$Executable failed with exit code $LASTEXITCODE" }
}

Push-Location $repoRoot
try {
    $dirty = & git -c safe.directory=D:/Hermes/zhangyuzhixue_app_v2 status --porcelain -- $bundlePath
    if ($LASTEXITCODE -ne 0) { throw "Unable to inspect bundle Git status" }
    if ($dirty -and -not $AllowDirty) {
        throw "Bundle has uncommitted changes. Commit it or pass -AllowDirty explicitly."
    }
    $commit = (& git -c safe.directory=D:/Hermes/zhangyuzhixue_app_v2 rev-parse HEAD).Trim()
    if (-not $commit) { throw "Unable to resolve release commit" }
    New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
    Invoke-CheckedCommand "python" @(
        "server\scripts\release_db_bundle.py", "prepare",
        "--db-type", $DbType, "--bundle", $bundlePath,
        "--output", $manifestPath, "--git-commit", $commit
    )
    Write-Host "Mode:       $(if ($Deploy) { 'DEPLOY' } else { 'DRY-RUN' })"
    Write-Host "Release ID: $releaseId"
    if (-not $Deploy) {
        Write-Host "DRY-RUN complete. No network or production mutation was performed."
        exit 0
    }
    if (-not (Test-Path -LiteralPath $SshKey -PathType Leaf)) { throw "SSH key not found" }
    Invoke-CheckedCommand "scp" @("-o", "BatchMode=yes", "-i", $SshKey, $bundlePath, "${server}:$remoteBundle")
    Invoke-CheckedCommand "scp" @("-o", "BatchMode=yes", "-i", $SshKey, $manifestPath, "${server}:$remoteManifest")

    $messageArg = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($Message))
    $forceArg = if ($ForceUpdate) { "--force-update" } else { "" }
    $remoteCommand = "set -euo pipefail; install -d -o ubuntu -g ubuntu -m 750 '$backupRoot'; msg=`$(printf '%s' '$messageArg' | base64 -d); sudo -u ubuntu /opt/zhangyuzhixue-v2/venv/bin/python '$projectRoot/scripts/release_db_bundle.py' install --project-root '$projectRoot' --backup-root '$backupRoot' --lock-file '$lockFile' --release-id '$releaseId' --bundle '$remoteBundle' --manifest '$remoteManifest' $forceArg --message `"`$msg`"; rm -f '$remoteBundle' '$remoteManifest'"
    Invoke-CheckedCommand "ssh" @("-o", "BatchMode=yes", "-i", $SshKey, $server, $remoteCommand)

    try {
        Invoke-CheckedCommand "python" @(
            "server\scripts\release_db_bundle.py", "verify",
            "--manifest", $manifestPath
        )
    }
    catch {
        Write-Warning "Public validation failed; rolling back $releaseId"
        $rollback = "sudo -u ubuntu /opt/zhangyuzhixue-v2/venv/bin/python '$projectRoot/scripts/release_db_bundle.py' rollback --project-root '$projectRoot' --backup-root '$backupRoot' --lock-file '$lockFile' --release-id '$releaseId'"
        Invoke-CheckedCommand "ssh" @("-o", "BatchMode=yes", "-i", $SshKey, $server, $rollback)
        throw
    }
    Write-Host "Data bundle deployment completed: $releaseId"
}
finally {
    Pop-Location
}
