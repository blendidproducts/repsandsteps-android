# ============================================================
#  RepsAndSteps — build the Android APK on this Windows machine
#  Run from the apk\ folder:   powershell -ExecutionPolicy Bypass -File .\build-apk.ps1
#
#  Needs (one-time):
#    - Node 18+            https://nodejs.org
#    - Java JDK 21         https://adoptium.net   (set JAVA_HOME)
#    - Android SDK         Android Studio, or cmdline-tools + ANDROID_HOME
# ============================================================
param(
  [string]$Version = "1.0.0",
  [switch]$Release          # -Release signs with release.keystore; default is a debug build
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot          # drive-letter independent

function Need($name, $hint) {
  if (-not (Get-Command $name -ErrorAction SilentlyContinue)) { throw "$name not found. $hint" }
}
Need node "Install Node from https://nodejs.org"
if (-not $env:JAVA_HOME)    { throw "JAVA_HOME is not set. Install JDK 21 from https://adoptium.net" }
if (-not $env:ANDROID_HOME -and -not $env:ANDROID_SDK_ROOT) {
  throw "ANDROID_HOME is not set. Install Android Studio, then set ANDROID_HOME to e.g. C:\Users\$env:USERNAME\AppData\Local\Android\Sdk"
}

Write-Host "==> Installing dependencies" -ForegroundColor Cyan
npm install

if (-not (Test-Path ".\android")) {
  Write-Host "==> Creating the Android project" -ForegroundColor Cyan
  npx cap add android
} else {
  Write-Host "==> Syncing the Android project" -ForegroundColor Cyan
  npx cap sync android
}

Write-Host "==> Patching AndroidManifest (camera, wake lock)" -ForegroundColor Cyan
node scripts\patch-android.js

Write-Host "==> Stamping version $Version" -ForegroundColor Cyan
$gradle = ".\android\app\build.gradle"
$code = [int]((Get-Date).ToString("yyMMddHH"))
(Get-Content $gradle) `
  -replace 'versionName ".*"', "versionName `"$Version`"" `
  -replace 'versionCode \d+',  "versionCode $code" | Set-Content $gradle

Push-Location .\android
try {
  if ($Release) {
    Write-Host "==> Building RELEASE" -ForegroundColor Cyan
    .\gradlew.bat assembleRelease --no-daemon
    $unsigned = "app\build\outputs\apk\release\app-release-unsigned.apk"
    if (-not (Test-Path $unsigned)) { $unsigned = "app\build\outputs\apk\release\app-release.apk" }

    $sdk = if ($env:ANDROID_HOME) { $env:ANDROID_HOME } else { $env:ANDROID_SDK_ROOT }
    $bt  = (Get-ChildItem "$sdk\build-tools" | Sort-Object Name | Select-Object -Last 1).FullName
    $ks  = Join-Path $PSScriptRoot "release.keystore"
    if (-not (Test-Path $ks)) { throw "release.keystore not found next to build-apk.ps1. Run .\make-keystore.ps1 first." }

    $pw = Read-Host "Keystore password" -AsSecureString
    $pwPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
                 [Runtime.InteropServices.Marshal]::SecureStringToBSTR($pw))

    & "$bt\zipalign.exe" -p -f 4 $unsigned "aligned.apk"
    & "$bt\apksigner.bat" sign --ks $ks --ks-pass "pass:$pwPlain" --ks-key-alias repsandsteps `
        --key-pass "pass:$pwPlain" --out "..\RepsAndSteps-$Version.apk" "aligned.apk"
    & "$bt\apksigner.bat" verify --print-certs "..\RepsAndSteps-$Version.apk"
    Remove-Item "aligned.apk" -Force
    $out = "RepsAndSteps-$Version.apk"
  } else {
    Write-Host "==> Building DEBUG (installs on any phone, not for the Play Store)" -ForegroundColor Cyan
    .\gradlew.bat assembleDebug --no-daemon
    Copy-Item "app\build\outputs\apk\debug\app-debug.apk" "..\RepsAndSteps-$Version-debug.apk" -Force
    $out = "RepsAndSteps-$Version-debug.apk"
  }
} finally { Pop-Location }

$size = [math]::Round((Get-Item $out).Length / 1MB, 1)
$sha  = (Get-FileHash $out -Algorithm SHA256).Hash.ToLower()

Write-Host ""
Write-Host "  BUILT: $out  ($size MB)" -ForegroundColor Green
Write-Host "  SHA256: $sha" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Next:" -ForegroundColor Yellow
Write-Host "   1. Upload it to your site as  /downloads/repsandsteps-latest.apk"
Write-Host "   2. Update /app-version.json   (versionName $Version, sizeMB $size, sha256 above)"
Write-Host ""
