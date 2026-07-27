[CmdletBinding()]
param(
    [switch]$Deploy,
    [switch]$AllowDirty,
    [string]$SshKey = "C:\Users\Annouimo\.ssh\id_rsa"
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$landingRoot = Join-Path $repoRoot "landing"
$server = "root@82.157.115.219"
$remoteRoot = "/opt/zhangyuzhixue-v2"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$tempRoot = Join-Path $repoRoot ".hermes\tmp\landing-release-$timestamp"
$archive = Join-Path $tempRoot "landing-release.tar.gz"
$manifest = Join-Path $tempRoot "SHA256SUMS"
$remoteArchive = "/tmp/zhangyuzhixue-landing-$timestamp.tar.gz"
$remoteManifest = "/tmp/zhangyuzhixue-landing-$timestamp.SHA256SUMS"

$releaseFiles = @(
    "index.html",
    "software.html",
    "courses.html",
    "course-derivative.html",
    "course-geometry.html",
    "course-innovation.html",
    "team.html",
    "about.html",
    "privacy.html",
    "terms.html",
    "internal.html",
    "assets/css/site.css",
    "assets/js/site.js",
    "assets/images/share-cover.jpg",
    "robots.txt",
    "sitemap.xml",
    "404.html"
)

function Invoke-CheckedCommand {
    param([string]$Executable, [string[]]$Arguments)
    & $Executable @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$Executable failed with exit code $LASTEXITCODE"
    }
}

Write-Host "Landing production release"
Write-Host "  Repository: $repoRoot"
Write-Host "  Server:     $server"
Write-Host "  Mode:       $(if ($Deploy) { 'DEPLOY' } else { 'DRY-RUN' })"

if ($Deploy -and -not (Test-Path -LiteralPath $SshKey -PathType Leaf)) {
    throw "SSH key not found: $SshKey"
}

Push-Location $repoRoot
try {
    Invoke-CheckedCommand "python" @("scripts\audit_landing.py", "landing")

    $releasePaths = $releaseFiles | ForEach-Object { "landing/$_" }
    $dirtyLanding = & git -c safe.directory=D:/Hermes/zhangyuzhixue_app_v2 status --porcelain -- @releasePaths
    if ($LASTEXITCODE -ne 0) {
        throw "Unable to inspect Landing Git status"
    }
    if ($dirtyLanding -and -not $AllowDirty) {
        throw "Landing has uncommitted changes. Commit the release or pass -AllowDirty explicitly."
    }
    $commit = (& git -c safe.directory=D:/Hermes/zhangyuzhixue_app_v2 rev-parse HEAD).Trim()
    if ($LASTEXITCODE -ne 0 -or -not $commit) {
        throw "Unable to resolve the release commit"
    }

    New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
    $manifestLines = foreach ($relativePath in $releaseFiles) {
        $absolutePath = Join-Path $landingRoot $relativePath
        if (-not (Test-Path -LiteralPath $absolutePath -PathType Leaf)) {
            throw "Release file not found: $relativePath"
        }
        $hash = (Get-FileHash -LiteralPath $absolutePath -Algorithm SHA256).Hash.ToLowerInvariant()
        "$hash  $relativePath"
    }
    Set-Content -LiteralPath $manifest -Value $manifestLines -Encoding ascii

    $tarArguments = @("-czf", $archive, "-C", $landingRoot) + $releaseFiles
    Invoke-CheckedCommand "tar" $tarArguments

    Write-Host "  Files:      $($releaseFiles.Count)"
    Write-Host "  Archive:    $archive"
    Write-Host "  Manifest:   $manifest"

    if (-not $Deploy) {
        Write-Host "DRY-RUN complete. No network or production mutation was performed."
        exit 0
    }

    Invoke-CheckedCommand "scp" @(
        "-o", "BatchMode=yes",
        "-o", "ConnectTimeout=10",
        "-i", $SshKey,
        $archive,
        "${server}:$remoteArchive"
    )
    Invoke-CheckedCommand "scp" @(
        "-o", "BatchMode=yes",
        "-o", "ConnectTimeout=10",
        "-i", $SshKey,
        $manifest,
        "${server}:$remoteManifest"
    )

    $remoteScript = @"
set -euo pipefail
archive='$remoteArchive'
manifest='$remoteManifest'
deploy_root='$remoteRoot/landing'
release_id='$timestamp'
backup_root='$remoteRoot/backups'
lock_file='/var/lock/zhangyuzhixue-landing-deploy.lock'
stage="/tmp/zhangyuzhixue-landing-stage-$timestamp"
backup="`$backup_root/landing-$timestamp.tar.gz"
backup_created=false

exec 9>"`$lock_file"
if ! flock -n 9; then
    echo 'Another Landing deployment is already running.' >&2
    exit 1
fi

validate_deploy_root() {
    test "`$deploy_root" = '$remoteRoot/landing'
}

rollback() {
    exit_code=`$?
    trap - ERR
    if `$backup_created; then
        echo "Landing deployment failed; restoring `$backup" >&2
        validate_deploy_root
        rm -rf -- "`$deploy_root"
        tar -xzf "`$backup" -C '$remoteRoot'
        nginx -t
    fi
    rm -rf "`$stage"
    rm -f "`$archive" "`$manifest"
    exit "`$exit_code"
}
trap rollback ERR

test -f "`$archive"
test -f "`$manifest"
mkdir -p "`$backup_root" "`$stage"
tar -xzf "`$archive" -C "`$stage"
cd "`$stage"
sha256sum -c "`$manifest"

tar -czf "`$backup" -C '$remoteRoot' landing
backup_created=true
tar -xzf "`$archive" -C "`$deploy_root"
find "`$stage" -type d -printf '%P\n' | while read -r path; do
    test -z "`$path" || chmod 755 "`$deploy_root/`$path"
done
while read -r hash path; do
    chmod 644 "`$deploy_root/`$path"
    chown root:root "`$deploy_root/`$path"
done < "`$manifest"
chmod 755 "`$deploy_root"

cd "`$deploy_root"
sha256sum -c "`$manifest"
nginx -t

printf '%s commit=%s manifest=%s backup=%s\n' \
    "`$(date --iso-8601=seconds)" '$commit' \
    "`$(sha256sum "`$manifest" | awk '{print `$1}')" "`$backup" \
    >> "`$backup_root/landing-deployments.log"

rm -rf "`$stage"
rm -f "`$archive" "`$manifest"
trap - ERR
echo "BACKUP=`$backup"
"@

    $remoteCommand = $remoteScript.Replace("`r", "")
    Invoke-CheckedCommand "ssh" @(
        "-o", "BatchMode=yes",
        "-i", $SshKey,
        $server,
        $remoteCommand
    )

    try {
        Invoke-CheckedCommand "python" @("scripts\smoke_production.py")
    }
    catch {
        Write-Warning "Public smoke test failed. Restoring the Landing backup."
        $restoreScript = @"
set -euo pipefail
backup='$remoteRoot/backups/landing-$timestamp.tar.gz'
deploy_root='$remoteRoot/landing'
lock_file='/var/lock/zhangyuzhixue-landing-deploy.lock'
exec 9>"`$lock_file"
flock 9
test -f "`$backup"
test "`$deploy_root" = '$remoteRoot/landing'
rm -rf -- "`$deploy_root"
tar -xzf "`$backup" -C '$remoteRoot'
nginx -t
echo "Landing restored from `$backup"
"@
        $restoreCommand = $restoreScript.Replace("`r", "")
        Invoke-CheckedCommand "ssh" @(
            "-o", "BatchMode=yes",
            "-i", $SshKey,
            $server,
            $restoreCommand
        )
        throw
    }

    Write-Host "Landing deployment completed: $timestamp"
}
finally {
    Pop-Location
}
