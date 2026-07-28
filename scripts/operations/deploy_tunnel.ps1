[CmdletBinding()]
param(
    [switch]$Apply,
    [string]$CandidatePath,
    [string]$SshKey = "C:\Users\Annouimo\.ssh\id_rsa"
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$serverScript = Join-Path $repoRoot "server\scripts\deploy_cloudflared_config.sh"
$server = "root@82.157.115.219"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$remoteScript = "/tmp/zhangyuzhixue-deploy-cloudflared-$timestamp.sh"
$remoteCandidate = "/tmp/zhangyuzhixue-cloudflared-$timestamp.yml"

if (-not (Test-Path -LiteralPath $serverScript -PathType Leaf)) {
    throw "Tunnel deployment script not found: $serverScript"
}
if ($CandidatePath) {
    $CandidatePath = (Resolve-Path $CandidatePath).Path
}

Write-Host "Cloudflare Tunnel production configuration"
Write-Host "  Candidate: $(if ($CandidatePath) { $CandidatePath } else { 'CURRENT SERVER CONFIG' })"
Write-Host "  Mode:      $(if ($Apply) { 'APPLY' } else { 'DRY-RUN' })"

if (-not $Apply) {
    Write-Host "DRY-RUN complete. No network or production mutation was performed."
    exit 0
}
if (-not (Test-Path -LiteralPath $SshKey -PathType Leaf)) {
    throw "SSH key not found: $SshKey"
}

& scp -o BatchMode=yes -i $SshKey $serverScript "${server}:$remoteScript"
if ($LASTEXITCODE -ne 0) { throw "Unable to upload Tunnel deployment script" }
if ($CandidatePath) {
    & scp -o BatchMode=yes -i $SshKey $CandidatePath "${server}:$remoteCandidate"
    if ($LASTEXITCODE -ne 0) { throw "Unable to upload Tunnel candidate" }
}

$candidateArgument = if ($CandidatePath) { $remoteCandidate } else { "" }
$command = "set -e; trap 'rm -f -- `"$remoteScript`" `"$remoteCandidate`"' EXIT; chmod 700 '$remoteScript'; bash '$remoteScript' '$candidateArgument'"
& ssh -o BatchMode=yes -i $SshKey $server $command
if ($LASTEXITCODE -ne 0) { throw "Tunnel configuration deployment failed" }

& python (Join-Path $repoRoot "scripts\audit\smoke_production.py")
if ($LASTEXITCODE -ne 0) { throw "Production smoke test failed" }
