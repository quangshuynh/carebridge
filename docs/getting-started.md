# Getting started

This page covers running CareBridge from source on an emulator, simulator, or physical device.

!!! note "Deployment is not validation"
    These steps install a development build. Following them does not mean the current build has passed physical-device testing. Use the [device validation checklist](device-validation.md) when testing on real hardware.

## Prerequisites

- The current stable [Flutter SDK](https://docs.flutter.dev/get-started/install). The project requires Dart 3.13.4 or later, which recent stable Flutter releases include.
- Git.
- For Android: Android Studio or the Android command-line tools, and a JDK. CI builds with Temurin 17.
- For iPhone and iPad: a Mac with Xcode. See [Apple devices](#apple-devices).

Run `flutter doctor` and resolve anything it reports for the platforms you plan to use.

## Clone and run

```sh
git clone https://github.com/quangshuynh/carebridge.git
cd carebridge
flutter pub get
flutter run
```

`flutter run` picks a connected device or asks you to choose one. List devices with `flutter devices` and pass one explicitly with `-d <device-id>`.

## Run the tests

```sh
flutter test
```

The full set of checks that CI runs is listed in [Contributing](contributing.md#development-checks).

## Android devices

1. Enable developer options and USB debugging on the device.
2. Connect it by USB and accept the debugging prompt if one appears.
3. Confirm the device is listed, then run the app:

```sh
flutter devices
flutter run -d <android-device-id>
```

You can build and deploy Android from Windows, macOS, or Linux.

## Apple devices

iOS and iPadOS builds require macOS with Xcode. They cannot be built or deployed from Windows or Linux.

1. On a Mac, install Flutter and Xcode.
2. Open `ios/Runner.xcworkspace` in Xcode, select the **Runner** target, and choose a development team under **Signing & Capabilities**.
3. Connect the iPhone or iPad and trust the computer. Apple may also require you to enable Developer Mode on the device.
4. Confirm the device is listed, then run the app:

```sh
flutter devices
flutter run -d <apple-device-id>
```

The project targets iOS 15.0 and later.

## Platform limitations

- Only Android, iOS, and iPadOS are supported. The repository contains no web or desktop platform projects.
- CI compiles an Android debug APK and an unsigned iOS debug build. These are build checks only. They do not install or run the app on a device.
- Speech uses the device's own text-to-speech engine. Voice quality, available voices, and offline behavior vary by device and settings. See [Privacy](privacy.md#text-to-speech).
