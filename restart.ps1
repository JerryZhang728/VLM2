# restart.ps1 — restart the server in BACKGROUND on Thor; logs to /tmp/vlm.log
# Usage:  .\restart

param(
    [string]$ThorUser = "ubuntu",
    [string]$ThorHost = "192.168.213.135",
    [string]$ThorPath = "/home/ubuntu/vlm/vlm2"
)

$ErrorActionPreference = "Stop"
$VenvPython = "$ThorPath/.venv/bin/python"

$cmd = @"
set -e
cd $ThorPath
if [ ! -x "$VenvPython" ]; then
    echo "ERROR: venv not found at $VenvPython"
    exit 1
fi
pkill -f 'live_vlm_webui.server' 2>/dev/null || true
sleep 1
setsid $VenvPython -u -m live_vlm_webui.server </dev/null > /tmp/vlm.log 2>&1 &
disown 2>/dev/null || true
sleep 3
echo '--- last 30 lines of /tmp/vlm.log ---'
tail -n 30 /tmp/vlm.log
"@

ssh "${ThorUser}@${ThorHost}" $cmd
Write-Host ""
Write-Host "==> Done. URL: https://${ThorHost}:8090" -ForegroundColor Green
