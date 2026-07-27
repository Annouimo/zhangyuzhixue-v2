[CmdletBinding()]
param(
    [switch]$Deploy,
    [switch]$AllowDirty,
    [string]$SshKey = "C:\Users\Annouimo\.ssh\id_rsa"
)

$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$teacherRoot = Join-Path $repoRoot "landing\teacher"
$server = "root@82.157.115.219"
$remoteRoot = "/opt/zhangyuzhixue-v2"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$tempRoot = Join-Path $repoRoot ".hermes\tmp\teacher-web-release-$timestamp"
$archive = Join-Path $tempRoot "teacher-web-release.tar.gz"
$manifest = Join-Path $tempRoot "SHA256SUMS"
$remoteArchive = "/tmp/zhangyuzhixue-teacher-web-$timestamp.tar.gz"
$remoteManifest = "/tmp/zhangyuzhixue-teacher-web-$timestamp.SHA256SUMS"
$releaseFiles = @(
    "about.html", "classes.html", "detail.html", "index.html", "login.html",
    "publish.html", "student.html", "students.html", "teacher-common.js", "teacher-styles.css"
)

function Invoke-CheckedCommand {
    param([string]$Executable, [string[]]$Arguments)
    & $Executable @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$Executable failed with exit code $LASTEXITCODE" }
}

Write-Host "Teacher Web production release"
Write-Host "  Server: $server"
Write-Host "  Mode:   $(if ($Deploy) { 'DEPLOY' } else { 'DRY-RUN' })"
if ($Deploy -and -not (Test-Path -LiteralPath $SshKey -PathType Leaf)) { throw "SSH key not found: $SshKey" }

Push-Location $repoRoot
try {
    Invoke-CheckedCommand "python" @("scripts\audit_teacher_web.py", "landing\teacher")
    $releasePaths = $releaseFiles | ForEach-Object { "landing/teacher/$_" }
    $dirty = & git -c safe.directory=D:/Hermes/zhangyuzhixue_app_v2 status --porcelain -- @releasePaths
    if ($LASTEXITCODE -ne 0) { throw "Unable to inspect Teacher Web Git status" }
    if ($dirty -and -not $AllowDirty) { throw "Teacher Web has uncommitted changes. Commit it or pass -AllowDirty explicitly." }
    $commit = (& git -c safe.directory=D:/Hermes/zhangyuzhixue_app_v2 rev-parse HEAD).Trim()
    if ($LASTEXITCODE -ne 0 -or -not $commit) { throw "Unable to resolve release commit" }

    New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
    $manifestLines = foreach ($relativePath in $releaseFiles) {
        $absolutePath = Join-Path $teacherRoot $relativePath
        if (-not (Test-Path -LiteralPath $absolutePath -PathType Leaf)) { throw "Release file not found: $relativePath" }
        $hash = (Get-FileHash -LiteralPath $absolutePath -Algorithm SHA256).Hash.ToLowerInvariant()
        "$hash  $relativePath"
    }
    [System.IO.File]::WriteAllText($manifest, (($manifestLines -join "`n") + "`n"), [System.Text.Encoding]::ASCII)
    if ([System.IO.File]::ReadAllBytes($manifest) -contains 13) { throw "Manifest contains CR bytes" }
    Invoke-CheckedCommand "tar" (@("-czf", $archive, "-C", $teacherRoot) + $releaseFiles)
    Write-Host "  Commit: $commit"
    Write-Host "  Files:  $($releaseFiles.Count)"
    if (-not $Deploy) { Write-Host "DRY-RUN complete. No production mutation was performed."; exit 0 }

    Invoke-CheckedCommand "scp" @("-o", "BatchMode=yes", "-o", "ConnectTimeout=10", "-i", $SshKey, $archive, "${server}:$remoteArchive")
    Invoke-CheckedCommand "scp" @("-o", "BatchMode=yes", "-o", "ConnectTimeout=10", "-i", $SshKey, $manifest, "${server}:$remoteManifest")

    $remoteScript = @"
set -euo pipefail
archive='$remoteArchive'
manifest='$remoteManifest'
deploy_root='$remoteRoot/landing/teacher'
shared_logo='$remoteRoot/landing/images/logo-mark-96.png'
stage='/tmp/zhangyuzhixue-teacher-web-stage-$timestamp'
previous='/tmp/zhangyuzhixue-teacher-web-previous-$timestamp'
backup='$remoteRoot/backups/teacher-web-$timestamp.tar.gz'
log='$remoteRoot/backups/teacher-web-deployments.log'
lock='/var/lock/zhangyuzhixue-teacher-web-deploy.lock'
swapped=false
exec 9>"`$lock"
if ! flock -n 9; then echo 'Another Teacher Web deployment is running.' >&2; exit 1; fi
rollback() {
    code=`$?
    trap - ERR
    if `$swapped; then
        rm -rf -- "`$deploy_root"
        mv "`$previous" "`$deploy_root"
        nginx -t
    fi
    rm -rf -- "`$stage" "`$previous"
    rm -f -- "`$archive" "`$manifest"
    exit "`$code"
}
trap rollback ERR
test "`$deploy_root" = '$remoteRoot/landing/teacher'
test -f "`$shared_logo"
test -f "`$archive"
test -f "`$manifest"
rm -rf -- "`$stage" "`$previous"
mkdir -p "`$stage" '$remoteRoot/backups'
tar -xzf "`$archive" -C "`$stage"
cd "`$stage"
sha256sum -c "`$manifest"
test "`$(find . -maxdepth 1 -type f | wc -l)" -eq 10
find "`$stage" -type d -exec chmod 755 {} +
find "`$stage" -type f -exec chmod 644 {} +
chown -R root:root "`$stage"
tar -czf "`$backup" -C '$remoteRoot/landing' teacher
mv "`$deploy_root" "`$previous"
mv "`$stage" "`$deploy_root"
swapped=true
cd "`$deploy_root"
sha256sum -c "`$manifest"
nginx -t
curl -fsS --max-time 10 http://127.0.0.1:8080/teacher/login.html >/dev/null
curl -fsS --max-time 10 http://127.0.0.1:8080/teacher/teacher-common.js >/dev/null
printf '%s commit=%s manifest=%s backup=%s\n' "`$(date --iso-8601=seconds)" '$commit' "`$(sha256sum "`$manifest" | awk '{print `$1}')" "`$backup" >> "`$log"
rm -rf -- "`$previous"
rm -f -- "`$archive" "`$manifest"
swapped=false
trap - ERR
echo "BACKUP=`$backup"
"@
    Invoke-CheckedCommand "ssh" @("-o", "BatchMode=yes", "-i", $SshKey, $server, $remoteScript.Replace("`r", ""))
    try { Invoke-CheckedCommand "python" @("scripts\smoke_production.py") }
    catch {
        Write-Warning "Public smoke failed; restoring Teacher Web backup."
        $restoreScript = @"
set -euo pipefail
backup='$remoteRoot/backups/teacher-web-$timestamp.tar.gz'
deploy_root='$remoteRoot/landing/teacher'
restore='/tmp/zhangyuzhixue-teacher-web-restore-$timestamp'
exec 9>'/var/lock/zhangyuzhixue-teacher-web-deploy.lock'
flock 9
test -f "`$backup"
rm -rf -- "`$restore"
mkdir -p "`$restore"
tar -xzf "`$backup" -C "`$restore"
test -d "`$restore/teacher"
rm -rf -- "`$deploy_root"
mv "`$restore/teacher" "`$deploy_root"
rmdir "`$restore"
nginx -t
"@
        Invoke-CheckedCommand "ssh" @("-o", "BatchMode=yes", "-i", $SshKey, $server, $restoreScript.Replace("`r", ""))
        throw
    }
    Write-Host "Teacher Web deployment completed: $timestamp"
}
finally { Pop-Location }
