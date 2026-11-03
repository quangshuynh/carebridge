import 'dart:io';

import 'package:carebridge/domain/sample_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/board_harness.dart';
import 'support/fake_backup_files.dart';
import 'support/fake_display_preferences_store.dart';
import 'support/fake_speech_service.dart';
import 'support/sdk_fonts.dart';

/// Fails any attempt to open an HTTP connection, and counts it.
class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw const SocketException('CareBridge must not use the network');
  }
}

void main() {
  setUpAll(loadSdkFonts);

  testWidgets('communication, settings, and a restart work with no network '
      'and keep every choice', (tester) async {
    final previous = HttpOverrides.current;
    final network = _NoNetwork();
    HttpOverrides.global = network;
    addTearDown(() => HttpOverrides.global = previous);

    final speech = FakeSpeechService();
    final store = FakeDisplayPreferencesStore();
    await pumpCareBridge(tester, speech: speech, store: store);

    await tester.tap(choiceFinder('help'));
    await tester.pump();
    await holdSettingsButton(tester);
    await tester.tap(find.byKey(const Key('high-contrast-switch')));
    await tester.pump();
    await returnToBoard(tester);
    await tester.tap(choiceFinder('finished'));
    await tester.pump();

    await tester.pumpWidget(const SizedBox());
    await pumpCareBridge(tester, speech: speech, store: store);

    expect(network.attempts, 0);
    expect(tester.takeException(), isNull);
    expect(speech.spokenPhrases, ['I need help.', 'I am finished.']);
    expect(paletteOnBoard(tester).isHighContrast, isTrue);
    // Every configured choice is still shown after settings and a restart.
    for (final choice in sampleCommunicator.enabledChoices) {
      expect(find.text(choice.label), findsOneWidget);
    }
  });

  testWidgets('a backup exported on one device restores on another with no '
      'network', (tester) async {
    final previous = HttpOverrides.current;
    final network = _NoNetwork();
    HttpOverrides.global = network;
    addTearDown(() => HttpOverrides.global = previous);

    Future<void> tapInSettings(Key key) async {
      await tester.scrollUntilVisible(
        find.byKey(key),
        100,
        scrollable: find.descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();
    }

    final files = FakeBackupFiles();
    await pumpCareBridge(
      tester,
      store: FakeDisplayPreferencesStore(),
      backupFiles: files,
    );
    await holdSettingsButton(tester);
    await tester.tap(find.byKey(const Key('high-contrast-switch')));
    await tester.pump();
    await tapInSettings(const Key('backup-export'));

    // A second device, starting from the defaults.
    await tester.pumpWidget(const SizedBox());
    final speech = FakeSpeechService();
    final otherStore = FakeDisplayPreferencesStore();
    files.fileToOpen = files.savedFiles.single;
    await pumpCareBridge(
      tester,
      speech: speech,
      store: otherStore,
      backupFiles: files,
    );
    expect(paletteOnBoard(tester).isHighContrast, isFalse);
    await holdSettingsButton(tester);
    await tapInSettings(const Key('backup-import'));
    await tester.tap(find.byKey(const Key('import-confirm')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('settings-done')));
    await returnToBoard(tester);
    await tester.tap(choiceFinder('drink'));
    await tester.pump();

    expect(network.attempts, 0);
    expect(tester.takeException(), isNull);
    expect(paletteOnBoard(tester).isHighContrast, isTrue);
    expect(otherStore.saved?.highContrast, isTrue);
    expect(speech.spokenPhrases, ['I would like a drink.']);
  });
}
