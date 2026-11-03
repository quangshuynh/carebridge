import 'package:flutter/foundation.dart';

import '../domain/board_backup.dart';
import '../services/backup_files.dart';
import 'board_choices_controller.dart';
import 'display_preferences_controller.dart';

/// The result of the latest backup action, shown to the caregiver.
enum BackupOutcome {
  exported,
  exportCancelled,
  exportFailed,
  imported,
  importCancelled,

  /// The chosen file could not be read at all.
  importUnreadable,

  /// The file was read but is not an acceptable backup; see [problem].
  importRejected,

  /// The backup was valid but could not be saved, so nothing changed.
  importFailed,
}

/// Exports and imports caregiver settings and the board's choices as a
/// local file the caregiver handles themselves. Import replaces them only
/// after the whole file is valid, the caregiver confirms, and everything new
/// is saved.
class BoardBackupController extends ChangeNotifier {
  BoardBackupController({
    required this.files,
    required this.preferences,
    required this.choices,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;
  final BackupFiles files;
  final DisplayPreferencesController preferences;
  final BoardChoicesController choices;
  final DateTime Function() _now;

  bool _isBusy = false;
  bool _isDisposed = false;
  BackupOutcome? _outcome;
  BoardBackupProblem? _problem;

  /// True from the start of an export or import until its outcome is known,
  /// including while an import waits for confirmation. Requests made while
  /// busy are ignored.
  bool get isBusy => _isBusy;
  BackupOutcome? get outcome => _outcome;

  /// Why the latest import was rejected, when [outcome] is
  /// [BackupOutcome.importRejected].
  BoardBackupProblem? get problem => _problem;

  /// The current settings and choices as a backup.
  BoardBackup get current => BoardBackup(
    displayPreferences: preferences.preferences,
    board: choices.board,
  );

  /// Forgets the last outcome, for example when settings are opened again.
  void clearOutcome() {
    if (_outcome == null || _isBusy) return;
    _outcome = null;
    _problem = null;
    _notify();
  }

  /// Saves the current settings to a file the caregiver chooses. Never
  /// changes the settings. Returns false when ignored as a repeat.
  Future<bool> export() async {
    if (!_begin()) return false;
    BackupOutcome outcome;
    try {
      final bytes = BoardBackupFormat.encodeBytes(current);
      final saved = await files.save(
        fileName: BoardBackupFormat.fileNameFor(_now()),
        bytes: bytes,
      );
      outcome = saved ? BackupOutcome.exported : BackupOutcome.exportCancelled;
    } catch (_) {
      outcome = BackupOutcome.exportFailed;
    }
    _finish(outcome);
    return true;
  }

  /// Lets the caregiver choose a file and checks all of it. Returns the
  /// backup awaiting [applyImport] or [declineImport], or null when nothing
  /// is to be applied (cancelled, unreadable, rejected, or ignored as a
  /// repeat). Nothing is changed here.
  Future<BoardBackup?> chooseImport() async {
    if (!_begin()) return null;
    final Uint8List? bytes;
    try {
      bytes = await files.open(maxBytes: BoardBackupFormat.maxBytes);
    } catch (_) {
      _finish(BackupOutcome.importUnreadable);
      return null;
    }
    if (bytes == null) {
      _finish(BackupOutcome.importCancelled);
      return null;
    }
    try {
      return BoardBackupFormat.decode(bytes);
    } on BoardBackupException catch (error) {
      _finish(BackupOutcome.importRejected, problem: error.problem);
      return null;
    }
  }

  /// Replaces the current settings and choices with [backup] once all of
  /// it is saved. The board is saved first; if the settings then fail to
  /// save, the previous board is saved back. Nothing on screen changes until
  /// both are saved. A version 1 backup has no choices and leaves the board
  /// as it is.
  Future<void> applyImport(BoardBackup backup) async {
    if (!_isBusy || _isDisposed) return;
    final board = backup.board;
    final previousBoard = choices.board;
    try {
      if (board != null) await choices.persist(board);
      try {
        await preferences.replaceWith(backup.displayPreferences);
      } catch (_) {
        if (board != null) {
          try {
            await choices.persist(previousBoard);
          } catch (_) {}
        }
        rethrow;
      }
      if (board != null) choices.adopt(board);
      _finish(BackupOutcome.imported);
    } catch (_) {
      _finish(BackupOutcome.importFailed);
    }
  }

  /// The caregiver chose not to replace their settings.
  void declineImport() {
    if (!_isBusy) return;
    _finish(BackupOutcome.importCancelled);
  }

  bool _begin() {
    if (_isBusy || _isDisposed) return false;
    _isBusy = true;
    _outcome = null;
    _problem = null;
    _notify();
    return true;
  }

  void _finish(BackupOutcome outcome, {BoardBackupProblem? problem}) {
    _isBusy = false;
    _outcome = outcome;
    _problem = problem;
    _notify();
  }

  void _notify() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
