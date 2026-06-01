# push-images.ps1 — sync the /VLM/Images test folder to Thor.
# Usage:  .\push-images

param(
    [string]$ThorUser  = "ubuntu",
    [string]$ThorHost  = "192.168.213.135",
    [string]$ThorDest  = "/home/ubuntu/Images",
    [string]$LocalSrc  = "C:\Users\jerry\OneDrive_Gmail\OneDrive\Claude\VLM\Images"
)

if (-not (Test-Path $LocalSrc)) {
    Write-Host "Local source missing: $LocalSrc" -ForegroundColor Red
    exit 1
}

Write-Host "==> Pushing $LocalSrc/  ->  $ThorUser@$ThorHost`:$ThorDest/" -ForegroundColor Cyan

# Make destination writable first so scp can overwrite existing files.
ssh "${ThorUser}@${ThorHost}" "mkdir -p ${ThorDest}; chmod -R u+rwX ${ThorDest} 2>/dev/null; true" | Out-Null

scp -r -q "$LocalSrc\*" "${ThorUser}@${ThorHost}:${ThorDest}/"
if ($LASTEXITCODE -eq 0) {
    Write-Host "==> Done." -ForegroundColor Green
    ssh "${ThorUser}@${ThorHost}" "ls -la ${ThorDest} | head -20"
} else {
    Write-Host "==> Push failed." -ForegroundColor Red
    exit 1
}
