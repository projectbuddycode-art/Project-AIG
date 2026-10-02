@echo off
cd /d "c:\Users\proje\Desktop\AIG"
echo ====== Running Flutter Analyze ======
call C:\src\flutter\bin\flutter.bat analyze
echo.
echo ====== Running Flutter Test ======
call C:\src\flutter\bin\flutter.bat test
echo.
echo ====== Building APK ======
call C:\src\flutter\bin\flutter.bat clean
call C:\src\flutter\bin\flutter.bat pub get
call C:\src\flutter\bin\flutter.bat build apk --debug
echo.
echo ====== Build Complete ======
if exist "build\app\outputs\flutter-apk\app-debug.apk" (
    echo APK READY: build\app\outputs\flutter-apk\app-debug.apk
    dir /S "build\app\outputs\flutter-apk\app-debug.apk"
) else (
    echo ERROR: APK not found
)
pause
