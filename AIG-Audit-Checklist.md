# AIG Full Codebase Audit — Actionable Checklist

Purpose
- A runnable, prioritized checklist to perform the full production audit described in the supplied audit text.
- Use this as the canonical guide to find, fix, test, build, install, and verify the AIG app before handing it off for hardware testing.

How to use
1. Work top-to-bottom; each main section contains discrete testable items.
2. For UI/button items, create one checklist row per button (automate where possible with ADB/UIAutomator).
3. Record PASS/FAIL and attach evidence (screenshots, logcat snippets, file paths).
4. Do not mark the final "READY" decision until a fresh APK was built from source, old APKs removed from the emulator/device, the fresh APK installed, and the runtime acceptance loop fully executed.

Quick commands
- flutter pub get
- flutter analyze
- flutter test
- flutter build apk --debug

ADB helpers (example)
- adb devices
- adb shell getprop sys.boot_completed
- adb shell pm list packages
- adb uninstall <package>
- adb install <path-to-apk>
- adb shell am force-stop <package>
- adb shell input tap <x> <y>
- adb logcat -v time | grep --line-buffered "FlutterError\|FATAL EXCEPTION"

Audit checklist (master)
- [ ] Create a master test matrix (CSV or spreadsheet) with one row per interactive production button/feature. Columns: screen, button, expected action, actual action, network/native call, result, evidence link, PASS/FAIL, notes.

1) Camera
- [ ] Implement/verify explicit camera state machine: Disconnected, Initializing, Ready/PreviewActive, Capturing, Finalizing, Disposed.
- [ ] Permission flow: check immediately → request if not granted → initialize immediately when granted (no need to leave/reopen screen).
- [ ] Preview truthfulness: only show "Ready" when preview is active (not black screen).
- [ ] Prevent duplicate initialization, double disposal, initialization after disposal, preview races, stale callbacks.
- [ ] Test cases: first launch, permission grant, reopening, repeated entry/exit, background/foreground, repeated captures, repeated video recordings.

2) Photo capture
- [ ] On capture button: ensure preview active before capture.
- [ ] Ensure capture is disabled during processing to prevent duplicates.
- [ ] Verify: real image file received, file exists, file non-empty, persisted to device gallery, inserted into AIG Gallery, accessible after app restart.
- [ ] Show success only after persistence confirmed.

3) Video recording
- [ ] Prevent duplicate starts/stops; make start/stop idempotent.
- [ ] Ensure safe stop during lifecycle changes; wait for finalization.
- [ ] Verify MP4 exists, is non-empty, saved to Android gallery, and appears in AIG Gallery.

4) Device gallery + AIG Gallery
- [ ] For each captured media (photo/video): verify actual file exists → is non-empty → published to Android gallery → appears in AIG Gallery → survives app restart.
- [ ] Do not treat temporary path or in-memory metadata as persisted.

5) Machine / ESP32 connection
- [ ] Enforce truthful connection states: Disconnected, Connecting, Connected/Unverified, Verified, Error, Unreachable.
- [ ] Validate machine identity, firmware, health/status response before marking Verified.
- [ ] For every command: log request, payload, response, timeout/error. Do not show success until acknowledged where protocol supports ack.

6) Rotation controls
- [ ] For each rotation control (Left, Right, Stop, Home, angle/speed controls): validate connection, send exact command, wait for ack if supported, update UI truthfully.
- [ ] Implement throttling/debouncing for continuous or rapid inputs.

7) Lighting controls
- [ ] Audit every light: top, side, back, sparkle, intensity/PWM controls, presets.
- [ ] Ensure correct command/payload/value range; throttle slider updates; handle errors and update UI truthfully.

8) Presets
- [ ] Preset execution must validate machine AND camera preconditions, apply lighting/rotation, wait for required operations, capture if required, verify real result, and save media.
- [ ] Preset must not claim completion if any dependent step fails.

9) UI and Dashboard
- [ ] Remove any debug/floating debug text from production views.
- [ ] Fix overflows, duplicated labels, overlapping components, invisible text, and broken loading states.
- [ ] Ensure no raw exception or Flutter assertion reaches red error screen.

10) Button-by-button audit
- [ ] Produce a row for every interactive production button listed in the master matrix.
- [ ] Automate verification using ADB/UIAutomator where possible; otherwise perform manual steps and attach evidence.

11) Logging and error triage
- [ ] Clear/rotate logcat before final runs.
- [ ] Search logcat for: FATAL EXCEPTION, FlutterError, assertion failures, CameraX errors, platform channel errors, "Cannot add new events after calling close", ANR, uncaught exceptions, media storage errors.
- [ ] Fix root causes for any AIG-originating errors.

12) Build, install, runtime verification
- [ ] Run: flutter pub get → flutter analyze → flutter test → flutter build apk --debug. Fix production-relevant analyzer issues until clean enough per project rules.
- [ ] Locate APK: record absolute path, filename, size, and timestamp.
- [ ] Start emulator, wait for boot, uninstall all old AIG package variants, install only the new APK, confirm installation and package identity.
- [ ] Execute runtime acceptance loop from fresh launch: Dashboard → Machine connection → Camera Studio (permission + preview) → Photo capture (verify file) → Video (verify MP4) → Rotation/Lighting/Presets → Gallery → Export/share → Navigation/back → background/foreground → reopen Camera Studio.
- [ ] Repeat camera open/close multiple times.

13) Emulator automation tips
- [ ] Use `adb shell input` commands and UIAutomator for reproducible flows.
- [ ] Capture screenshots and UI hierarchy dumps for each important verification step.

14) Distinguish software vs hardware verification
- [ ] Do not claim physical verification for results seen only on emulator. Record hardware-pending items separately for physical test team.
- [ ] Before handing to hardware tester: verify app sends exact expected commands and handles responses/errors correctly.

15) Acceptance criteria & final release report
- [ ] FULL CODEBASE AUDIT: PASS/FAIL
- [ ] CAMERA PREVIEW: PASS/FAIL
- [ ] CAMERA RE-ENTRY: PASS/FAIL
- [ ] PERMISSION FLOW: PASS/FAIL
- [ ] PHOTO CAPTURE: PASS/FAIL
- [ ] PHOTO FILE VERIFIED: PASS/FAIL
- [ ] PHOTO DEVICE GALLERY: PASS/FAIL
- [ ] VIDEO RECORDING: PASS/FAIL
- [ ] MP4 VERIFIED: PASS/FAIL
- [ ] VIDEO DEVICE GALLERY: PASS/FAIL
- [ ] AIG GALLERY: PASS/FAIL
- [ ] MACHINE CONNECTION: PASS/FAIL
- [ ] FIRMWARE VERIFICATION: PASS/FAIL
- [ ] ROTATION COMMAND SOFTWARE VERIFICATION: PASS/FAIL
- [ ] LIGHTING COMMAND SOFTWARE VERIFICATION: PASS/FAIL
- [ ] PRESET VERIFICATION: PASS/FAIL
- [ ] BUTTON AUDIT: TOTAL / PASSED / FAILED
- [ ] DASHBOARD/UI: PASS/FAIL
- [ ] NAVIGATION/BACK: PASS/FAIL
- [ ] ANALYZE: PASS/FAIL
- [ ] TESTS: PASS/FAIL + EXACT COUNT
- [ ] APK: ABSOLUTE PATH / FILENAME / SIZE / TIMESTAMP
- [ ] EMULATOR: DEVICE ID / OLD AIG APPS REMOVED: YES/NO / FRESH APK INSTALLED: PASS/FAIL / LAUNCH: PASS/FAIL
- [ ] LOGCAT: AIG CRITICAL ERRORS: EXACT COUNT
- [ ] PHYSICAL HARDWARE: PENDING ITEMS
- [ ] FINAL DECISION: READY FOR KARTIK TEST / NOT READY

Evidence attachments
- For each PASS/FAIL: attach logcat excerpt, screenshot, and file path to persisted media where applicable.

Deliverables that can be produced from this checklist
- A detailed CSV/Spreadsheet master matrix (one row per button/feature).
- A set of ADB/UIAutomator scripts to automate the acceptance loop.
- A short shell script or README with the exact flutter/adk commands and paths used during the run.

Notes
- Never mark UI/feature as successful based solely on in-memory flags, temporary files, or fake success states.
- Prefer the most reliable maintained camera implementation if the current codebase uses an unstable/custom workaround that causes failures.

---

Template: Final Release Report (to be filled after verification)

FULL CODEBASE AUDIT: 
CAMERA PREVIEW: 
CAMERA RE-ENTRY: 
PERMISSION FLOW: 
PHOTO CAPTURE: 
PHOTO FILE VERIFIED: 
PHOTO DEVICE GALLERY: 
VIDEO RECORDING: 
MP4 VERIFIED: 
VIDEO DEVICE GALLERY: 
AIG GALLERY: 
MACHINE CONNECTION: 
FIRMWARE VERIFICATION: 
ROTATION COMMAND SOFTWARE VERIFICATION: 
LIGHTING COMMAND SOFTWARE VERIFICATION: 
PRESET VERIFICATION: 
BUTTON AUDIT: TOTAL / PASSED / FAILED
DASHBOARD/UI: 
NAVIGATION/BACK: 
ANALYZE: 
TESTS: 
APK: ABSOLUTE PATH / FILENAME / SIZE / TIMESTAMP
EMULATOR: DEVICE ID / OLD AIG APPS REMOVED: / FRESH APK INSTALLED: / LAUNCH:
LOGCAT: AIG CRITICAL ERRORS: 
PHYSICAL HARDWARE: PENDING ITEMS
FINAL DECISION: READY FOR KARTIK TEST / NOT READY


# End of checklist
