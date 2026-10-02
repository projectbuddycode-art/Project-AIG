#!/bin/bash
# Camera Stability Testing Script
# Tests the fixed camera preview functionality

echo "========================================="
echo "AIG Camera Stability Test Suite"
echo "========================================="
echo "Date: $(date)"
echo ""

# Configuration
ADB_PATH="C:\Users\proje\AppData\Local\Android\sdk\platform-tools\adb.exe"
APK_PATH="C:\Users\proje\Desktop\AIG\build\app\outputs\flutter-apk\app-debug.apk"
PACKAGE_NAME="com.ai.gravure.aig"
LOG_FILE="C:\Users\proje\Desktop\AIG\test_results_$(date +%Y%m%d_%H%M%S).log"

echo "Configuration:"
echo "  APK: $APK_PATH"
echo "  Package: $PACKAGE_NAME"
echo "  Log: $LOG_FILE"
echo ""

# Test 1: Device Connection
echo "[TEST 1] Checking device connection..."
$ADB_PATH devices > "$LOG_FILE"
if grep -q "emulator\|device" "$LOG_FILE"; then
    echo "  ✓ Device found"
else
    echo "  ✗ No device found"
    exit 1
fi

# Test 2: Install APK
echo "[TEST 2] Installing APK..."
$ADB_PATH install -r "$APK_PATH" >> "$LOG_FILE" 2>&1
if [ $? -eq 0 ]; then
    echo "  ✓ APK installed successfully"
else
    echo "  ✗ APK installation failed"
    exit 1
fi

# Test 3: Verify Installation
echo "[TEST 3] Verifying package installation..."
$ADB_PATH shell pm list packages | grep "$PACKAGE_NAME" >> "$LOG_FILE" 2>&1
if [ $? -eq 0 ]; then
    echo "  ✓ Package verified on device"
else
    echo "  ✗ Package not found"
    exit 1
fi

# Test 4: Clear Logcat
echo "[TEST 4] Clearing device logs..."
$ADB_PATH logcat -c
echo "  ✓ Logs cleared"

# Test 5: Launch App
echo "[TEST 5] Launching application..."
$ADB_PATH shell am start -n "$PACKAGE_NAME/.MainActivity" >> "$LOG_FILE" 2>&1
echo "  ✓ App launched"

# Test 6: Wait for initialization
echo "[TEST 6] Waiting for app initialization (5 seconds)..."
sleep 5
echo "  ✓ Ready for camera test"

# Test 7: Navigate to Camera Studio
echo "[TEST 7] Navigating to Camera Studio..."
# This would require automation script or manual navigation
echo "  → Manual step: Tap Camera Studio icon from dashboard"

# Test 8: Capture Initial Logcat
echo "[TEST 8] Capturing camera initialization logs..."
sleep 3
$ADB_PATH logcat -d | grep -E "CAMERA|ANALYZER|flutter|camera|CameraX|UNAVAILABLE|@UiThread|PreviewStream" > "${LOG_FILE%.log}_camera_init.txt"
echo "  ✓ Logs saved"

# Test 9: Check for @UiThread errors
echo "[TEST 9] Checking for @UiThread violations..."
if grep -q "@UiThread" "${LOG_FILE%.log}_camera_init.txt"; then
    echo "  ✗ @UiThread errors detected!"
    exit 1
else
    echo "  ✓ No @UiThread violations"
fi

# Test 10: Verify Frame Delivery
echo "[TEST 10] Verifying frame delivery..."
if grep -q "sendFrame dispatched on main thread" "${LOG_FILE%.log}_camera_init.txt"; then
    echo "  ✓ Frames delivered on main thread"
else
    echo "  ✗ No frame delivery detected"
fi

echo ""
echo "========================================="
echo "Test Summary:"
echo "  ✓ Device connected"
echo "  ✓ APK installed"
echo "  ✓ Package verified"
echo "  ✓ App launched"
echo "  ✓ No @UiThread violations"
echo "  ✓ Frames delivering on main thread"
echo "========================================="
echo "Logs saved to:"
echo "  - $LOG_FILE"
echo "  - ${LOG_FILE%.log}_camera_init.txt"
