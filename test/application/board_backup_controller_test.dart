// Export and import (issue #8): export never changes anything, and an import
// changes settings only when valid, confirmed, and saved.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:carebridge/application/board_backup_controller.dart';
import 'package:carebridge/application/board_choices_controller.dart';
import 'package:carebridge/application/display_preferences_controller.dart';
import 'package:carebridge/domain/board_backup.dart';
import 'package:carebridge/domain/board_choices.dart';
import 'package:carebridge/domain/display_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_backup_files.dart';
import '../support/fake_board_choices_store.dart';
import '../support/fake_display_preferences_store.dart';

const _on = DisplayPreferences(highContrast: true);
const _off = DisplayPreferences(highContrast: false);

Uint8List _backupBytes(DisplayPreferences preferences) =>
    BoardBackupFormat.encodeBytes(
      BoardBackup(
        displayPreferences: preferences,
        board: BoardChoices.original,
      ),
    );

void main() {
  late FakeDisplayPreferencesStore store;
  late DisplayPreferencesController preferences;
  late FakeBackupFiles files;
  late BoardBackupController backup;
  late int notifications;

  Future<void> start(DisplayPreferences? saved) async {
    store = FakeDisplayPreferencesStore(saved);
    preferences = DisplayPreferencesController(store: store);
    await preferences.load();
    files = FakeBackupFiles();
    backup = BoardBackupController(
      files: files,
      preferences: preferences,
      choices: BoardChoicesController(),
      now: () => DateTime(2026, 11, 3, 9),
    );
    notifications = 0;
    preferences.addListener(() => notifications++);
  }

  /// Settings must be unchanged in memory, in storage, and to listeners.
  void expectUnchanged(DisplayPreferences expected, {int saves = 0}) {
    expect(preferences.preferences, expected);
    expect(store.saved, expected);
    expect(store.saveCount, saves);
    expect(notifications, 0);
  }

  group('export', () {
    setUp(() => start(_on));

    test('saves the complete current settings without changing them', () async {
      expect(await backup.export(), isTrue);

      expect(backup.outcome, BackupOutcome.exported);
      expect(files.savedNames, ['carebridge-backup-2026-11-03.json']);
      expect(
        utf8.decode(files.savedFiles.single),
        BoardBackupFormat.encode(
          BoardBackup(displayPreferences: _on, board: BoardChoices.original),
        ),
      );
      expectUnchanged(_on);
    });

    test('exporting twice produces identical files', () async {
      await backup.export();
      await backup.export();
      expect(files.savedFiles[0], files.savedFiles[1]);
    });

    test('cancelling saves nothing and says so', () async {
      files.saveAccepted = false;
      await backup.export();
      expect(backup.outcome, BackupOutcome.exportCancelled);
      expect(files.savedFiles, isEmpty);
      expectUnchanged(_on);
    });

    test('an unavailable destination or write failure is reported', () async {
      files.saveError = const FileSystemException('Read-only file system');
      await backup.export();
      expect(backup.outcome, BackupOutcome.exportFailed);
      expect(backup.isBusy, isFalse);
      expectUnchanged(_on);
    });

    test('a repeated request while saving is ignored', () async {
      files.pendingSave = Completer<void>();
      final first = backup.export();
      expect(backup.isBusy, isTrue);
      expect(await backup.export(), isFalse);
      expect(await backup.chooseImport(), isNull);
      files.pendingSave!.complete();
      expect(await first, isTrue);
      expect(files.saveCount, 1);
      expect(files.openCount, 0);
    });
  });

  group('import', () {
    setUp(() => start(_off));

    test('a valid backup is offered, then applied and saved once '
        'confirmed', () async {
      files.fileToOpen = _backupBytes(_on);
      final chosen = await backup.chooseImport();

      expect(
        chosen,
        BoardBackup(displayPreferences: _on, board: BoardChoices.original),
      );
      // Nothing changes until the caregiver confirms.
      expect(backup.isBusy, isTrue);
      expectUnchanged(_off);

      await backup.applyImport(chosen!);
      expect(backup.outcome, BackupOutcome.imported);
      expect(backup.isBusy, isFalse);
      expect(preferences.preferences, _on);
      expect(store.saved, _on);
      expect(notifications, 1);
    });

    test('declining the confirmation changes nothing', () async {
      files.fileToOpen = _backupBytes(_on);
      await backup.chooseImport();
      backup.declineImport();
      expect(backup.outcome, BackupOutcome.importCancelled);
      expect(backup.isBusy, isFalse);
      expectUnchanged(_off);
    });

    test('cancelling the file picker changes nothing', () async {
      expect(await backup.chooseImport(), isNull);
      expect(backup.outcome, BackupOutcome.importCancelled);
      expectUnchanged(_off);
    });

    test('a file that cannot be read changes nothing', () async {
      files.openError = const FileSystemException('Permission denied');
      expect(await backup.chooseImport(), isNull);
      expect(backup.outcome, BackupOutcome.importUnreadable);
      expectUnchanged(_off);
    });

    final rejected = <String, (List<int>, BoardBackupProblem)>{
      'malformed JSON': (
        utf8.encode('{"format":'),
        BoardBackupProblem.notBackup,
      ),
      'a future version': (
        utf8.encode(
          '{"format": "carebridge.board-backup", "schemaVersion": 3, '
          '"settings": {"highContrast": true}}',
        ),
        BoardBackupProblem.newerVersion,
      ),
      'an invalid value': (
        utf8.encode(
          '{"format": "carebridge.board-backup", "schemaVersion": 1, '
          '"settings": {"highContrast": "yes"}}',
        ),
        BoardBackupProblem.invalidContent,
      ),
      'an oversized file': (
        Uint8List(BoardBackupFormat.maxBytes * 4),
        BoardBackupProblem.tooLarge,
      ),
    };
    rejected.forEach((name, testCase) {
      final (bytes, problem) = testCase;
      test('$name is rejected and the previous settings survive', () async {
        files.fileToOpen = Uint8List.fromList(bytes);
        expect(await backup.chooseImport(), isNull);
        expect(backup.outcome, BackupOutcome.importRejected);
        expect(backup.problem, problem);
        expect(backup.isBusy, isFalse);
        expectUnchanged(_off);
      });
    });

    test('a persistence failure keeps the previous settings in memory and '
        'in storage', () async {
      files.fileToOpen = _backupBytes(_on);
      final chosen = await backup.chooseImport();
      store.saveError = StateError('disk full');

      await backup.applyImport(chosen!);

      expect(backup.outcome, BackupOutcome.importFailed);
      expect(backup.isBusy, isFalse);
      expect(preferences.preferences, _off);
      expect(store.saved, _off);
      expect(notifications, 0);
    });

    test('a later valid import still works after a rejected one', () async {
      files.fileToOpen = Uint8List.fromList(utf8.encode('not json'));
      await backup.chooseImport();
      files.fileToOpen = _backupBytes(_on);
      await backup.applyImport((await backup.chooseImport())!);
      expect(preferences.preferences, _on);
    });

    test('importing the default configuration restores the defaults', () async {
      await preferences.setHighContrast(true);
      notifications = 0;
      files.fileToOpen = Uint8List.fromList(
        utf8.encode(
          '{"format": "carebridge.board-backup", "schemaVersion": 1, '
          '"settings": {}}',
        ),
      );
      await backup.applyImport((await backup.chooseImport())!);
      expect(preferences.preferences, DisplayPreferences.standard);
      expect(store.saved, DisplayPreferences.standard);
    });

    test('an imported setting is kept when saved preferences finish loading '
        'later', () async {
      store = FakeDisplayPreferencesStore(_off)..pendingLoad = Completer();
      preferences = DisplayPreferencesController(store: store);
      final loading = preferences.load();
      backup = BoardBackupController(
        files: files,
        preferences: preferences,
        choices: BoardChoicesController(),
      );
      files.fileToOpen = _backupBytes(_on);
      await backup.applyImport((await backup.chooseImport())!);
      store.pendingLoad!.complete();
      await loading;
      expect(preferences.preferences, _on);
    });
  });

  group('with real temporary files', () {
    late Directory directory;
    late TemporaryDirectoryBackupFiles diskFiles;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('carebridge-backup');
      diskFiles = TemporaryDirectoryBackupFiles(directory);
    });
    tearDown(() => directory.delete(recursive: true));

    test('a backup exported on one device restores identically on '
        'another', () async {
      final sourceStore = FakeDisplayPreferencesStore(_on);
      final source = DisplayPreferencesController(store: sourceStore);
      await source.load();
      await BoardBackupController(
        files: diskFiles,
        preferences: source,
        choices: BoardChoicesController(),
        now: () => DateTime(2026, 1, 2),
      ).export();

      final exported = File(
        '${directory.path}/carebridge-backup-2026-01-02.json',
      );
      expect(directory.listSync(), [isA<File>()]);

      final targetStore = FakeDisplayPreferencesStore();
      final target = DisplayPreferencesController(store: targetStore);
      final restore = BoardBackupController(
        files: diskFiles..chosen = exported,
        preferences: target,
        choices: BoardChoicesController(),
      );
      await restore.applyImport((await restore.chooseImport())!);

      expect(restore.outcome, BackupOutcome.imported);
      expect(target.preferences, source.preferences);
      expect(targetStore.saved, sourceStore.saved);
      expect(
        BoardBackupFormat.encode(restore.current),
        await exported.readAsString(),
      );
    });

    test('a failed write leaves no backup file behind', () async {
      final controller = BoardBackupController(
        files: diskFiles..failWrite = true,
        preferences: DisplayPreferencesController(),
        choices: BoardChoicesController(),
      );
      await controller.export();
      expect(controller.outcome, BackupOutcome.exportFailed);
      expect(directory.listSync(), isEmpty);
    });

    test('an oversized file is rejected without reading all of it', () async {
      final huge = File('${directory.path}/huge.json');
      await huge.writeAsBytes(Uint8List(5 * 1024 * 1024));
      final controller = BoardBackupController(
        files: diskFiles..chosen = huge,
        preferences: DisplayPreferencesController(),
        choices: BoardChoicesController(),
      );
      expect(await controller.chooseImport(), isNull);
      expect(controller.problem, BoardBackupProblem.tooLarge);
    });
  });

  group('choices', () {
    const snack = ChoiceDraft(
      label: 'Snack',
      spokenPhrase: 'Snack, please.',
      iconId: 'cookie',
      colorId: 'yellow',
    );
    late FakeBoardChoicesStore boardStore;
    late BoardChoicesController choices;
    late BoardChoices customBoard;

    setUp(() async {
      store = FakeDisplayPreferencesStore(_off);
      preferences = DisplayPreferencesController(store: store);
      await preferences.load();
      boardStore = FakeBoardChoicesStore();
      choices = BoardChoicesController(store: boardStore);
      await choices.load();
      files = FakeBackupFiles();
      backup = BoardBackupController(
        files: files,
        preferences: preferences,
        choices: choices,
      );
      customBoard = BoardChoices.original
          .withAdded(snack)
          .withMoved('custom-1', -6)
          .withVisibility('drive', visible: false);
    });

    Uint8List backupWith(BoardChoices board, DisplayPreferences settings) =>
        BoardBackupFormat.encodeBytes(
          BoardBackup(displayPreferences: settings, board: board),
        );

    test('export includes the customized board exactly', () async {
      await choices.add(snack);
      await choices.setVisible('help', visible: false);
      await backup.export();
      expect(
        BoardBackupFormat.decode(files.savedFiles.single).board,
        choices.board,
      );
      await backup.export();
      expect(files.savedFiles[0], files.savedFiles[1]);
    });

    test('import replaces settings and choices together, with ids and order '
        'intact', () async {
      files.fileToOpen = backupWith(customBoard, _on);
      await backup.applyImport((await backup.chooseImport())!);

      expect(backup.outcome, BackupOutcome.imported);
      expect(choices.board, customBoard);
      expect(boardStore.saved, customBoard);
      expect(preferences.preferences, _on);
      expect(choices.profile.enabledChoices.map((c) => c.id).toList(), [
        'custom-1',
        'food',
        'drink',
        'help',
        'rest',
        'finished',
      ]);
    });

    test('a version 1 backup replaces settings and leaves custom choices '
        'alone', () async {
      await choices.add(snack);
      final before = choices.board;
      files.fileToOpen = Uint8List.fromList(
        utf8.encode(
          '{"format": "carebridge.board-backup", "schemaVersion": 1, '
          '"settings": {"highContrast": true}}',
        ),
      );
      await backup.applyImport((await backup.chooseImport())!);
      expect(backup.outcome, BackupOutcome.imported);
      expect(preferences.preferences, _on);
      expect(choices.board, before);
      expect(boardStore.saved, before);
    });

    test('a backup with duplicate choice ids is rejected and nothing '
        'changes', () async {
      final duplicated = jsonDecode(
        utf8.decode(backupWith(BoardChoices.original, _on)),
      ) as Map<String, dynamic>;
      final list = duplicated['board']['choices'] as List<dynamic>;
      list.add(Map<String, dynamic>.of(list.first as Map<String, dynamic>));
      files.fileToOpen = Uint8List.fromList(
        utf8.encode(jsonEncode(duplicated)),
      );

      expect(await backup.chooseImport(), isNull);
      expect(backup.problem, BoardBackupProblem.invalidContent);
      expect(choices.board, BoardChoices.original);
      expect(boardStore.saveCount, 0);
      expect(store.saveCount, 0);
    });

    test('if the board cannot be saved, nothing changes', () async {
      files.fileToOpen = backupWith(customBoard, _on);
      final chosen = await backup.chooseImport();
      boardStore.saveError = StateError('disk full');
      await backup.applyImport(chosen!);

      expect(backup.outcome, BackupOutcome.importFailed);
      expect(choices.board, BoardChoices.original);
      expect(boardStore.savedText, isNull);
      expect(preferences.preferences, _off);
      expect(store.saveCount, 0);
    });

    test('if the settings cannot be saved after the board, the previous '
        'board is saved back and nothing on screen changes', () async {
      await choices.add(snack);
      final before = choices.board;
      files.fileToOpen = backupWith(customBoard.withMoved('food', 3), _on);
      final chosen = await backup.chooseImport();
      store.saveError = StateError('disk full');
      await backup.applyImport(chosen!);

      expect(backup.outcome, BackupOutcome.importFailed);
      expect(choices.board, before);
      expect(boardStore.saved, before);
      expect(preferences.preferences, _off);
      expect(store.saved, _off);
    });

    test('an import is not applied while saved choices are still '
        'loading', () async {
      boardStore = FakeBoardChoicesStore(BoardChoices.original.withAdded(snack))
        ..pendingLoad = Completer();
      choices = BoardChoicesController(store: boardStore);
      final loading = choices.load();
      backup = BoardBackupController(
        files: files,
        preferences: preferences,
        choices: choices,
      );
      files.fileToOpen = backupWith(customBoard, _on);
      await backup.applyImport((await backup.chooseImport())!);
      expect(backup.outcome, BackupOutcome.importFailed);
      expect(preferences.preferences, _off);

      boardStore.pendingLoad!.complete();
      await loading;
      expect(choices.board.choices, hasLength(7));
      expect(boardStore.saveCount, 0);
    });
  });
}
