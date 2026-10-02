@echo off
setlocal enabledelayedexpansion

cd /d c:\Users\proje\Desktop\AIG

echo ========================================
echo FLUTTER ANALYSIS AND BUILD VALIDATION
echo ========================================
echo.

echo [1/3] Running pub get...
call C:\src\flutter\bin\flutter.bat pub get
echo.

echo [2/3] Running flutter analyze...
call C:\src\flutter\bin\flutter.bat analyze > analyze_output.txt 2>&1
type analyze_output.txt
echo.

echo [3/3] Running flutter test...
call C:\src\flutter\bin\flutter.bat test > test_output.txt 2>&1
type test_output.txt
echo.

echo ========================================
echo VALIDATION COMPLETE
echo ========================================
echo Outputs saved to:
echo - analyze_output.txt
echo - test_output.txt
pause
