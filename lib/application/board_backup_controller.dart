import 'package:flutter/foundation.dart';

import '../domain/board_backup.dart';
import '../services/backup_files.dart';
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

/// Exports and imports caregiver settings as a local file the caregiver
/// handles themselves. Import replaces settings only after the whole file is
/// valid, the caregiver confirms, and the new settings are saved.
class BoardBackupController extends ChangeNotifier {
  BoardBackupController({
    required this.files,
    required this.preferences,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;
  final BackupFiles files;
  final DisplayPreferencesController preferences;
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

  /// The current settings as a backup.
  BoardBackup get current =>
      BoardBackup(displayPreferences: preferences.preferences);

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
    final bytes = BoardBackupFormat.encodeBytes(current);
    BackupOutcome outcome;
    try {
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

  /// Replaces the current settings with [backup] once they are saved. If
  /// saving fails, the previous settings stay in place and in storage.
  Future<void> applyImport(BoardBackup backup) async {
    if (!_isBusy || _isDisposed) return;
    try {
      await preferences.replaceWith(backup.displayPreferences);
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
