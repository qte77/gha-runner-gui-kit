# UNVERIFIED -- designed to mirror macos.sh's shape, not tested against a
# real target this session. There is no confirmed Windows consumer yet.
# Treat this as a starting point, not a proven path -- run it against a
# real installer and fix what breaks before depending on it.
$ErrorActionPreference = "Stop"

if (-not $env:DOWNLOAD_URL) { throw "DOWNLOAD_URL is required" }
$installType = if ($env:INSTALL_TYPE) { $env:INSTALL_TYPE } else { "exe" }
$launchTarget = $env:LAUNCH_TARGET
$settleSeconds = if ($env:SETTLE_SECONDS) { [int]$env:SETTLE_SECONDS } else { 5 }
$interactScript = $env:INTERACT_SCRIPT

switch ($installType) {
  "exe" {
    Invoke-WebRequest -Uri $env:DOWNLOAD_URL -OutFile "installer.exe"
    # Most silent-install flags aren't universal (/S, /quiet, /verysilent
    # all exist across installer frameworks) -- this assumes /S and will
    # need adjusting per real target.
    Start-Process -FilePath "installer.exe" -ArgumentList "/S" -Wait
    if (-not $launchTarget) { throw "launch-target is required for install-type=exe" }
    $launchPath = $launchTarget
  }
  "zip" {
    Invoke-WebRequest -Uri $env:DOWNLOAD_URL -OutFile "installer.zip"
    $destDir = Join-Path $env:ProgramFiles "GuiKitApp"
    Expand-Archive -Path "installer.zip" -DestinationPath $destDir -Force
    if (-not $launchTarget) { throw "launch-target is required for install-type=zip" }
    $launchPath = Join-Path $destDir $launchTarget
  }
  default { throw "Unknown install-type: $installType (expected exe|zip)" }
}

Write-Host "Launching: $launchPath"
Start-Process -FilePath $launchPath
Start-Sleep -Seconds $settleSeconds

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Save-Screenshot([string]$path) {
  $bounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
  $bmp = New-Object System.Drawing.Bitmap $bounds.Width, $bounds.Height
  $graphics = [System.Drawing.Graphics]::FromImage($bmp)
  $graphics.CopyFromScreen($bounds.Location, [System.Drawing.Point]::Empty, $bounds.Size)
  $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
  $graphics.Dispose()
  $bmp.Dispose()
}

Save-Screenshot "probe-before.png"

if ($interactScript) {
  try {
    Invoke-Expression $interactScript
    Write-Host "Interact script completed"
  } catch {
    Write-Host "Interact script failed (non-fatal): $_"
  }
}

Start-Sleep -Seconds 2
Save-Screenshot "probe-after.png"
