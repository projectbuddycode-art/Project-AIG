# Clean Install Validation Script for AIG
# This script performs the complete clean-install emulator validation

$ErrorActionPreference = "Continue"
$DebugPreference = "Continue"

$adbPath = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
$apkPath = "c:\Users\proje\Desktop\AIG\build\app\outputs\flutter-apk\app-debug.apk"
$packageName = "com.ai.gravure.aig"

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "STEP 1: Verify Emulator Status" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

Write-Host "ADB Path: $adbPath"
Write-Host "ADB Exists: $(Test-Path $adbPath)"

Write-Host ""
Write-Host "Connected devices:" -ForegroundColor Green
& $adbPath devices

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "STEP 2: Identify AIG Package" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

Write-Host "Target Package: $packageName"
Write-Host ""
Write-Host "Checking installed packages containing AIG/Gravure/Diamond:" -ForegroundColor Green
& $adbPath shell pm list packages | Select-String -Pattern "aig|gravure|diamond" -CaseSensitive:$false

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "STEP 3: Uninstall Old AIG Variants" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

Write-Host "Uninstalling old AIG package: $packageName" -ForegroundColor Yellow
& $adbPath uninstall $packageName

Write-Host ""
Write-Host "Verifying removal..." -ForegroundColor Green
$stillInstalled = & $adbPath shell pm list packages | Select-String -Pattern $packageName
if ($stillInstalled) {
    Write-Host "WARNING: Package still installed!" -ForegroundColor Red
    Write-Host $stillInstalled
} else {
    Write-Host "✓ Package successfully removed" -ForegroundColor Green
}

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "STEP 4-5: Verify New APK" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

if (Test-Path $apkPath) {
    $file = Get-Item $apkPath
    Write-Host "✓ APK Found" -ForegroundColor Green
    Write-Host "Exact path: $($file.FullName)"
    Write-Host "Filename: $($file.Name)"
    Write-Host "Size: $([math]::Round($file.Length/1MB, 2)) MB"
    Write-Host "Size (bytes): $($file.Length)"
    Write-Host "Last Modified: $($file.LastWriteTime)"
} else {
    Write-Host "✗ APK NOT FOUND: $apkPath" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "STEP 6: Install Fresh APK" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

Write-Host "Installing APK..." -ForegroundColor Yellow
$installResult = & $adbPath install -r $apkPath 2>&1
Write-Host $installResult

if ($installResult -match "Success") {
    Write-Host "✓ Installation succeeded" -ForegroundColor Green
    $installStatus = "PASS"
} else {
    Write-Host "✗ Installation may have failed" -ForegroundColor Red
    $installStatus = "FAIL"
}

Write-Host ""
Write-Host "Verifying installed package..." -ForegroundColor Green
$installed = & $adbPath shell pm list packages | Select-String -Pattern $packageName
if ($installed) {
    Write-Host "✓ Package is installed: $installed" -ForegroundColor Green
} else {
    Write-Host "✗ Package not found after install" -ForegroundColor Red
}

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "STEP 7: Launch Application" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

Write-Host "Launching $packageName/.MainActivity" -ForegroundColor Yellow
& $adbPath shell am start -n "$packageName/.MainActivity" 2>&1

Write-Host "Waiting 3 seconds for app to launch..." -ForegroundColor Gray
Start-Sleep -Seconds 3

Write-Host "✓ Application launch command sent" -ForegroundColor Green

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "STEP 8-9: Capture Initial Logcat" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

Write-Host "Clearing logcat..." -ForegroundColor Yellow
& $adbPath logcat -c

Write-Host "Starting logcat capture (will run in background)..." -ForegroundColor Yellow
# Capture logcat asynchronously
& $adbPath logcat -v brief | Out-File -FilePath "c:\Users\proje\Desktop\AIG\logcat_clean_install.txt" -Append &

Write-Host "Logcat will be saved to: c:\Users\proje\Desktop\AIG\logcat_clean_install.txt" -ForegroundColor Gray

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "SUMMARY - APK INSTALLATION COMPLETE" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "APK Path: $apkPath"
Write-Host "Package: $packageName"
Write-Host "Install Status: $installStatus"
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Check emulator screen for app launch and Camera Studio"
Write-Host "2. Test camera permission request and automatic startup"
Write-Host "3. Verify live preview appears without black screen"
Write-Host "4. Test capture controls, photo, video"
Write-Host "5. Review logcat for critical errors"
Write-Host ""
