# AIG recovery after PC reset

Repository: `git@github.com:projectbuddycode-art/Project-AIG.git`

## 1. Install tools on the new PC

1. Git for Windows (SSH key added to GitHub user `projectbuddycode-art`).
2. Flutter SDK (place it somewhere stable, e.g. `C:\src\flutter`). `pubspec.yaml` requires Dart SDK `^3.10.4`.
3. Android Studio or command-line Android SDK, with a JDK 17 compatible with the Android Gradle plugin.
4. Accept Android licenses: `flutter doctor --android-licenses`.
5. Optional: Arduino IDE / arduino-cli for ESP32 firmware.

## 2. Clone

```
git clone -b backup/aig-before-pc-reset-2026-10-02 git@github.com:projectbuddycode-art/Project-AIG.git AIG
cd AIG
flutter pub get
flutter analyze
flutter test
```

## 3. Android local paths

Create `android/local.properties` (not in Git) with your SDK locations, or let Flutter/Android Studio generate it:

```
sdk.dir=C:\\Users\\<you>\\AppData\\Local\\Android\\Sdk
flutter.sdk=C:\\src\\flutter
```

## 4. Run / build

```
flutter run
flutter build apk --debug
```

The previous Desktop APK `AIG-DiamondCam-Kisan-Final.apk` is not stored in Git. Rebuild it.

## 5. Machine

Connect the phone to Wi-Fi `DiamondCam_Device` and use Machine Control / Camera Studio. See `firmware/DiamondCam/README.md`.

## 6. What you still need from the old PC (not in Git)

- Any ZIP dashboard backup you already made
- Debug APKs if you want them without rebuilding
- Nested `backups/` folder (~3.5 GB of old copies) if you still need history outside Git
- Any keystore you create later
- Firebase `google-services.json` if you enable production Firebase (it was missing locally at backup time)
