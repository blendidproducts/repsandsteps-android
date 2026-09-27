# ============================================================
#  Create the RepsAndSteps signing key — ONE TIME, EVER.
#
#  This file signs every future build. If you lose it you can never update
#  the app on Google Play again; you'd have to publish a brand new listing.
#  Back release.keystore up somewhere safe (password manager + a second drive)
#  and never commit it to GitHub.
# ============================================================
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

if (Test-Path ".\release.keystore") {
  Write-Host "release.keystore already exists here. Not touching it." -ForegroundColor Yellow
  exit
}
if (-not $env:JAVA_HOME) { throw "JAVA_HOME is not set. Install JDK 21 from https://adoptium.net" }

$keytool = Join-Path $env:JAVA_HOME "bin\keytool.exe"

& $keytool -genkeypair -v `
  -keystore release.keystore `
  -alias repsandsteps `
  -keyalg RSA -keysize 4096 -validity 10000 `
  -dname "CN=RepsAndSteps, OU=Blendid Products LLC, O=Blendid Products LLC, L=, ST=, C=US"

Write-Host ""
Write-Host "Created release.keystore (alias: repsandsteps)" -ForegroundColor Green
Write-Host ""
Write-Host "To let GitHub Actions sign builds for you, add these repo secrets" -ForegroundColor Yellow
Write-Host "(Settings -> Secrets and variables -> Actions -> New repository secret):"
Write-Host "  KEYSTORE_BASE64    <- the line printed below"
Write-Host "  KEYSTORE_PASSWORD  <- the password you just typed"
Write-Host "  KEY_ALIAS          <- repsandsteps"
Write-Host "  KEY_PASSWORD       <- the same password"
Write-Host ""
$b64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes("$PSScriptRoot\release.keystore"))
$b64 | Set-Content ".\keystore.base64.txt"
Write-Host "Base64 of the keystore written to keystore.base64.txt" -ForegroundColor Cyan
Write-Host "Paste its contents into KEYSTORE_BASE64, then DELETE that txt file." -ForegroundColor Cyan
