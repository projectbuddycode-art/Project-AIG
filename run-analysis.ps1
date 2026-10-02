cd c:\Users\proje\Desktop\AIG

Write-Host "Starting Flutter analysis..." -ForegroundColor Cyan
Write-Host ""

# Run pub get
Write-Host "[1/3] Running pub get..." -ForegroundColor Yellow
& C:\src\flutter\bin\flutter.bat pub get 2>&1 | Out-File -FilePath "pubget_output.log" -Force
$pubOutput = Get-Content "pubget_output.log" -Tail 5
Write-Host $pubOutput

# Run flutter analyze
Write-Host "[2/3] Running flutter analyze..." -ForegroundColor Yellow
$analyze = & C:\src\flutter\bin\flutter.bat analyze 2>&1
$analyze | Out-File -FilePath "analyze_output.log" -Force
Write-Host $analyze | Select-Object -First 50
Write-Host ""
Write-Host "Full analyze output written to: analyze_output.log" -ForegroundColor Green

# Run flutter test
Write-Host "[3/3] Running flutter test..." -ForegroundColor Yellow
$test = & C:\src\flutter\bin\flutter.bat test 2>&1
$test | Out-File -FilePath "test_output.log" -Force
Write-Host $test | Select-Object -First 50
Write-Host ""
Write-Host "Full test output written to: test_output.log" -ForegroundColor Green

Write-Host ""
Write-Host "Analysis and testing complete!" -ForegroundColor Cyan
