# Builds the debug APK. No keystore or password needed — installs on any phone.
# Uses JDK 17 because Capacitor 6 ships Gradle 8.2, which rejects Java 21.
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

$env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-17.0.20.101-hotspot"
$env:ANDROID_HOME = "C:\Android"
$env:ANDROID_SDK_ROOT = "C:\Android"
$env:Path = "$env:JAVA_HOME\bin;$env:Path"

Write-Host "==> npm install"
cmd /c "npm install --no-audit --no-fund" 2>&1 | Select-Object -Last 4

if (-not (Test-Path ".\android")) {
  Write-Host "==> cap add android"
  cmd /c "npx --yes cap add android" 2>&1 | Select-Object -Last 8
} else {
  Write-Host "==> cap sync android"
  cmd /c "npx --yes cap sync android" 2>&1 | Select-Object -Last 8
}

Write-Host "==> patching AndroidManifest"
node scripts\patch-android.js

if (Test-Path ".\resources\icon.png") {
  Write-Host "==> generating launcher icons and splash"
  cmd /c "npx --yes @capacitor/assets generate --android" 2>&1 | Select-Object -Last 4
}

Write-Host "==> gradle assembleDebug (first run downloads Gradle, be patient)"
Set-Location ".\android"
cmd /c "gradlew.bat assembleDebug --no-daemon -q" 2>&1 | Select-Object -Last 15
Set-Location $PSScriptRoot

$apk = ".\android\app\build\outputs\apk\debug\app-debug.apk"
if (Test-Path $apk) {
  Copy-Item $apk ".\RepsAndSteps-1.0.0-debug.apk" -Force
  Write-Host ("BUILD-OK size MB: " + [math]::Round((Get-Item ".\RepsAndSteps-1.0.0-debug.apk").Length/1MB, 2))
} else {
  Write-Host "BUILD-FAILED no apk produced"
}
