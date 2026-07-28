[CmdletBinding()]
param(
    [switch]$Deploy,
    [string]$SshKey = "C:\Users\Annouimo\.ssh\id_rsa"
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$config = Join-Path $repoRoot "server\deploy\nginx\zhangyuzhixue.conf"
$server = "root@82.157.115.219"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$remoteCandidate = "/tmp/zhangyuzhixue-nginx-$timestamp.conf"

function Invoke-CheckedCommand {
    param([string]$Executable, [string[]]$Arguments)
    & $Executable @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$Executable failed with exit code $LASTEXITCODE"
    }
}

if (-not (Test-Path -LiteralPath $config -PathType Leaf)) {
    throw "Nginx configuration not found: $config"
}
$hash = (Get-FileHash -LiteralPath $config -Algorithm SHA256).Hash.ToLowerInvariant()

Write-Host "Nginx production configuration"
Write-Host "  Config: $config"
Write-Host "  SHA256: $hash"
Write-Host "  Mode:   $(if ($Deploy) { 'DEPLOY' } else { 'DRY-RUN' })"

if (-not $Deploy) {
    Write-Host "DRY-RUN complete. No network or production mutation was performed."
    exit 0
}
if (-not (Test-Path -LiteralPath $SshKey -PathType Leaf)) {
    throw "SSH key not found: $SshKey"
}

Invoke-CheckedCommand "scp" @(
    "-o", "BatchMode=yes", "-i", $SshKey,
    $config, "${server}:$remoteCandidate"
)

$remoteScript = @"
set -euo pipefail
candidate='$remoteCandidate'
available='/etc/nginx/sites-available/zhangyuzhixue'
enabled='/etc/nginx/sites-enabled/zhangyuzhixue'
backup_dir='/var/backups/zhangyuzhixue-v2/nginx/$timestamp'
log='/var/log/zhangyuzhixue/nginx-deployments.log'
lock='/var/lock/zhangyuzhixue-nginx-deploy.lock'
installed=false

exec 9>"`$lock"
if ! flock -n 9; then
    echo 'Another nginx configuration deployment is running' >&2
    exit 1
fi
test -f "`$candidate"
test -f "`$available"
test -f "`$enabled"
mkdir -p "`$backup_dir" "`$(dirname "`$log")"
cp -a "`$available" "`$backup_dir/available.conf"
cp -a "`$enabled" "`$backup_dir/enabled.conf"

rollback() {
    exit_code=`$?
    trap - EXIT
    set +e
    if `$installed; then
        install -o root -g root -m 644 "`$backup_dir/available.conf" "`$available"
        install -o root -g root -m 644 "`$backup_dir/enabled.conf" "`$enabled"
        nginx -t && systemctl reload nginx
    fi
    rm -f -- "`$candidate"
    exit "`$exit_code"
}
trap rollback EXIT

install -o root -g root -m 644 "`$candidate" "`$available"
install -o root -g root -m 644 "`$candidate" "`$enabled"
installed=true
nginx -t
systemctl reload nginx
systemctl is-active --quiet nginx
curl --fail --silent --output /dev/null http://127.0.0.1:8080/
curl --fail --silent --output /dev/null https://zhangyuzhixue.top/
login_status="`$(curl --silent --output /dev/null --write-out '%{http_code}' https://zhangyuzhixue.zhtec123.com/api/v1/auth/login/)"
test "`$login_status" = '405'
test "`$(sha256sum "`$enabled" | awk '{print `$1}')" = '$hash'

printf '%s config_sha256=%s backup=%s status=success\n' \
    "`$(date --iso-8601=seconds)" '$hash' "`$backup_dir" >> "`$log"
rm -f -- "`$candidate"
trap - EXIT
echo "Nginx configuration deployment completed: `$backup_dir"
"@

Invoke-CheckedCommand "ssh" @(
    "-o", "BatchMode=yes", "-i", $SshKey, $server,
    $remoteScript.Replace("`r", "")
)
Invoke-CheckedCommand "python" @("scripts\audit\smoke_production.py")
