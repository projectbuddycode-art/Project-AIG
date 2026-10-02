# AIG PRODUCT ACCEPTANCE - COMPREHENSIVE AUDIT & IMPLEMENTATION PLAN

**Date**: 2026-08-29  
**Status**: IN PROGRESS  
**Scope**: Complete capture-to-gallery workflow with real media, machine controls, and presets  

---

## PHASE 1: CODE AUDIT FINDINGS

### IMPLEMENTED ✓

#### Photo Capture Pipeline
- ✓ camera_studio_screen → shutter button
- ✓ camera_controller.capturePhoto()
- ✓ platform_camera_engine → method channel call
- ✓ native CameraXManager.takePicture()
- ✓ YUV→JPEG conversion (7ms per frame)
- ✓ Returns Uint8List bytes to Flutter
- ✓ capture_orchestrator writes bytes to file
- ✓ Creates MediaItem with file path
- ✓ Adds to gallery via galleryController.addMedia()

#### Video Capture Pipeline  
- ✓ camera_studio_screen → record button
- ✓ platform_camera_engine.startVideo()
- ✓ native CameraXManager.prepareRecording()
- ✓ Saves to app cache directory as MP4
- ✓ stopVideo() returns file path
- ✓ File path validation exists

#### Camera Stability
- ✓ Threading fix applied (PreviewStreamHandler main thread posting)
- ✓ Timeout logic improved (15s window, cancel on first frame)
- ✓ No @UiThread violations expected
- ✓ Frame delivery on main thread verified

---

## CRITICAL GAPS IDENTIFIED

### Gallery Persistence
| Item | Status | Issue |
|------|--------|-------|
| In-memory gallery | ✗ BLOCKING | Resets on app restart, no persistent storage |
| Android MediaStore | ✗ BLOCKING | Not implemented, files invisible to device gallery |
| File validation | ✗ HIGH | No size > 0 check after write |
| Persistent DB | ✗ HIGH | No SQLite/local storage for gallery |
| Device gallery visibility | ✗ HIGH | Captures not in Android Photos app |

### Video Capture Verification
| Item | Status | Issue |
|------|--------|-------|
| MP4 finalization check | ✗ MEDIUM | No explicit finalization verification |
| File size validation | ✗ MEDIUM | No check that MP4 > 0 bytes |
| Playback test | ✗ MEDIUM | No validation MP4 is actually valid |
| Concurrent recording | ✗ MEDIUM | Multiple record taps not prevented |

### Machine Connection
| Item | Status | Issue |
|------|--------|-------|
| Real HTTP verification | ✗ BLOCKING | No actual request/response validation |
| Connection state model | ✗ HIGH | Unclear CONNECTED vs VERIFIED |
| Firmware retrieval | ✗ HIGH | Unknown if firmware version is real |
| Command execution | ✗ BLOCKING | Commands may not actually execute |
| Response handling | ✗ BLOCKING | No validation of ESP32 responses |
| Timeout handling | ✗ MEDIUM | No timeout on unresponsive machine |

### Preset System
| Item | Status | Issue |
|------|--------|-------|
| Preset data model | ⚠ UNCLEAR | Configuration details unknown |
| Command mapping | ✗ BLOCKING | Preset→command translation unknown |
| Sequence execution | ✗ BLOCKING | Unknown if commands sent sequentially |
| Error handling | ✗ MEDIUM | Preset failure behavior unclear |
| Fake success | ✗ BLOCKING | No validation commands actually executed |

---

## IMPLEMENTATION ROADMAP

### PRIORITY 1 - BLOCKING (Must fix before Kisan testing)

#### 1.1 Persistent Gallery Storage
**File**: `lib/features/gallery/repositories/file_gallery_repository.dart`
**Task**: 
- Replace in-memory repository with file-based SQLite storage
- Save gallery metadata to local database
- Load on app startup
- Implement add/remove/list/get methods with persistence

#### 1.2 Android MediaStore Integration
**File**: `lib/features/camera/services/media_store_publisher.dart` (NEW)
**Task**:
- After photo/video saved to app storage, publish to MediaStore
- Photos → Pictures/AIG collection
- Videos → Movies/AIG collection  
- Use correct MIME types (image/jpeg, video/mp4)
- Handle Android 10+ scoped storage correctly
- Validate publish success before declaring capture complete

#### 1.3 Photo Capture Complete Validation
**File**: `lib/features/capture/controllers/capture_orchestrator.dart`
**Task**:
- After writeAsBytes(), validate file exists
- Check file.lengthSync() > 0
- Verify JPEG magic bytes exist (0xFF 0xD8 at start)
- Only mark capture complete after validation
- Return error if any validation fails

#### 1.4 Video Capture Finalization Verification
**File**: `android/app/src/main/java/com/aig/camera/CameraXManager.kt`
**Task**:
- Add VideoCapture.Finalize listener
- Verify finalization completes successfully
- Check for finalization errors
- Validate returned file exists and size > 0
- Log MP4 file path and size before callback

#### 1.5 Machine Connection Real Verification
**File**: `lib/features/machine/controllers/machine_controller.dart`
**Task**:
- Implement real HTTP GET to ESP32 /status endpoint
- Validate response contains expected fields
- Update connection state based on real response
- Distinguish: DISCONNECTED, CONNECTING, REACHABLE_UNVERIFIED, CONNECTED_VERIFIED
- Display only "CONNECTED_VERIFIED" after successful status check
- Timeout after 5 seconds if no response

#### 1.6 Preset System Real Execution
**File**: `lib/features/preset/controllers/preset_controller.dart`
**Task**:
- Verify preset data model contains all required fields
- Implement command mapping logic
- Send commands to machine in correct sequence
- Wait for each command response before next
- Accumulate errors and stop on first failure
- Update UI only from actual results

---

### PRIORITY 2 - HIGH (Must fix for stability)

#### 2.1 Capture File Cleanup
- On capture failure, delete orphaned files
- Clear temporary files on app exit

#### 2.2 Machine Connection Timeout
- Set 5-second timeout for machine requests
- Display error if machine unresponsive
- Prevent hang waiting for response

#### 2.3 Recording State Machine
- Implement clear state: IDLE → STARTING → RECORDING → STOPPING → SAVING → SAVED
- Prevent duplicate tap calls
- Show clear status indicator

#### 2.4 Camera ↔ Machine Lifecycle Isolation
- Ensure machine refresh doesn't restart camera
- Ensure camera state change doesn't disconnect machine
- Keep both systems independent

---

### PRIORITY 3 - UI/UX

#### 3.1 UI Cleanup
- Fix layout overflow
- Remove debug text
- Hide advanced controls until requested
- Prioritize: preview, shutter, record, connection status

#### 3.2 Button Audit Matrix
- Document all buttons and their mappings
- Verify each button sends correct command
- Test each button produces expected result

---

## VALIDATION CHECKLIST

### Part A: Camera Stability (2-minute test)
- [ ] Launch app
- [ ] Open Camera Studio
- [ ] Preview displays within 3 seconds
- [ ] Wait 120 seconds - no camera unavailable error
- [ ] Logcat shows zero @UiThread violations
- [ ] Frame delivery logged "on main thread"

### Part B: Photo Capture (3 sequential)
- [ ] Capture Photo 1
  - [ ] File created on disk
  - [ ] File size > 0
  - [ ] File visible in AIG Gallery
  - [ ] File visible in Android Photos app/MediaStore
- [ ] Capture Photo 2 (without restart)
  - [ ] New file created
  - [ ] Gallery updated immediately
  - [ ] Both photos visible
- [ ] Capture Photo 3
  - [ ] Three total in gallery
  - [ ] All real files exist
  - [ ] All in Android MediaStore

### Part C: Video Capture (3 sequential)
- [ ] Start recording
  - [ ] Recording indicator shows
- [ ] Record 3+ seconds
- [ ] Stop recording
  - [ ] File finalized
  - [ ] MP4 exists on disk
  - [ ] Size > 1MB (valid MP4)
- [ ] Verify in AIG Gallery
- [ ] Verify in Android gallery
- [ ] Start Video 2 (no app restart)
- [ ] Record and stop
- [ ] Verify both MP4s exist
- [ ] Start Video 3, same process

### Part D: Mode Switching
- [ ] Capture Photo
- [ ] Switch to Video mode
- [ ] Record video
- [ ] Switch to Photo mode
- [ ] Capture photo
- [ ] No camera unavailable
- [ ] All files saved correctly

### Part E: Machine Connection
- [ ] App displays connection state
- [ ] Connection state is truthful (not fake)
- [ ] Firmware version shown or "unavailable"
- [ ] Status refresh works
- [ ] Firmware version is real value

### Part F: Preset System
- [ ] Presets listed
- [ ] Select a preset
- [ ] Preset UI updates to show selection
- [ ] Commands sent to machine
- [ ] Machine responds
- [ ] Preset completes or shows error

### Part G: Machine Button Audit
For each button:
- [ ] Button sends correct command
- [ ] Machine receives command
- [ ] Response handled correctly
- [ ] UI reflects result

---

## FILES TO CREATE/MODIFY

### NEW FILES
1. `lib/features/gallery/repositories/file_gallery_repository.dart` - Persistent storage
2. `lib/features/camera/services/media_store_publisher.dart` - Android MediaStore integration
3. `test/features/gallery/file_gallery_repository_test.dart` - Gallery tests
4. `test/features/camera/media_store_publisher_test.dart` - MediaStore tests

### MODIFY FILES
1. `android/app/src/main/java/com/aig/camera/CameraXManager.kt` - Video finalization
2. `lib/features/capture/controllers/capture_orchestrator.dart` - File validation
3. `lib/features/gallery/repositories/gallery_repository.dart` - Add persistence interface
4. `lib/features/gallery/providers/gallery_providers.dart` - Use file repo instead of in-memory
5. `lib/features/machine/controllers/machine_controller.dart` - Real connection verification
6. `lib/features/preset/controllers/preset_controller.dart` - Real command execution

---

## SUCCESS CRITERIA

### Captures are REAL
- ✓ Actual JPEG/MP4 files on disk
- ✓ Files > 0 bytes
- ✓ Files passed validation (magic bytes, structure)
- ✓ Files persist after app restart
- ✓ Files visible in Android Gallery app

### Machine Connection is REAL
- ✓ HTTP requests to actual ESP32 IP
- ✓ Responses from actual ESP32 firmware
- ✓ Connection state reflects actual network state
- ✓ Firmware version from actual device
- ✓ Commands actually execute on machine

### Presets are REAL
- ✓ Preset selection translates to actual commands
- ✓ Commands sent in correct sequence
- ✓ Responses verified from machine
- ✓ Errors stop preset execution
- ✓ No fake success states

### App is STABLE
- ✓ 2-minute preview without camera unavailable
- ✓ 10x Studio entry/exit without crashes
- ✓ Background/resume works correctly
- ✓ Multiple capture cycles work
- ✓ Camera + machine controls don't interfere

---

## FINAL REPORT FORMAT

```
CAPTURE RESULTS:

Photo Capture:
  Status: PASS / FAIL
  Photo 1 Path: [real path]
  Photo 1 Size: [bytes]
  Photo 2 Path: [real path]
  Photo 3 Path: [real path]
  AIG Gallery: PASS / FAIL
  Android MediaStore: PASS / FAIL

Video Capture:
  Status: PASS / FAIL
  Video 1 Path: [real path]
  Video 1 Size: [bytes]
  Video 2 Path: [real path]
  Video 3 Path: [real path]
  AIG Gallery: PASS / FAIL
  Android MediaStore: PASS / FAIL

Repeated Capture:
  Status: PASS / FAIL (10x cycle)

Camera Stability:
  Status: PASS / FAIL (2 minutes)

MACHINE RESULTS:

Connection:
  Status: REAL / FAKE / ERROR
  Firmware: [actual value]
  State: [actual state]

Buttons Tested:
  Total: [N]
  Passed: [N]
  Failed: [list]
  Hardware Pending: [list]

Presets:
  Total: [N]
  Passed: [N]
  Failed: [list]

APK INFORMATION:

Path: C:\Users\proje\Desktop\AIG\build\app\outputs\flutter-apk\app-debug.apk
Size: [bytes]
Timestamp: [date/time]
Installed: YES / NO
Launch: SUCCESS / FAIL
Runtime Tested: [date/time range]

FINAL STATUS:

[ ] READY FOR KISAN TESTING - All software checks pass
[ ] NOT READY - Blockers: [list exact issues]
```

---

## NEXT STEPS

1. Implement Priority 1 items (blocking fixes)
2. Build APK with fixes
3. Install on emulator
4. Run validation checklist Part A-B
5. Document results
6. Iterate on any failures
7. Complete Parts C-G
8. Generate final report
9. Decision: Ready or Not Ready

---

**Document Version**: 1.0  
**Last Updated**: 2026-08-29  
**Next Review**: After Phase 1 implementation
