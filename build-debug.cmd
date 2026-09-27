@echo off
setlocal
cd /d "%~dp0"

set "JAVA_HOME=C:\Program Files\Eclipse Adoptium\jdk-17.0.20.101-hotspot"
set "ANDROID_HOME=C:\Android"
set "ANDROID_SDK_ROOT=C:\Android"
set "PATH=%JAVA_HOME%\bin;%PATH%"

echo ==== build started %DATE% %TIME% ==== > build.log

REM Launcher icons and splash are pre-generated into android\app\src\main\res.
REM @capacitor/assets is deliberately NOT used: its `sharp` dependency has no
REM prebuilt binary for Node 24 on this machine and fails to install.

if not exist "android" (
  echo [1/4] cap add android
  call npx --yes cap add android >> build.log 2>&1
) else (
  echo [1/4] cap sync android
  call npx --yes cap sync android >> build.log 2>&1
)

echo [2/4] patch AndroidManifest
call node scripts\patch-android.js >> build.log 2>&1

echo [3/4] gradle assembleDebug
cd android
call gradlew.bat assembleDebug >> ..\build.log 2>&1
cd ..

echo [4/4] collect apk
if exist "android\app\build\outputs\apk\debug\app-debug.apk" (
  copy /Y "android\app\build\outputs\apk\debug\app-debug.apk" "RepsAndSteps-1.0.0-debug.apk" >nul
  echo BUILD-OK
) else (
  echo BUILD-FAILED - see build.log
)
endlocal
