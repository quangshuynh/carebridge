<p align="center">
  <img src="docs/images/carebridge-logo.png" alt="CareBridge" width="256">
</p>

<p align="center">
  <a href="https://github.com/quangshuynh/carebridge/actions/workflows/ci.yml">
    <img src="https://github.com/quangshuynh/carebridge/actions/workflows/ci.yml/badge.svg" alt="CI">
  </a>
  <a href="https://github.com/quangshuynh/carebridge/actions/workflows/docs.yml">
    <img src="https://github.com/quangshuynh/carebridge/actions/workflows/docs.yml/badge.svg" alt="Docs">
  </a>
  <a href="https://flutter.dev/">
    <img src="https://img.shields.io/badge/Flutter-stable-02569B?logo=flutter&logoColor=white" alt="Flutter">
  </a>
  <a href="LICENSE">
    <img src="https://img.shields.io/badge/License-Apache%202.0-green.svg" alt="Apache 2.0 License">
  </a>
</p>

# CareBridge

CareBridge is an early-stage, local-first communication app. It helps nonverbal people express familiar everyday wants, needs, and routines to caregivers through large visual choices and spoken phrases.

<p align="center">
  <img src="docs/images/screenshots/phone-portrait-selected.png" alt="CareBridge on a phone in portrait with Drink selected" height="420">
  &nbsp;
  <img src="docs/images/screenshots/tablet-landscape-selected.png" alt="CareBridge on a tablet in landscape with Food selected" height="420">
</p>

## What it does

- Shows six large sample choices: Food, Drink, Drive, Help, Rest, and Finished.
- One tap marks the choice, shows its picture and phrase, speaks the phrase with the device's text-to-speech, and gives a light haptic tap.
- Keeps every choice visible and in place on phones and tablets, in portrait and landscape.
- Works offline with no account. CareBridge has no cloud service, analytics, or advertising.

The six choices are demo content. Personalization, caregiver editing, and saved data are not built yet.

CareBridge is not a medical device, diagnostic tool, or treatment, and it does not replace professional AAC assessment. A selection communicates only its configured phrase.

## Status and platforms

CareBridge is a foundation for real-world usability testing, not production use. It targets **Android, iOS, and iPadOS**. CI builds all three, but physical-device testing is still outstanding.

## Quick start

With the stable [Flutter SDK](https://docs.flutter.dev/get-started/install) installed:

```sh
flutter pub get
flutter run
flutter test
```

iPhone and iPad builds require macOS with Xcode. See [Getting started](https://quangshuynh.github.io/carebridge/getting-started/) for device setup.

## Documentation

The full documentation is at **[quangshuynh.github.io/carebridge](https://quangshuynh.github.io/carebridge/)**:

- [Communicator board](https://quangshuynh.github.io/carebridge/communicator-board/): exact interaction behavior
- [Accessibility](https://quangshuynh.github.io/carebridge/accessibility/) and [Privacy](https://quangshuynh.github.io/carebridge/privacy/)
- [Architecture](https://quangshuynh.github.io/carebridge/architecture/)
- [Device validation](https://quangshuynh.github.io/carebridge/device-validation/) checklist

The source for these pages is in [`docs/`](docs/).

## Contributing

Issues and focused pull requests are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

CareBridge is licensed under the [Apache License 2.0](LICENSE).
