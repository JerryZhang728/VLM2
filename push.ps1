# push.ps1 — sync local VLM2/ files to Thor over LAN. No server restart.
# Usage:  .\push
#
# After pushing, use .\start (foreground, see logs) or .\restart (background).

param(
    [string]$ThorUser = "ubuntu",
    [string]$ThorHost = "192.168.213.135",
    [string]$ThorPath = "/home/ubuntu/vlm/vlm2"
)

$ErrorActionPreference = "Stop"
$LocalPath = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "==> Pushing $LocalPath/  ->  $ThorUser@$ThorHost`:$ThorPath/" -ForegroundColor Cyan

# Pre-fix: make existing files writable so scp can overwrite them. scp's
# default behavior preserves perms, which can leave files read-only and
# block subsequent pushes.
ssh "${ThorUser}@${ThorHost}" "chmod -R u+rwX ${ThorPath} 2>/dev/null; true" | Out-Null

$pushTargets = @(
    "src",
    "bin",
    "start",
    "pyproject.toml",
    "requirements.txt",
    "MANIFEST.in",
    "README.md",
    "LICENSE",
    "NOTICE.txt"
)

foreach ($t in $pushTargets) {
    $local = Join-Path $LocalPath $t
    if (Test-Path $local) {
        Write-Host "    scp $t" -ForegroundColor DarkGray
        scp -r -q $local "${ThorUser}@${ThorHost}:${ThorPath}/"
        if ($LASTEXITCODE -ne 0) {
            Write-Host "    FAIL transferring $t" -ForegroundColor Red
            exit 1
        }
    }
}

# scp loses the +x bit; restore exec permission on shell scripts.
ssh "${ThorUser}@${ThorHost}" "chmod +x ${ThorPath}/start ${ThorPath}/bin/*.sh ${ThorPath}/bin/vlm2 2>/dev/null; true" | Out-Null

Write-Host "==> Push complete. On Thor:  cd /home/ubuntu/vlm/vlm2 && ./start" -ForegroundColor Green
Write-Host "    (or from Windows:  .\start  for foreground;  .\restart  for background)" -ForegroundColor DarkGray
