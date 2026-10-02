# AIG — Accredited Institute of Gemology (DiamondCam)

Flutter application for jewelry capture: Camera Studio, ESP32 DiamondCam turntable control, advertising presets, and conservative video finishing.

This repository is the full application backup. A separate ZIP of a dashboard may exist outside this repo.

## Requirements (as used on the development PC)

| Tool | Value used in this workspace | Notes |
|---|---|---|
| Flutter | SDK at `C:\src\flutter` (`sdk: ^3.10.4` in `pubspec.yaml`) | Confirm with `flutter --version` after install |
| Dart | Bundled with Flutter | |
| Android SDK | Standard Android Studio SDK | `compileSdk` / `minSdk` come from the Flutter Gradle plugin |
| Java | JDK 17 (Android Gradle `VERSION_17`) | Set `JAVA_HOME` after PC reset |
| ESP32 | ESP32-WROOM-32 | Arduino sketch in `firmware/DiamondCam` |
| Git LFS | Installed locally (3.7.1) | Not required for this backup (no LFS-tracked files) |

Unknown until you reinstall: exact Flutter channel/version string. Run `flutter --version` on the old machine if you still can, and record it.

## Get the source after a PC reset

```
git clone -b backup/aig-before-pc-reset-2026-10-02 git@github.com:projectbuddycode-art/Project-AIG.git AIG
cd AIG
```

SSH deploy keys or GitHub SSH must be set up on the new PC (`ssh -T git@github.com`).

## Install Flutter dependencies

```
flutter pub get
```

`pubspec.lock` is committed. Keep it.

## Run the app

```
flutter run
```

Or open `android/` / the Flutter project in Android Studio / Cursor and run on a device.

Local testing bypass (already documented in code): `--dart-define=AIG_TEST_MODE=true`. In debug builds, `kDebugMode` also enables local testing mode. Do not treat this as a production auth setting.

## Tests

```
flutter analyze
flutter test
```

## Build APK

```
flutter build apk --debug
```

Release signing: `android/app/build.gradle.kts` currently uses the **debug** signing config for release. No production keystore is in this repository (and must not be committed).

Previous debug APKs lived on the development PC Desktop (`AIG-DiamondCam-Kisan-Final.apk`) and as large `*.apk` files in the project root. Those binaries are **not** in Git (GitHub 100 MB file limit; they are rebuildable). Rebuild after clone.

## ESP32 firmware

- Sketch: `firmware/DiamondCam/DiamondCam.ino`
- Notes: `firmware/DiamondCam/README.md` and `firmware/README.md`

Documented AP / HTTP (from firmware README; verify on hardware):

- SSID: `DiamondCam_Device`
- Password: documented in firmware README as station AP password (not a cloud secret)
- IP: `192.168.4.1` port 80
- Endpoints: `/health`, `/info`, `/status`, `/rotate`, `/rotate/continuous`, `/rotate/stop`, `/light`, `/reset`

The firmware README and the Flutter calibration constants have **disagreed in the past** (for example pulses/rev). After restore, compare `firmware/DiamondCam/README.md` with `lib` machine calibration before flashing.

## Environment / Firebase

There is no local `.env` in this project. Firebase is initialized only when local testing mode is off (`lib/core/services/firebase_initializer.dart`).

`google-services.json` / `GoogleService-Info.plist` were **not present** in the workspace at backup time. If you add them later, keep them out of Git (see `.gitignore`) unless they are intentionally public client configs.

See `.env.example` for dart-define names only.

## Hardware (already documented in-repo)

See firmware README for GPIO (STEP 26, DIR 27, ENABLE 25, LIGHT 33), DM542 notes, and the physical calibration checklist. Do not treat commanded angle as encoder position.

## What is not in Git

- `/build`, `.dart_tool`, Gradle caches
- `/backups` (multi-GB nested copies of older trees)
- `*.apk` and logcat dumps
- `local.properties` (machine SDK paths)
- secrets listed in `.gitignore`
