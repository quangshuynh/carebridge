// Board backup in settings (issue #8): caregivers export and import from
// settings only, with a confirmation, clear feedback, and no change to the
// board's choices or speech.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:carebridge/domain/board_backup.dart';
import 'package:carebridge/domain/display_preferences.dart';
import 'package:carebridge/domain/sample_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/board_harness.dart';
import '../support/fake_backup_files.dart';
import '../support/fake_display_preferences_store.dart';
import '../support/fake_speech_service.dart';
import '../support/sdk_fonts.dart';

const _export = Key('backup-export');
const _import = Key('backup-import');
const _dialog = Key('import-confirmation');

Uint8List _backupOf({required bool highContrast}) =>
    BoardBackupFormat.encodeBytes(
      BoardBackup(
        displayPreferences: DisplayPreferences(highContrast: highContrast),
      ),
    );

/// Scrolls settings until [key] is built and fully visible.
Future<void> _scrollTo(WidgetTester tester, Key key) async {
  await tester.scrollUntilVisible(
    find.byKey(key),
    100,
    scrollable: find.descendant(
      of: find.byType(ListView),
      matching: find.byType(Scrollable),
    ),
  );
  await tester.ensureVisible(find.byKey(key));
  await tester.pumpAndSettle();
}

Future<void> _tapInSettings(WidgetTester tester, Key key) async {
  await _scrollTo(tester, key);
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

/// The confirmation dialog's own entrance animation.
Animation<double> _dialogAnimation(WidgetTester tester) =>
    ModalRoute.of(tester.element(find.byKey(_dialog)))!.animation!;

String _status(WidgetTester tester) => tester
    .widget<Semantics>(find.byKey(const Key('backup-status')))
    .properties
    .label!;

void main() {
  setUpAll(loadSdkFonts);

  late FakeBackupFiles files;
  late FakeDisplayPreferencesStore store;
  late FakeSpeechService speech;

  setUp(() {
    files = FakeBackupFiles();
    store = FakeDisplayPreferencesStore(const DisplayPreferences());
    speech = FakeSpeechService();
  });

  Future<void> openSettings(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double textScale = 1,
    bool disableAnimations = false,
  }) async {
    await pumpCareBridge(
      tester,
      size: size,
      textScale: textScale,
      speech: speech,
      store: store,
      backupFiles: files,
      disableAnimations: disableAnimations,
    );
    await holdSettingsButton(tester);
  }

  testWidgets('backup lives only in settings; the board is unchanged', (
    tester,
  ) async {
    await pumpCareBridge(tester, store: store, backupFiles: files);
    expect(find.byKey(_export), findsNothing);
    expect(find.byKey(_import), findsNothing);
    for (final choice in sampleCommunicator.enabledChoices) {
      expect(choiceFinder(choice.id), findsOneWidget);
    }
    await holdSettingsButton(tester);
    expect(find.byKey(_export), findsOneWidget);
    expect(find.byKey(_import), findsOneWidget);
  });

  group('export', () {
    testWidgets('saves the settings and confirms without changing them', (
      tester,
    ) async {
      store.saved = const DisplayPreferences(highContrast: true);
      await openSettings(tester);
      await _tapInSettings(tester, _export);

      expect(_status(tester), 'Backup saved. Your settings are unchanged.');
      expect(
        BoardBackupFormat.decode(files.savedFiles.single),
        const BoardBackup(
          displayPreferences: DisplayPreferences(highContrast: true),
        ),
      );
      expect(store.saveCount, 0);
      expect(find.byKey(_dialog), findsNothing);
    });

    testWidgets('cancellation and failure are each explained', (tester) async {
      await openSettings(tester);
      files.saveAccepted = false;
      await _tapInSettings(tester, _export);
      expect(_status(tester), 'Export cancelled. No file was saved.');

      files.saveError = const FileSystemException('No space left');
      await _tapInSettings(tester, _export);
      expect(_status(tester), contains('could not be saved'));
      expect(_status(tester), contains('Your settings are unchanged.'));
      expect(files.savedFiles, isEmpty);
    });

    testWidgets('repeated taps while saving start only one export and give '
        'no extra feedback', (tester) async {
      await openSettings(tester);
      files.pendingSave = Completer<void>();
      await _scrollTo(tester, _import);
      await tester.tap(find.byKey(_export));
      await tester.pump();
      await tester.tap(find.byKey(_export), warnIfMissed: false);
      await tester.tap(find.byKey(_import), warnIfMissed: false);
      await tester.pump();
      expect(find.byKey(const Key('backup-status')), findsNothing);

      files.pendingSave!.complete();
      await tester.pumpAndSettle();
      expect(files.saveCount, 1);
      expect(files.openCount, 0);
      expect(_status(tester), startsWith('Backup saved.'));
    });
  });

  group('import', () {
    testWidgets('shows what will change, then replaces settings once '
        'confirmed, and the board still communicates', (tester) async {
      files.fileToOpen = _backupOf(highContrast: true);
      await openSettings(tester);
      await _tapInSettings(tester, _import);

      expect(find.byKey(_dialog), findsOneWidget);
      expect(find.text('Replace current settings?'), findsOneWidget);
      expect(
        find.text('High contrast: Off now, On after import.'),
        findsOneWidget,
      );
      expect(store.saved, const DisplayPreferences(highContrast: false));

      await tester.tap(find.byKey(const Key('import-confirm')));
      await tester.pumpAndSettle();

      expect(find.byKey(_dialog), findsNothing);
      expect(_status(tester), 'Backup imported. Your settings were replaced.');
      expect(store.saved, const DisplayPreferences(highContrast: true));
      expect(find.text('On'), findsOneWidget, reason: 'switch state in words');

      await tester.ensureVisible(find.byKey(const Key('settings-done')));
      await returnToBoard(tester);
      expect(paletteOnBoard(tester).isHighContrast, isTrue);
      for (final choice in sampleCommunicator.enabledChoices) {
        expect(choiceFinder(choice.id), findsOneWidget);
      }
      await tester.tap(choiceFinder('help'));
      await tester.pump();
      expect(speech.spokenPhrases, ['I need help.']);
      expect(find.text('I need help.'), findsOneWidget);
    });

    testWidgets('keeping current settings changes nothing', (tester) async {
      files.fileToOpen = _backupOf(highContrast: true);
      await openSettings(tester);
      await _tapInSettings(tester, _import);
      await tester.tap(find.byKey(const Key('import-cancel')));
      await tester.pumpAndSettle();

      expect(_status(tester), 'Import cancelled. Nothing was changed.');
      expect(store.saveCount, 0);
      expect(find.text('Off'), findsOneWidget);
    });

    testWidgets('dismissing the confirmation changes nothing', (tester) async {
      files.fileToOpen = _backupOf(highContrast: true);
      await openSettings(tester);
      await _tapInSettings(tester, _import);
      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();

      expect(find.byKey(_dialog), findsNothing);
      expect(_status(tester), 'Import cancelled. Nothing was changed.');
      expect(store.saveCount, 0);
    });

    testWidgets('cancelling the file picker is explained', (tester) async {
      await openSettings(tester);
      await _tapInSettings(tester, _import);
      expect(find.byKey(_dialog), findsNothing);
      expect(_status(tester), 'Import cancelled. Nothing was changed.');
    });

    final rejected = <String, (List<int>, String)>{
      'a file that is not a backup': (
        utf8.encode('{"hello": "world"}'),
        'That file is not a CareBridge backup. Nothing was changed.',
      ),
      'a backup from a newer version': (
        utf8.encode(
          '{"format": "carebridge.board-backup", "schemaVersion": 2, '
          '"settings": {"highContrast": true}}',
        ),
        'That backup is from a newer version of CareBridge. Update '
            'CareBridge, then try again. Nothing was changed.',
      ),
      'a damaged backup': (
        utf8.encode(
          '{"format": "carebridge.board-backup", "schemaVersion": 1, '
          '"settings": {"highContrast": true, "photo": "/sdcard/a.png"}}',
        ),
        'That backup is damaged or has settings CareBridge does not '
            'support. Nothing was changed.',
      ),
      'an oversized file': (
        Uint8List(BoardBackupFormat.maxBytes + 1),
        'That file is too large to be a CareBridge backup. '
            'Nothing was changed.',
      ),
    };
    rejected.forEach((name, testCase) {
      final (bytes, message) = testCase;
      testWidgets('$name is rejected without asking or changing anything', (
        tester,
      ) async {
        files.fileToOpen = Uint8List.fromList(bytes);
        await openSettings(tester);
        await _tapInSettings(tester, _import);
        expect(find.byKey(_dialog), findsNothing);
        expect(_status(tester), message);
        expect(store.saveCount, 0);
        expect(find.text('Off'), findsOneWidget);
      });
    });

    testWidgets('an unreadable file is explained', (tester) async {
      files.openError = const FileSystemException('Permission denied');
      await openSettings(tester);
      await _tapInSettings(tester, _import);
      expect(
        _status(tester),
        'That file could not be opened. Nothing was changed.',
      );
    });

    testWidgets('a save failure keeps the previous settings on screen and in '
        'storage', (tester) async {
      files.fileToOpen = _backupOf(highContrast: true);
      await openSettings(tester);
      await _tapInSettings(tester, _import);
      store.saveError = StateError('disk full');
      await tester.tap(find.byKey(const Key('import-confirm')));
      await tester.pumpAndSettle();

      expect(
        _status(tester),
        'The backup could not be applied. Your previous settings are kept.',
      );
      expect(store.saved, const DisplayPreferences(highContrast: false));
      expect(find.text('Off'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('settings-done')));
      await returnToBoard(tester);
      expect(paletteOnBoard(tester).isHighContrast, isFalse);
    });
  });

  testWidgets('feedback is cleared when settings are opened again', (
    tester,
  ) async {
    await openSettings(tester);
    await _tapInSettings(tester, _export);
    expect(find.byKey(const Key('backup-status')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('settings-done')));
    await returnToBoard(tester);
    await holdSettingsButton(tester);
    expect(find.byKey(const Key('backup-status')), findsNothing);
  });

  group('accessibility', () {
    testWidgets('actions, heading, and feedback are labeled for screen '
        'readers', (tester) async {
      final semantics = tester.ensureSemantics();
      files.fileToOpen = _backupOf(highContrast: true);
      await openSettings(tester);
      await _scrollTo(tester, _import);

      expect(
        tester.getSemantics(find.bySemanticsLabel('Backup')),
        isSemantics(label: 'Backup', isHeader: true),
      );
      for (final label in ['Export board backup', 'Import board backup']) {
        expect(
          tester.getSemantics(find.bySemanticsLabel(label)),
          isSemantics(
            label: label,
            isButton: true,
            hasEnabledState: true,
            isEnabled: true,
            hasTapAction: true,
            isFocusable: true,
          ),
        );
      }

      await _tapInSettings(tester, _import);
      for (final label in ['Keep current settings', 'Replace settings']) {
        expect(
          tester.getSemantics(find.bySemanticsLabel(label)),
          isSemantics(label: label, isButton: true, hasTapAction: true),
        );
      }
      await tester.tap(find.byKey(const Key('import-cancel')));
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(
          find.bySemanticsLabel('Import cancelled. Nothing was changed.'),
        ),
        isSemantics(isLiveRegion: true),
      );
      semantics.dispose();
    });

    testWidgets('backup buttons and confirmation buttons are large targets', (
      tester,
    ) async {
      files.fileToOpen = _backupOf(highContrast: false);
      await openSettings(tester);
      await _scrollTo(tester, _import);
      for (final key in [_export, _import]) {
        expect(
          tester.getSize(find.byKey(key)).height,
          greaterThanOrEqualTo(72),
        );
      }
      await _tapInSettings(tester, _import);
      for (final key in ['import-cancel', 'import-confirm']) {
        expect(
          tester.getSize(find.byKey(Key(key))).height,
          greaterThanOrEqualTo(72),
        );
      }
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });

    testWidgets('the confirmation uses the high contrast palette', (
      tester,
    ) async {
      store.saved = const DisplayPreferences(highContrast: true);
      files.fileToOpen = _backupOf(highContrast: false);
      await openSettings(tester);
      await _tapInSettings(tester, _import);
      expect(
        find.text('High contrast: On now, Off after import.'),
        findsOneWidget,
      );
      final dialog = tester.widget<AlertDialog>(find.byKey(_dialog));
      expect(dialog.backgroundColor, Colors.white);
      expect(
        (dialog.shape! as RoundedRectangleBorder).side.color,
        Colors.black,
      );
    });

    for (final disableAnimations in [false, true]) {
      testWidgets(
        'the confirmation ${disableAnimations ? 'appears at once '
                  'with reduced motion' : 'animates normally'}',
        (tester) async {
          files.fileToOpen = _backupOf(highContrast: true);
          await openSettings(tester, disableAnimations: disableAnimations);
          await _scrollTo(tester, _import);
          await tester.tap(find.byKey(_import));
          await tester.pump();
          await tester.pump();
          expect(find.byKey(_dialog), findsOneWidget);
          expect(
            _dialogAnimation(tester).isCompleted,
            disableAnimations,
            reason: 'fully shown in its first frame only with reduced motion',
          );
          await tester.pumpAndSettle();
        },
      );
    }

    final layouts = {
      'small phone at 3x text': (const Size(320, 568), 3.0),
      'phone landscape at 2x text': (const Size(844, 390), 2.0),
      'tablet at 2x text': (const Size(1024, 1366), 2.0),
      'tablet landscape': (const Size(1366, 1024), 1.0),
    };
    layouts.forEach((name, layout) {
      final (size, textScale) = layout;
      testWidgets('$name: backup and its confirmation stay usable', (
        tester,
      ) async {
        files.fileToOpen = _backupOf(highContrast: true);
        await openSettings(tester, size: size, textScale: textScale);
        expect(tester.takeException(), isNull);
        await _tapInSettings(tester, _import);
        expect(tester.takeException(), isNull);
        expect(find.text('Replace current settings?'), findsOneWidget);
        await tester.ensureVisible(find.byKey(const Key('import-confirm')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('import-confirm')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(store.saved, const DisplayPreferences(highContrast: true));
        await _scrollTo(tester, const Key('backup-status'));
        expect(
          find.byKey(const Key('backup-status')).hitTestable(),
          findsOneWidget,
        );
      });
    });
  });
}
