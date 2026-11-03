import 'package:carebridge/app.dart';
import 'package:carebridge/application/communication_board_controller.dart';
import 'package:carebridge/domain/communication_models.dart';
import 'package:carebridge/domain/sample_board.dart';
import 'package:carebridge/presentation/care_bridge_theme.dart';
import 'package:carebridge/presentation/communication_board_screen.dart';
import 'package:carebridge/presentation/widgets/settings_hold_button.dart';
import 'package:carebridge/services/backup_files.dart';
import 'package:carebridge/services/display_preferences_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_speech_service.dart';
import 'fake_tactile_feedback.dart';

/// Pumps the whole app at a phone size by default.
Future<void> pumpCareBridge(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double textScale = 1,
  FakeSpeechService? speech,
  FakeTactileFeedback? haptics,
  DisplayPreferencesStore? store,
  BackupFiles? backupFiles,
  CommunicatorProfile profile = sampleCommunicator,
  DateTime Function()? now,
  bool systemHighContrast = false,
  bool disableAnimations = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(
        highContrast: systemHighContrast,
        disableAnimations: disableAnimations,
      );
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await tester.pumpWidget(
    CareBridgeApp(
      speechService: speech ?? FakeSpeechService(),
      tactileFeedback: haptics,
      displayPreferencesStore: store,
      backupFiles: backupFiles,
      profile: profile,
      now: now,
    ),
  );
  // Lets saved preferences load, as they do just after launch.
  await tester.pump();
}

Finder choiceFinder(String id) => find.byKey(Key('choice-$id'));

CommunicationBoardController boardController(WidgetTester tester) => tester
    .widget<CommunicationBoardScreen>(find.byType(CommunicationBoardScreen))
    .controller;

CareBridgePalette paletteOnBoard(WidgetTester tester) =>
    CareBridgePalette.of(tester.element(choiceFinder('food')));

/// Holds the settings button for as long as it requires.
Future<void> holdSettingsButton(WidgetTester tester) async {
  final gesture = await tester.startGesture(
    tester.getCenter(find.byKey(const Key('settings-button'))),
  );
  await tester.pump(SettingsHoldButton.holdDuration);
  await gesture.up();
  await tester.pumpAndSettle();
}

Future<void> returnToBoard(WidgetTester tester) async {
  WidgetController.hitTestWarningShouldBeFatal = true;
  addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);
  await tester.tap(find.byKey(const Key('settings-done')));
  await tester.pumpAndSettle();
}
