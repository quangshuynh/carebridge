<p align="center">
  <img src="docs/images/carebridge-logo.png" alt="CareBridge" width="256">
</p>

<p align="center">
  <a href="https://github.com/quangshuynh/carebridge/actions/workflows/ci.yml">
    <img src="https://github.com/quangshuynh/carebridge/actions/workflows/ci.yml/badge.svg" alt="CI">
  </a>
  <a href="https://flutter.dev/">
    <img src="https://img.shields.io/badge/Flutter-stable-02569B?logo=flutter&logoColor=white" alt="Flutter">
  </a>
  <a href="https://dart.dev/">
    <img src="https://img.shields.io/badge/Dart-stable-0175C2?logo=dart&logoColor=white" alt="Dart">
  </a>
  <a href="LICENSE">
    <img src="https://img.shields.io/badge/License-Apache%202.0-green.svg" alt="Apache 2.0 License">
  </a>
</p>

# CareBridge

CareBridge is an early-stage, local-first communication app that helps nonverbal people express familiar everyday wants, needs, and routines to caregivers through large visual choices and spoken phrases.

The current vertical slice provides six sample choices—Food, Drink, Drive, Help, Rest, and Finished. Selecting one gives immediate visual confirmation and uses on-device text-to-speech. No account or internet connection is needed for communication.

## Status and platforms

CareBridge is a small foundation intended for real-world usability testing, not production use. Android, iOS, and iPadOS are first-class targets. Physical-device accessibility and speech testing is still required.

CareBridge is not a diagnostic tool, medical device, treatment, intent-inference system, or replacement for professional AAC assessment. A selection communicates only its caregiver-configured phrase.

## Privacy and local-first design

Core communication must remain available offline and on the device. There is no authentication, cloud synchronization, analytics, advertising, or AI. Selection events exist only in memory for the running session; durable local persistence is deliberately deferred until its data lifecycle and caregiver controls are designed.

## Run on a physical Android device

Install the current stable [Flutter SDK](https://docs.flutter.dev/get-started/install)
and Android tooling, enable developer options and USB debugging on the device, and
connect it by USB. Then run:

```sh
flutter doctor
flutter devices
flutter pub get
flutter run -d <android-device-id>
```

Accept the device's debugging prompt if shown. `flutter devices` must list the
device before deployment. These are deployment instructions, not a claim that the
current build has completed physical-device validation.

## Run on a physical iPhone or iPad

iOS/iPadOS deployment requires macOS with Xcode; it cannot be built or deployed
from Windows. On a Mac, install Flutter and Xcode, open `ios/Runner.xcworkspace` in
Xcode, select the Runner target, and configure a development team for signing.
Connect and trust the iPhone or iPad, then run:

```sh
flutter doctor
flutter devices
flutter pub get
flutter run -d <apple-device-id>
```

Apple may require Developer Mode and trust confirmation on the device. These steps
do not imply that the app has already been physically validated on Apple hardware.
Use the [real-device validation checklist](docs/REAL_DEVICE_VALIDATION.md) on both
platforms.

## Development checks

```sh
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug
```

## Architecture

Domain models hold profiles, categories, choices, visuals, ordering, enabled state, and communication events. A small controller owns interaction state and guards rapid duplicate activation. Presentation widgets render that state. Text-to-speech sits behind a narrow interface so tests and future platform behavior stay independent of the UI.

## Caregiver editing direction

Editing is intentionally absent from the communicator board. A later caregiver mode should require a deliberate long-press followed by a caregiver-controlled PIN or device authentication, live in a separate route, and return explicitly to a locked communicator mode.

## Contributing

Issues and focused pull requests are welcome. Prioritize observable communicator needs, offline reliability, accessibility, and the smallest testable change. See [CONTRIBUTING.md](CONTRIBUTING.md).
