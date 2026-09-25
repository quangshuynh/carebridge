# Contributing

Issues and focused pull requests are welcome. The contribution rules live in [CONTRIBUTING.md](https://github.com/quangshuynh/carebridge/blob/main/CONTRIBUTING.md) in the repository. This page covers the practical development tasks around them.

Good contributions start from observable communicator needs and favor offline reliability, accessibility, and the smallest testable change.

## Development checks

CI runs these on every pull request. Run them locally before opening one:

```sh
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug
```

CI also builds an unsigned iOS debug build on macOS with `flutter build ios --debug --no-codesign`.

## Screenshots

The screenshots in `docs/images/screenshots/` are rendered by Flutter's test renderer using the Roboto and Material Icons fonts bundled with the Flutter SDK. They show no device status bar, navigation bar, or notch. Regenerate them after visual changes:

```sh
flutter test tool/screenshots/capture_screenshots_test.dart
```

## Branding

App icons, launch images, and this site's logo use the figure mark from `docs/images/carebridge0-logo.png`, without the wordmark. The mark is cropped and scaled, never redrawn. Regenerate every variant with:

```sh
python tool/branding/generate_app_icons.py
```

The script requires Python 3 and Pillow.

## Documentation

Detailed product and developer documentation lives in this site, under `docs/`. The repository README is a short landing page that links here.

The site is built with [MkDocs](https://www.mkdocs.org/) and [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/). Its Python tooling is separate from the Flutter app. To preview it locally:

```sh
python -m pip install -r requirements-docs.txt
mkdocs serve
```

Before opening a pull request that touches documentation, check that the site builds without warnings:

```sh
mkdocs build --strict
```

Pull requests run the same strict build. Changes merged to `main` are published to GitHub Pages automatically.
