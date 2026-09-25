// Regenerates the documentation screenshots in docs/images/screenshots/.
//
// Run from the repository root:
//   flutter test tool/screenshots/capture_screenshots_test.dart
//
// The board is rendered by Flutter's test renderer with the Roboto and
// Material Icons fonts bundled in the Flutter SDK, so text and icons are
// real. There is no device status bar, navigation bar, or notch; safe-area
// insets are zero.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:carebridge/app.dart';
import 'package:carebridge/services/speech_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test/support/sdk_fonts.dart';

const _outputDirectory = 'docs/images/screenshots';

void main() {
  setUpAll(loadSdkFonts);

  for (final shot in [
    (name: 'phone-portrait-initial', size: const Size(390, 844), tap: null),
    (name: 'phone-portrait-selected', size: const Size(390, 844), tap: 'drink'),
    (name: 'phone-landscape-selected', size: const Size(844, 390), tap: 'help'),
    (
      name: 'tablet-portrait-selected',
      size: const Size(820, 1180),
      tap: 'rest',
    ),
    (
      name: 'tablet-landscape-selected',
      size: const Size(1180, 820),
      tap: 'food',
    ),
  ]) {
    testWidgets(shot.name, (tester) async {
      const pixelRatio = 2.0;
      tester.view.physicalSize = shot.size * pixelRatio;
      tester.view.devicePixelRatio = pixelRatio;
      addTearDown(tester.view.reset);
      const boundaryKey = Key('screenshot');
      await tester.pumpWidget(
        const RepaintBoundary(
          key: boundaryKey,
          child: CareBridgeApp(speechService: _SilentSpeech()),
        ),
      );
      if (shot.tap != null) {
        await tester.tap(find.byKey(Key('choice-${shot.tap}')));
      }
      await tester.pumpAndSettle();
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(boundaryKey),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: pixelRatio);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        File('$_outputDirectory/${shot.name}.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(png!.buffer.asUint8List());
      });
    });
  }
}

class _SilentSpeech implements SpeechService {
  const _SilentSpeech();
  @override
  Future<void> speak(String phrase) async {}
  @override
  Future<void> stop() async {}
}
