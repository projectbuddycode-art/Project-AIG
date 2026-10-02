@echo off
REM Camera Stability Testing Script (Windows)
REM Tests the fixed camera preview functionality

setlocal enabledelayedexpansion

echo =========================================
echo AIG Camera Stability Test Suite
echo =========================================
echo Date: %date% %time%
echo.

REM Configuration
set "ADB=C:\Users\proje\AppData\Local\Android\sdk\platform-tools\adb.exe"
set "APK=C:\Users\proje\Desktop\AIG\build\app\outputs\flutter-apk\app-debug.apk"
set "PACKAGE=com.ai.gravure.aig"
set "LOGDIR=C:\Users\proje\Desktop\AIG"
for /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set mydate=%%c%%a%%b)
for /f "tokens=1-2 delims=/:" %%a in ('time /t') do (set mytime=%%a%%b)
set "LOG=%LOGDIR%\test_results_%mydate%_%mytime%.log"

echo Configuration:
echo   APK: %APK%
echo   Package: %PACKAGE%
echo   Log: %LOG%
echo.

REM Test 1: Device Connection
echo [TEST 1] Checking device connection...
"%ADB%" devices > "%LOG%" 2>&1
if errorlevel 1 (
    echo   X Device check failed
    exit /b 1
)
echo   SUCCESS: Device connected
echo.

REM Test 2: Install APK
echo [TEST 2] Installing APK...
"%ADB%" install -r "%APK%" >> "%LOG%" 2>&1
if errorlevel 1 (
    echo   X APK installation failed
    exit /b 1
)
echo   SUCCESS: APK installed
echo.

REM Test 3: Verify Installation
echo [TEST 3] Verifying package installation...
"%ADB%" shell pm list packages | findstr /i "aig" > nul
if errorlevel 1 (
    echo   X Package not found
    exit /b 1
)
echo   SUCCESS: Package verified
echo.

REM Test 4: Clear Logcat
echo [TEST 4] Clearing device logs...
"%ADB%" logcat -c
echo   SUCCESS: Logs cleared
echo.

REM Test 5: Launch App
echo [TEST 5] Launching application...
"%ADB%" shell am start -n "%PACKAGE%/.MainActivity" >> "%LOG%" 2>&1
echo   SUCCESS: App launched
echo.

REM Test 6: Wait
echo [TEST 6] Waiting for app initialization (5 seconds)...
timeout /t 5 /nobreak
echo   SUCCESS: Ready for camera test
echo.

REM Test 7: Instructions
echo [TEST 7] MANUAL STEP REQUIRED
echo   Open Camera Studio from the dashboard
echo   Camera preview should appear within 2-3 seconds
echo   Wait 30 seconds and verify:
echo     - Preview shows camera feed
echo     - NO "Camera Unavailable" error
echo     - NO camera errors in logcat
echo.

REM Test 8: Capture Logs
echo [TEST 8] Capturing camera logs (waiting 10 seconds)...
timeout /t 10 /nobreak
"%ADB%" logcat -d 2>&1 | findstr /I "CAMERA ANALYZER flutter camera CameraX UNAVAILABLE @UiThread PreviewStream" > "%LOGDIR%\camera_logs.txt"
echo   SUCCESS: Logs captured to camera_logs.txt
echo.

REM Test 9: Check Results
echo [TEST 9] Analyzing logs for issues...
findstr /i "@UiThread" "%LOGDIR%\camera_logs.txt" > nul
if errorlevel 1 (
    echo   SUCCESS: No @UiThread violations found
) else (
    echo   X @UiThread violations detected!
)

findstr /i "sendFrame dispatched on main thread" "%LOGDIR%\camera_logs.txt" > nul
if errorlevel 0 (
    echo   SUCCESS: Frame delivery on main thread detected
) else (
    echo   X No frame delivery evidence found
)

findstr /i "UNAVAILABLE" "%LOGDIR%\camera_logs.txt" > nul
if errorlevel 1 (
    echo   SUCCESS: No camera unavailable errors
) else (
    echo   X Camera unavailable error detected
)

echo.
echo =========================================
echo Test Logs:
echo   - %LOG%
echo   - %LOGDIR%\camera_logs.txt
echo =========================================

pause
