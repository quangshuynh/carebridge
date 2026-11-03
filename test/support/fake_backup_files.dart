import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:carebridge/services/backup_files.dart';

/// Stands in for the platform's save and open dialogs, in memory.
class FakeBackupFiles implements BackupFiles {
  /// What the "chosen" file holds; null means the caregiver cancels.
  Uint8List? fileToOpen;
  Object? openError;

  /// False means the caregiver cancels the save dialog.
  bool saveAccepted = true;
  Object? saveError;
  Completer<void>? pendingSave;

  final List<String> savedNames = [];
  final List<Uint8List> savedFiles = [];
  int openCount = 0;
  int saveCount = 0;

  @override
  Future<bool> save({
    required String fileName,
    required Uint8List bytes,
  }) async {
    saveCount++;
    await pendingSave?.future;
    if (saveError != null) throw saveError!;
    if (!saveAccepted) return false;
    savedNames.add(fileName);
    savedFiles.add(Uint8List.fromList(bytes));
    return true;
  }

  @override
  Future<Uint8List?> open({required int maxBytes}) async {
    openCount++;
    if (openError != null) throw openError!;
    final file = fileToOpen;
    if (file == null) return null;
    return file.length > maxBytes
        ? Uint8List.sublistView(file, 0, maxBytes + 1)
        : file;
  }
}

/// Saves into and opens from a real temporary directory. A save is written
/// beside its destination and renamed into place, so an interrupted write
/// never leaves a partial backup under the real name.
class TemporaryDirectoryBackupFiles implements BackupFiles {
  TemporaryDirectoryBackupFiles(this.directory);
  final Directory directory;

  /// The file the caregiver "chooses" to open; null cancels.
  File? chosen;

  /// Fails the write after the partial file exists, like a full disk.
  bool failWrite = false;

  @override
  Future<bool> save({
    required String fileName,
    required Uint8List bytes,
  }) async {
    final target = File('${directory.path}/$fileName');
    final partial = File('${target.path}.part');
    try {
      await partial.writeAsBytes(bytes, flush: true);
      if (failWrite) throw const FileSystemException('No space left');
      await partial.rename(target.path);
    } finally {
      if (await partial.exists()) await partial.delete();
    }
    return true;
  }

  @override
  Future<Uint8List?> open({required int maxBytes}) async {
    final file = chosen;
    if (file == null) return null;
    final handle = await file.open();
    try {
      return await handle.read(maxBytes + 1);
    } finally {
      await handle.close();
    }
  }
}
