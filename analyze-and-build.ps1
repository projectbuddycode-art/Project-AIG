# Flutter Build and Analysis Script
$flutterPath = "C:\src\flutter\bin\flutter.bat"
$projectRoot = "c:\Users\proje\Desktop\AIG"

Push-Location $projectRoot

Write-Host "====== FLUTTER ANALYSIS ======" -ForegroundColor Cyan
& $flutterPath analyze 2>&1 | Tee-Object -Variable analyzeOutput
$analyzeResult = ($analyzeOutput | Measure-Object -Line).Lines

Write-Host ""
Write-Host "====== FLUTTER TEST ======" -ForegroundColor Cyan
& $flutterPath test 2>&1 | Tee-Object -Variable testOutput
$testResult = ($testOutput | Measure-Object -Line).Lines

Write-Host ""
Write-Host "====== APK BUILD ======" -ForegroundColor Cyan
& $flutterPath clean
& $flutterPath pub get  
& $flutterPath build apk --debug 2>&1 | Tee-Object -Variable buildOutput
$buildResult = $LASTEXITCODE

Write-Host ""
Write-Host "====== RESULTS ======" -ForegroundColor Green
Write-Host "Analyze Result: $analyzeResult lines"
Write-Host "Test Result: $testResult lines"  
Write-Host "Build Exit Code: $buildResult"

if (Test-Path "build\app\outputs\flutter-apk\app-debug.apk") {
    $apkFile = Get-Item "build\app\outputs\flutter-apk\app-debug.apk"
    Write-Host "APK FOUND:"
    Write-Host "  Path: $($apkFile.FullName)"
    Write-Host "  Size: $([math]::Round($apkFile.Length/1MB, 2)) MB"
    Write-Host "  Time: $($apkFile.LastWriteTime)"
} else {
    Write-Host "APK NOT FOUND"
}

Pop-Location
