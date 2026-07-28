[CmdletBinding()]
param(
    [switch]$Apply,
    [switch]$HardenPermissions,
    [string]$SshKey = "C:\Users\Annouimo\.ssh\id_rsa"
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$server = "root@82.157.115.219"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$remoteStage = "/tmp/zhangyuzhixue-deploy-bootstrap-$timestamp"
$files = @(
    "server/scripts/pre-receive.prod",
    "server/scripts/post-receive.prod",
    "server/scripts/harden_production_permissions.sh"
)

function Invoke-CheckedCommand {
    param([string]$Executable, [string[]]$Arguments)
    & $Executable @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$Executable failed with exit code $LASTEXITCODE"
    }
}

foreach ($relativePath in $files) {
    $absolutePath = Join-Path $repoRoot $relativePath
    if (-not (Test-Path -LiteralPath $absolutePath -PathType Leaf)) {
        throw "Bootstrap file not found: $relativePath"
    }
}

Write-Host "Production deployment bootstrap"
Write-Host "  Server: $server"
Write-Host "  Mode:   $(if ($Apply) { 'APPLY' } else { 'DRY-RUN' })"
Write-Host "  Harden: $HardenPermissions"

if (-not $Apply) {
    Write-Host "Would upload and install:"
    $files | ForEach-Object { Write-Host "  $_" }
    Write-Host "No network or production mutation was performed."
    exit 0
}

if (-not (Test-Path -LiteralPath $SshKey -PathType Leaf)) {
    throw "SSH key not found: $SshKey"
}

Invoke-CheckedCommand "ssh" @(
    "-o", "BatchMode=yes", "-i", $SshKey, $server,
    "install -d -m 700 '$remoteStage'"
)

try {
    foreach ($relativePath in $files) {
        Invoke-CheckedCommand "scp" @(
            "-o", "BatchMode=yes", "-i", $SshKey,
            (Join-Path $repoRoot $relativePath),
            "${server}:${remoteStage}/"
        )
    }

    $applyPermissions = if ($HardenPermissions) {
        "bash '$remoteStage/harden_production_permissions.sh'"
    } else {
        "echo 'Sensitive-file permissions unchanged (use -HardenPermissions to apply).'"
    }
    $remoteScript = @"
set -euo pipefail
bare='/opt/zhangyuzhixue-v2.git'
hooks="`$bare/hooks"
backup="`$bare/hook-backups/$timestamp"
test -d "`$bare"
install -d -m 700 "`$backup"
for hook in pre-receive post-receive; do
    if test -f "`$hooks/`$hook"; then
        cp -a "`$hooks/`$hook" "`$backup/`$hook"
    fi
done
install -o root -g root -m 755 '$remoteStage/pre-receive.prod' "`$hooks/pre-receive"
install -o root -g root -m 755 '$remoteStage/post-receive.prod' "`$hooks/post-receive"
bash -n "`$hooks/pre-receive"
bash -n "`$hooks/post-receive"
$applyPermissions
systemctl is-active --quiet zhangyuzhixue-web
systemctl is-active --quiet nginx
systemctl is-active --quiet cloudflared-zhangyuzhixue
nginx -t
echo "Hook backup: `$backup"
"@
    Invoke-CheckedCommand "ssh" @(
        "-o", "BatchMode=yes", "-i", $SshKey, $server,
        $remoteScript.Replace("`r", "")
    )
}
finally {
    & ssh -o BatchMode=yes -i $SshKey $server "rm -rf -- '$remoteStage'" | Out-Null
}

Write-Host "Production deployment bootstrap completed."
