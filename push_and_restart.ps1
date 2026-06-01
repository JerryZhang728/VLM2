# push_and_restart.ps1
# ---------------------------------------------------------------------------
# One-shot dev-loop helper: copy the local VLM2/ tree to Thor over LAN, then
# restart live-vlm-webui on Thor (inside the venv at ThorPath/.venv).
#
# Prereqs (one-time setup, see SETUP_THOR.md):
#   * SSH access to Thor with password-free key auth recommended
#   * On Thor:
#         cd /home/ubuntu/vlm/vlm2
#         python3 -m venv .venv
#         source .venv/bin/activate
#         pip install -e .
#
# Usage:
#   .\push_and_restart.ps1                 # default Thor target
#   .\push_and_restart.ps1 -Restart:$false # push only, don't restart
# ---------------------------------------------------------------------------

param(
    [string]$ThorUser   = "ubuntu",
    [string]$ThorHost   = "192.168.213.135",
    [string]$ThorPath   = "/home/ubuntu/vlm/vlm2",
    [bool]  $Restart    = $true
)

$ErrorActionPreference = "Stop"
$LocalPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$VenvPython = "$ThorPath/.venv/bin/python"
$VenvPip    = "$ThorPath/.venv/bin/pip"

Write-Host "==> Pushing $LocalPath/  ->  $ThorUser@$ThorHost`:$ThorPath/" -ForegroundColor Cyan

# Push only the files that change. Skip .git, .venv, __pycache__, dist, etc.
$pushTargets = @(
    "src",
    "bin",
    "pyproject.toml",
    "requirements.txt",
    "MANIFEST.in",
    "README.md",
    "LICENSE"
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

Write-Host "==> Push complete" -ForegroundColor Green

if ($Restart) {
    Write-Host "==> Restarting live-vlm-webui on Thor (venv)..." -ForegroundColor Cyan

    # Run inside the project venv. pip install -e . is editable so we don't
    # strictly need to re-run it on every push, but doing so picks up any
    # pyproject.toml dependency changes for free.
    $restartCmd = @"
set -e
cd $ThorPath
if [ ! -x "$VenvPython" ]; then
    echo "ERROR: venv not found at $VenvPython"
    echo "Run the one-time setup from SETUP_THOR.md first."
    exit 1
fi
# Reinstall in editable mode (cheap if nothing changed).
$VenvPip install -e . --quiet 2>/dev/null || true
# Kill any prior instance.
pkill -f 'live_vlm_webui.server' 2>/dev/null || true
pkill -f 'live-vlm-webui' 2>/dev/null || true
sleep 1
# setsid + closed stdin properly detaches from this SSH session so the
# process survives after this remote command returns.
setsid $VenvPython -u -m live_vlm_webui.server </dev/null > /tmp/vlm.log 2>&1 &
disown 2>/dev/null || true
sleep 3
echo '--- last 30 lines of /tmp/vlm.log ---'
tail -n 30 /tmp/vlm.log
"@

    ssh "${ThorUser}@${ThorHost}" $restartCmd
    Write-Host ""
    Write-Host "==> Done." -ForegroundColor Green
    Write-Host "    Open https://${ThorHost}:8090 in your browser" -ForegroundColor Yellow
    Write-Host "    Tail logs:  ssh ${ThorUser}@${ThorHost} 'tail -f /tmp/vlm.log'" -ForegroundColor DarkGray
}
