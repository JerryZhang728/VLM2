# start.ps1 — kill any running server and start in FOREGROUND so logs stream live.
# Ctrl+C in this window stops the server.
# Usage:  .\start

param(
    [string]$ThorUser = "ubuntu",
    [string]$ThorHost = "192.168.213.135",
    [string]$ThorPath = "/home/ubuntu/vlm/vlm2"
)

$ErrorActionPreference = "Stop"

Write-Host "==> Killing any existing live-vlm-webui processes..." -ForegroundColor Cyan
ssh "${ThorUser}@${ThorHost}" "pkill -f live_vlm_webui.server 2>/dev/null; sleep 1; pgrep -f live_vlm_webui.server >/dev/null && pkill -9 -f live_vlm_webui.server; true"

Write-Host "==> Starting server in foreground (Ctrl+C to stop)..." -ForegroundColor Cyan
Write-Host "    URL: https://${ThorHost}:8090" -ForegroundColor Yellow
Write-Host ""

ssh -t "${ThorUser}@${ThorHost}" "cd ${ThorPath} && PYTHONUNBUFFERED=1 .venv/bin/python -u -m live_vlm_webui.server"
